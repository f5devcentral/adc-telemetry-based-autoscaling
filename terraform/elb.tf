
 # Declare the data source
data "aws_availability_zones" "available" {
  state = "available"
}

# e.g. Create subnets in the first two available availability zones

resource "aws_subnet" "primary" {
  availability_zone = data.aws_availability_zones.available.names[0]
 vpc_id = "${module.vpc.vpc_id}"
 cidr_block = "11.0.0.0/16"
  # ...
}

resource "aws_subnet" "secondary" {
  availability_zone = data.aws_availability_zones.available.names[1]
 vpc_id = "${module.vpc.vpc_id}"
 cidr_block = "11.0.0.0/16"
  # ...
}

resource "aws_security_group" "elb" {
  name = "adcp-elb"
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Inbound HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 resource "aws_elb" "adcpe-elb" {
  name               = "adcp-elb"
  availability_zones = data.aws_availability_zones.available.names
  security_groups    = [aws_security_group.elb.id]
  health_check {
    target              = "HTTP:8080/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  # This adds a listener for incoming HTTP requests.
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 8080
    instance_protocol = "http"
  }
}