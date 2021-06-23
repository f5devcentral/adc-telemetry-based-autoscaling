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