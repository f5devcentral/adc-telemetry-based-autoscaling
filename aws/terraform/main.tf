provider "aws" {
  region = var.region
}

locals {
  allowed_mgmt_cidr = "0.0.0.0/0"
  allowed_app_cidr  = "0.0.0.0/0"
  hostname          = format("bigip.aws.%s.com", local.app_id)
  event_timestamp   = formatdate("YYYY-MM-DD hh:mm:ss",timestamp())
  app_id            = random_id.id.hex
}

#
# Create a random id
#
resource "random_id" "id" {
  byte_length = 2
}

#
# Create random password for BIG-IP
#
resource random_string password {
  length      = 16
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

resource "aws_iam_role" "main" {
  name               = format("%s-iam-role", local.app_id)
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "BigIpPolicy" {
  //name = "aws-iam-role-policy-${module.utils.env_prefix}"
  role   = aws_iam_role.main.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Action": [
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceStatus",
            "ec2:DescribeAddresses",
            "ec2:AssociateAddress",
            "ec2:DisassociateAddress",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeNetworkInterfaceAttribute",
            "ec2:DescribeRouteTables",
            "ec2:ReplaceRoute",
            "ec2:CreateRoute",
            "ec2:assignprivateipaddresses",
            "sts:AssumeRole",
            "s3:ListAllMyBuckets"
        ],
        "Resource": [
            "*"
        ],
        "Effect": "Allow"
    },
    {
        "Effect": "Allow",
        "Action": [
            "secretsmanager:GetResourcePolicy",
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:ListSecretVersionIds",
            "secretsmanager:UpdateSecretVersionStage"
        ],
        "Resource": [
            "arn:aws:secretsmanager:${var.region}:${module.vpc.vpc_owner_id}:secret:*"
        ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = format("%s-iam-profile", local.app_id)
  role = aws_iam_role.main.id
}

#
# Create Secret Store and Store BIG-IP Password
#
resource "aws_secretsmanager_secret" "bigip" {
  name = format("%s-bigip-secret", local.app_id)
}

resource "aws_secretsmanager_secret_version" "bigip-pwd" {
  secret_id     = aws_secretsmanager_secret.bigip.id
  secret_string = random_string.password.result
}

#
# Create the VPC
#
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = format("%s-vpc", local.app_id)
  cidr                 = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs = var.availabilityZones

  tags = {
    Name        = format("%s-vpc", local.app_id)
    Terraform   = "true"
    Environment = "dev"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "default"
  }
}
resource "aws_route_table" "internet-gw" {
  vpc_id = module.vpc.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_subnet" "mgmt" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = cidrsubnet(var.cidr, 8, 1)
  availability_zone = format("%sb", var.region)

  tags = {
    Name = "management"
  }
}

resource "aws_route_table_association" "route_table_mgmt" {
  subnet_id      = aws_subnet.mgmt.id
  route_table_id = aws_route_table.internet-gw.id
}

#
# Create a security group for Environment
#
module "mgmt-network-security-group" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-mgmt-nsg", local.app_id)
  description = "Security group for BIG-IP Management"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = var.AllowedIPs
  ingress_rules       = ["http-80-tcp","https-443-tcp", "https-8443-tcp", "ssh-tcp", "consul-tcp", "consul-webui-tcp", "splunk-web-tcp", "consul-serf-lan-tcp", "consul-serf-lan-udp"]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = format("%s-%s", local.app_id, var.ec2_key_name)
  public_key = tls_private_key.example.public_key_openssh
}

#
# Create BIG-IP
#

module bigip {
  source = "../f5module/"
  count  = var.bigip_count
  prefix = format("%s", local.app_id)
  f5_password = "F5testnet!"
  mgmt_subnet_ids        = [{ "subnet_id" = aws_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids = [module.mgmt-network-security-group.security_group_id]
  app_name                  = var.app_name
  consul_ip                 = aws_instance.consulvm.private_ip
  hostname                  = local.hostname
  app_id                    = local.app_id
  tg_arn                    = aws_lb_target_group.nlb_tg.arn
  splunkIP                  = var.splunkIP
  splunkHEC                 = var.splunkHEC
  logStashIP                = var.logStashIP
  law_id                    = var.law_id
  law_primarykey            = var.law_primarykey
  ts_consumer               = var.ts_consumer

  providers = {
    consul = consul
  }
}

resource "null_resource" "clusterDO" {
  count = var.bigip_count
  provisioner "local-exec" {
    command = "cat > DO_1nic.json <<EOL\n ${module.bigip[count.index].onboard_do}\nEOL"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf DO_1nic.json"
  }
  depends_on = [module.bigip]
}

data "template_file" "tfstate" {
  template          = file("../../templates/tfstate.tpl")
  vars = {
    app_id              = local.app_id
    consul_ip           = aws_instance.consulvm.public_ip
  }
}

resource "local_file" "tfstate" {
  content  = data.template_file.tfstate.rendered
  filename = "tfstate.tf"
}
