resource "aws_instance" "alertForwarder" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "m5.large"
  private_ip             = "10.0.0.115"
  subnet_id              = "${module.vpc.public_subnets[0]}"
  vpc_security_group_ids = ["${aws_security_group.alertForwarder.id}"]
  user_data              = "${file("../scripts/alertForwarder.sh")}"
  iam_instance_profile   = "${aws_iam_instance_profile.alertForwarder.name}"
  key_name               = "${aws_key_pair.demo.key_name}"
  tags = {
    Name = "${var.prefix}-alertForwarder"
  }
}