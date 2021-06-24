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
  owners = ["099720109477"] # Canonical
}

variable ec2_key_name2 {
  description = "AWS EC2 Key name for SSH access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable aws_iam_instance_profile {
  description = "aws_iam_instance_profile"
  type        = string
  default     = null
}

resource "aws_key_pair" "instance_key" {
  key_name   = format("%s-key", local.app_id)
  public_key = file("~/.ssh/id_rsa.pub")
}

#
# Deploy Consul Server
#

resource "aws_instance" "consulvm" {
  ami                         = data.aws_ami.ubuntu.id
  #availability_zone          = "${var.region}${var.aws_region_az}"
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.mgmt-network-security-group.security_group_id]
  subnet_id                   = aws_subnet.mgmt.id
  key_name                    = var.ec2_key_name2 == "~/.ssh/id_rsa.pub" ? aws_key_pair.instance_key.key_name : var.ec2_key_name2
 
  root_block_device {
    delete_on_termination = true
  }

  iam_instance_profile = var.aws_iam_instance_profile
  user_data            = file("../../scripts/consul.sh")
  provisioner "local-exec" {
    command = "sleep 300"
  }
 
  tags = {
    "Owner"               = "Canonical"
    "Name"                = "consul-vm"
    "KeepInstanceRunning" = "false"
  }
}

#
# Update consul server
#

provider "consul" {
  address = "${aws_instance.consulvm.public_ip}:8500"
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
  #key {
  #  path  = format("adpm/applications/%s/terraform/outputs/bigip_mgmt", local.app_id)
  #  value = "https://${module.bigip.0.mgmtPublicIP}:8443"
  #}
  #key {
  #  path  = format("adpm/applications/%s/terraform/outputs/application_address", local.app_id )
  #  value = "https://${azurerm_public_ip.nlb_public_ip.ip_address}"
  #}
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
}

#
# Deploy Alert Forwarder
#

data "template_file" "alertfwd" {
  template          = file("../../templates/alertfwd.tpl")
  vars = {
    github_token    = var.github_token
    repo_path       = var.repo_path
  }
}

resource "aws_instance" "alertforwardervm" {
  ami                         = data.aws_ami.ubuntu.id
  #availability_zone          = "${var.region}${var.aws_region_az}"
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.mgmt-network-security-group.security_group_id]
  subnet_id                   = aws_subnet.mgmt.id
  key_name                    = var.ec2_key_name2 == "~/.ssh/id_rsa.pub" ? aws_key_pair.instance_key.key_name : var.ec2_key_name2
 
  root_block_device {
    delete_on_termination = true
  }

  iam_instance_profile = var.aws_iam_instance_profile
  user_data            = data.template_file.alertfwd.rendered
  provisioner "local-exec" {
    command = "sleep 300"
  }
 
  tags = {
    "Owner"               = "Canonical"
    "Name"                = "alertForwarder-vm"
    "KeepInstanceRunning" = "false"
  }
}