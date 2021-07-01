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

