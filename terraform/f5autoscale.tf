resource "aws_autoscaling_group" "f5asg" {
  name                 = "${var.prefix}-f5asg-asg"
  launch_configuration = "${aws_launch_configuration.f5asg.name}"
  desired_capacity     = 2
  min_size             = 1
  max_size             = 4
  vpc_zone_identifier  = ["${module.vpc.public_subnets[0]}"]

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.prefix}-f5asg"
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
  name_prefix                 = "${var.prefix}-f5asg-"
  image_id                    = "${data.aws_ami.f5_ami.id}"
  instance_type               = "m5.xlarge"
  associate_public_ip_address = true

  security_groups = ["${aws_security_group.f5asg.id}"]
  key_name        = "${aws_key_pair.demo.key_name}"
  user_data       = "${aws_iam_instance_profile.bigip.name}"
  iam_instance_profile = "${aws_iam_instance_profile.bigip.name}"

  lifecycle {
    create_before_destroy = true
  }
}