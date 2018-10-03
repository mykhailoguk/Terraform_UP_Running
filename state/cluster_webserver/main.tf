terraform {
  backend "s3" {
    bucket          = "terraform-up-and-running-state-mguk"
    key             = "terraform_web_cluser/terraform.tfstate"
    dynamodb_table  = "terraform-state-lock-dynamo"
    profile         = "training"
    region          = "us-east-1"
  }
}

provider "aws" {
  region  = "${var.region}"
  profile = "${var.profile}"
}

### ec2 cluster
resource "aws_launch_configuration" "web_cluster" {
  image_id           = "${var.ami}"
  instance_type = "${var.instance_type}"
  security_groups = ["${aws_security_group.allow_trafic_8080.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "allow_trafic_8080" {
  name = "aws-web-server-group"
  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_blocks}"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb" {
  name = "web-cluster-elb-sec"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }  
}

data "aws_availability_zones" "all" {}

resource "aws_elb" "web_cluster_elb" {
  name               = "terraform-web-cluster-elb"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }  
}

resource "aws_autoscaling_group" "web_cluser_autoscaling" {
  launch_configuration = "${aws_launch_configuration.web_cluster.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  load_balancers    = ["${aws_elb.web_cluster_elb.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 3

  tag {
    key                 = "Name"
    value               = "terraform-asg-web-cluster"
    propagate_at_launch = true
  }
}
