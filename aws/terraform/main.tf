terraform {
  required_providers {
    github = {
      source = "integrations/github"
      version = "4.9.4"  
    }
  }
}

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

# Configure the GitHub Provider
provider "github" {
  token = var.github_token
  owner = var.github_owner
}

resource "github_repository_file" "adpm" {
  repository          = "adc-telemetry-based-autoscaling"
  branch              = "main"
  file                = "aws/consul_server.cfg"
  content             = format("https://%s:8443", aws_instance.consulvm.public_ip)
  commit_message      = format("file contents update by application ID: %s", local.app_id)
  overwrite_on_create = true
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

#
# Create BIG-IP
#

module bigip {
  source = "../f5module/"
  count  = var.bigip_count
  prefix = format("%s", local.app_id)
  f5_password = random_string.password.result
  mgmt_subnet_ids        = [{ "subnet_id" = aws_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids = [module.mgmt-network-security-group.security_group_id]
  app_name                  = var.app_name
  ec2_key_name              = var.ec2_key_name
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

#
# Deploy AWS NLB 
#

resource "aws_eip" "nlb_pip" {
}

resource "aws_lb" "nlb" {
  name               = format("%s-nlb", local.app_id)
  internal           = false
  load_balancer_type = "network"
  enable_deletion_protection = false

  subnet_mapping {
    subnet_id     = aws_subnet.mgmt.id
    allocation_id = aws_eip.nlb_pip.id
  }
}

resource "aws_lb_target_group" "nlb_tg" {
  name     = format("%s-tg", local.app_id)
  port     = 443
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_listener" "nlb_front_end" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}

#
# Find latest Ubuntu AMI in designated region
#
data "aws_ami" "ubuntu" {
  most_recent = true
  
  filter {
    name   = "name"
    values = [var.ubuntu_ami_search_name]
  }

  filter {
        name   = "virtualization-type"
        values = ["hvm"]
  }
  owners = ["679593333241"] # Canonical
}

variable aws_iam_instance_profile {
  description = "aws_iam_instance_profile"
  type        = string
  default     = null
}

#
# Deploy Consul/alertForwarder Server
#

data "template_file" "consul" {
  template          = file("../../templates/consul.tpl")
  vars = {
    consul_ip       = var.consul_ip
    consul_ver      = "1.9.0"    
    github_token    = var.github_token
    repo_path       = var.repo_path
  }
}

resource "aws_instance" "consulvm" {
  ami                         = data.aws_ami.ubuntu.id
  #availability_zone          = "${var.region}${var.aws_region_az}"
  instance_type               = "t3.micro"
  private_ip                  = var.consul_ip
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.mgmt-network-security-group.security_group_id]
  subnet_id                   = aws_subnet.mgmt.id
  key_name                    = var.ec2_key_name

  root_block_device {
    delete_on_termination = true
  }

  iam_instance_profile = var.aws_iam_instance_profile
  user_data            = data.template_file.consul.rendered
  provisioner "local-exec" {
    #command = "aws ec2 wait instance-status-ok --instance-ids ${aws_instance.consulvm.id} --region ${var.region}"
    command = "sleep 300"
  }
 
  tags = {
    "Owner"               = "Canonical"
    "Name"                = "${local.app_id}-consul-vm"
    "KeepInstanceRunning" = "false"
  }
}

#
# Update consul server
#

provider "consul" {
  address = "${aws_instance.consulvm.public_ip}:8443"
  scheme = "https"
  insecure_https  = true
}

resource "consul_keys" "app" {
  datacenter = "dc1"
  # Set the CNAME of our load balancer as a key
  key {
    path  = format("adpm/common/scaling/bigip/min")
    value = var.bigip_min
  }
  key {
    path  = format("adpm/common/scaling/bigip/max")
    value = var.bigip_max
  }
  key {
    path  = format("adpm/common/scaling/workload/min")
    value = var.workload_min
  }
  key {
    path  = format("adpm/common/scaling/workload/max")
    value = var.workload_max
  }
  key {
    path  = format("adpm/common/scaling/min_scaling_interval_seconds")
    value = var.scale_interval
  }
  key {
    path  = format("adpm/applications/%s/scaling/bigip/current_count", local.app_id)
    value = var.bigip_count
  }
  key {
    path  = format("adpm/applications/%s/scaling/workload/current_count", local.app_id)
    value = var.workload_count
  }
  key {
    path  = format("adpm/applications/%s/create_timestamp", local.app_id)
    value = local.event_timestamp
  }
  key {
    path  = format("adpm/applications/%s/scaling/bigip/last_modified_timestamp", local.app_id)
    value = local.event_timestamp
  }
  key {
    path  = format("adpm/applications/%s/scaling/workload/last_modified_timestamp", local.app_id)
    value = local.event_timestamp
  }
  key {
    path  = format("adpm/applications/%s/scaling/is_running", local.app_id)
    value = "false"
  } 
  key {
    path  = format("adpm/applications/%s/terraform/outputs/application_address", local.app_id )
    value = "https://${aws_eip.nlb_pip.public_ip}"
  }
  key {
    path  = format("adpm/applications/%s/github_owner", local.app_id)
    value = var.github_owner
  }
  key {
    path  = format("adpm/applications/%s/repo_path", local.app_id)
    value = var.repo_path
  }
  key {
    path  = format("adpm/applications/%s/ts_consumer", local.app_id)
    value = var.ts_consumer
  }
  key {
    path  = format("adpm/applications/%s/splunkIP", local.app_id)
    value = var.splunkIP
  }
  key {
    path  = format("adpm/applications/%s/splunkHEC", local.app_id)
    value = var.splunkHEC
  }
  key {
     path  = format("adpm/applications/%s/logStashIP", local.app_id)
    value = var.logStashIP
  }
  key {
    path  = format("adpm/applications/%s/law_id", local.app_id)
    value = var.law_id
  }
  key {
    path  = format("adpm/applications/%s/law_primarykey", local.app_id)
    value = var.law_primarykey
  }
  key {
    path  = format("adpm/applications/%s/location", local.app_id )
    value = var.region
  }
  key {
    path  = format("adpm/applications/%s/key_name", local.app_id )
    value = var.ec2_key_name
  }
}