data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["${var.f5_ami_search_name}"]
  }
}


resource "aws_autoscaling_group" "f5asg" {
  name                 = "${var.prefix}f5asg"
  launch_configuration = "${aws_launch_configuration.f5asg.name}"
  desired_capacity     = 2
  min_size             = 1
  max_size             = 4
  vpc_zone_identifier  = ["${module.vpc.public_subnets[0]}"]
  health_check_type = "ELB"

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.prefix}f5asg"
      propagate_at_launch = true
    },
    {
      key                 = "Env"
      value               = "consul"
      propagate_at_launch = true
    },
  ]

}

resource "aws_launch_configuration" "f5asg" {
  name_prefix                 = "${var.prefix}f5asg"
  image_id                    = "${data.aws_ami.f5_ami.id}"
  instance_type               = "m5.xlarge"
  associate_public_ip_address = true

  security_groups = ["${aws_security_group.f5asg.id}"]
  key_name        = "${aws_key_pair.demo.key_name}"
  user_data       = data.template_file.vm_onboard.rendered
  iam_instance_profile = "${aws_iam_instance_profile.bigip.name}"

  lifecycle {
    create_before_destroy = true
  }
}

# Setup Onboarding scripts
data "template_file" "vm_onboard" {
  template = file("${path.module}/onboard.tpl")

  vars = {
    admin_user     = var.uname
    admin_password = var.upassword
    DO_URL         = var.DO_URL
    AS3_URL        = var.AS3_URL
    TS_URL         = var.TS_URL
    libs_dir       = var.libs_dir
    onboard_log    = var.onboard_log
    DO_Document    = data.template_file.vm01_do_json.rendered
    AS3_Document   = data.template_file.as3_json.rendered
    TS_Document    = data.template_file.ts_json.rendered
  }
}

data "template_file" "vm01_do_json" {
  template = file("${path.module}/do.json")

  vars = {
    local_host         = "-device.hostname-"
    hostname           = "bigip.aws.${var.region}.${var.prefix}f5asg.com"
    local_selfip       = "-external-self-address-"
    gateway            = var.ext_gw
    dns_server         = var.dns_server
    ntp_server         = var.ntp_server
    timezone           = var.timezone
    bigIqLicenseType   = var.bigIqLicenseType
    bigIqHost          = var.bigIqHost
    bigIqUsername      = var.bigIqUsername
    bigIqPassword      = var.bigIqPassword
    bigIqLicensePool   = var.bigIqLicensePool
    bigIqSkuKeyword1   = var.bigIqSkuKeyword1
    bigIqSkuKeyword2   = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure = var.bigIqUnitOfMeasure
    bigIqHypervisor    = var.bigIqHypervisor
    region             = var.region
  }
}

data "template_file" "as3_json" {
  template = file("${path.module}/as3.json")
  vars = {
    backendvm_ip    = var.backend01ext
    web_pool        = "myapp-${var.app}"
    tls_cert        = var.tls_cert
    tls_pswd        = var.tls_pswd
  }
}

  data "template_file" "ts_json" {
  template = file("${path.module}/ts.json")

  vars = {
    region      = var.location
    logStashIP  = var.logStashIP
    logStashPort = var.logStashPort
    wrkspaceID  = var.wrkspaceID
    passphrase  = var.passphrase
  }
}
