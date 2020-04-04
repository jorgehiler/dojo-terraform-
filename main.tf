provider "aws" {
  region = "us-east-2"
}

variable "server_port" {
  description = "the port the server will use for HTTP request"
  default     = 8080
}


resource "aws_security_group" "instance" {
  name = "terraform-jorgehiler"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}



data "aws_availability_zones" "all" {

}

resource "aws_launch_configuration" "example" {
  image_id        = "ami-0fc20dd1da406780b"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]


  user_data = <<-EOF
              #!/bin/bash
              echo "Hello World, jorgehiler!" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }

}

//el cluster recibe ayuda del load_balancer

//el ELB defie el check type
resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = "${data.aws_availability_zones.all.names}"
  
  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"
  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-jorgehiler-cluster"
    propagate_at_launch = true
  }

}

resource "aws_elb" "example" {
	name = "terraform-jorgehiler-cluster"
	availability_zones = "${data.aws_availability_zones.all.names}"
	security_groups = ["${aws_security_group.elb.id}"]

	listener {
		lb_port = "80"
		lb_protocol = "http"
		instance_port = "${var.server_port}"
		instance_protocol = "http"
	}

	health_check {
		healthy_threshold = 2
		unhealthy_threshold = 2
		timeout = 3
		interval = 30
		target = "HTTP:${var.server_port}/"
	}
  
}

resource "aws_security_group" "elb" {
	name = "terraform-jorgehiler-elb"

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

    //A todos los protocolos
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
  
}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}




