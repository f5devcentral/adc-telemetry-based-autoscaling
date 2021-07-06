
#
# Deploy Workloads
#

data "template_file" "backendapp" {
  template          = file("../../templates/backendapp_aws.tpl")
  vars = {
    app_id              = local.app_id
    consul_ip           = aws_instance.consulvm.private_ip
  }
}

resource "aws_instance" "backendapp" {
  count                       = var.workload_count
  ami                         = data.aws_ami.ubuntu.id
  #availability_zone          = "${var.region}${var.aws_region_az}"
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.mgmt-network-security-group.security_group_id]
  subnet_id                   = aws_subnet.mgmt.id
  #key_name                    = var.ec2_key_name2 == "~/.ssh/id_rsa.pub" ? aws_key_pair.instance_key.key_name : var.ec2_key_name2
  key_name                    = var.ec2_key_name

  root_block_device {
    delete_on_termination = true
  }

  iam_instance_profile = var.aws_iam_instance_profile
  user_data            = data.template_file.backendapp.rendered
  provisioner "local-exec" {
    command = "sleep 300"
  }
 
  tags = {
    Name                = "${local.app_id}-backendapp-${count.index}"
    environment         = var.environment
    owner               = var.owner
    group               = var.group
    costcenter          = var.costcenter
    application         = var.application
    tag_name            = "Env"
    value               = "consul"
    propagate_at_launch = true
    key                 = "Env"
    value               = "consul"
  }
}
