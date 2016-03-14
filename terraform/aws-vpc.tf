provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region = "eu-west-1"
}

resource "aws_vpc" "vpc" {
	cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "gateway" {
	vpc_id = "${aws_vpc.vpc.id}"
}

# NAT instance

resource "aws_security_group" "nat" {
	name = "nat"
	description = "Allow services from the private subnet through NAT"

	ingress {
		from_port = 0
		to_port = 65535
		protocol = "tcp"
		cidr_blocks = ["${aws_subnet.eu-west-1b-private.cidr_block}"]
	}

	vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_instance" "nat" {
	ami = "${var.aws_nat_ami}"
	availability_zone = "eu-west-1b"
	instance_type = "t1.micro"
	key_name = "${var.aws_key_name}"
	security_groups = ["${aws_security_group.nat.id}"]
	subnet_id = "${aws_subnet.eu-west-1b-public.id}"
	associate_public_ip_address = true
	source_dest_check = false
        tags = {
          Name = "nat"
          subnet = "eu-west-1b-public"
          role = "nat"
        }
}

resource "aws_eip" "nat" {
	instance = "${aws_instance.nat.id}"
	vpc = true
}

# Public subnets

resource "aws_subnet" "eu-west-1b-public" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.0.0.0/24"
	availability_zone = "eu-west-1b"
}

# Routing table for public subnets

resource "aws_route_table" "eu-west-1-public" {
	vpc_id = "${aws_vpc.vpc.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.gateway.id}"
	}
}

resource "aws_route_table_association" "eu-west-1b-public" {
	subnet_id = "${aws_subnet.eu-west-1b-public.id}"
	route_table_id = "${aws_route_table.eu-west-1-public.id}"
}

# Private subnets

resource "aws_subnet" "eu-west-1b-private" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.0.1.0/24"
	availability_zone = "eu-west-1b"
}

# Routing table for private subnets

resource "aws_route_table" "eu-west-1-private" {
	vpc_id = "${aws_vpc.vpc.id}"
	route {
		cidr_block = "0.0.0.0/0"
		instance_id = "${aws_instance.nat.id}"
	}
}

resource "aws_route_table_association" "eu-west-1b-private" {
	subnet_id = "${aws_subnet.eu-west-1b-private.id}"
	route_table_id = "${aws_route_table.eu-west-1-private.id}"
}

# Bastion

resource "aws_security_group" "bastion" {
  name        = "bastion"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "Bastion security group"
  tags      { Name = "bastion" }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NAT
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = [
        "${aws_subnet.eu-west-1b-private.cidr_block}",
        "${aws_subnet.eu-west-1b-public.cidr_block}"
    ]
    self = false
  }

  egress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${aws_subnet.eu-west-1b-private.cidr_block}"]
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.aws_key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "bastion" {
	ami = "${var.aws_ubuntu_ami}"
	availability_zone = "eu-west-1b"
	instance_type = "t1.micro"
	security_groups = ["${aws_security_group.bastion.id}"]
	subnet_id = "${aws_subnet.eu-west-1b-public.id}"
        connection {
          user = "ubuntu"
        }
        key_name = "${aws_key_pair.auth.id}"
        tags = {
          Name = "bastion"
          subnet = "eu-west-1b-public"
          role = "bastion"
        }
}

resource "aws_security_group" "allow_bastion" {
    name = "allow_bastion_ssh"
    description = "Allow access from bastion host"
    vpc_id = "${aws_vpc.vpc.id}"
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        security_groups = [
                "${aws_security_group.bastion.id}",
                "${aws_security_group.nat.id}",
                "${aws_security_group.elb.id}",
                "${aws_security_group.app.id}" 
        ]
        self = false
    }
}

resource "aws_eip" "bastion" {
	instance = "${aws_instance.bastion.id}"
	vpc = true
}

output "bastion" {
    value = "${aws_instance.bastion.public_ip}"
}

# ACL

#resource "aws_network_acl" "acl" {
#  vpc_id = "${aws_vpc.vpc.id}"
#  subnet_ids = [
#        "${aws_subnet.eu-west-1b-public.id}",
#        "${aws_subnet.eu-west-1b-private.id}"
#        ]
#  ingress {
#    protocol   = "-1"
#    rule_no    = 100
#    action     = "allow"
#    cidr_block = "0.0.0.0/0"
#    from_port  = 0
#    to_port    = 0
#  }
#
#  egress {
#    protocol   = "-1"
#    rule_no    = 100
#    action     = "allow"
#    cidr_block = "0.0.0.0/0"
#    from_port  = 0
#    to_port    = 0
#  }
#
#}
#
#resource "aws_network_acl_rule" "acl" {
#    network_acl_id = "${aws_network_acl.acl.id}"
#    rule_number = 200
#    egress = false
#    protocol = "tcp"
#    rule_action = "allow"
#    cidr_block = "0.0.0.0/0"
#    from_port = 22
#    to_port = 22
#}

# ELB

resource "aws_security_group" "elb" {
  name        = "app.elb"
  vpc_id = "${aws_vpc.vpc.id}"
  description = "Security group for App ELB"

  tags      { Name = "app-elb" }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "blue" {
  name                        = "app-blue"
  connection_draining         = true
  connection_draining_timeout = 400

  subnets = ["${aws_subnet.eu-west-1b-public.id}"]
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 8080
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 15
    target              = "HTTP:8080/"
  }
}

resource "aws_elb" "green" {
  name                        = "app-green"
  connection_draining         = true
  connection_draining_timeout = 400

  subnets = ["${aws_subnet.eu-west-1b-public.id}"]
  security_groups = ["${aws_security_group.elb.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 8080
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 15
    target              = "HTTP:8080/"
  }
}

resource "aws_security_group" "app" {
  name        = "app"
  vpc_id = "${aws_vpc.vpc.id}"
  description = "Security group for App"

  tags      { Name = "app" }

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${aws_subnet.eu-west-1b-private.cidr_block}"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Apps
resource "aws_instance" "app-blue" {
        ami = "${var.aws_ubuntu_ami}"
        availability_zone = "eu-west-1b"
        instance_type = "t1.micro"
        security_groups = ["${aws_security_group.app.id}"]
        subnet_id = "${aws_subnet.eu-west-1b-private.id}"
        connection {
          user = "ubuntu"
        }
        key_name = "${aws_key_pair.auth.id}"
        tags = {
          Name = "app-blue"
          subnet = "eu-west-1b-public"
          role = "app-blue"
        }
}

resource "aws_eip" "app-blue" {
        instance = "${aws_instance.app-blue.id}"
        vpc = true
}

resource "aws_instance" "app-green" {
        ami = "${var.aws_ubuntu_ami}"
        availability_zone = "eu-west-1b"
        instance_type = "t1.micro"
        security_groups = ["${aws_security_group.app.id}"]
        subnet_id = "${aws_subnet.eu-west-1b-private.id}"
        connection {
          user = "ubuntu"
        }
        key_name = "${aws_key_pair.auth.id}"
        tags = {
          Name = "app-green"
          subnet = "eu-west-1b-public"
          role = "app-green"
        }
}

resource "aws_eip" "app-green" {
        instance = "${aws_instance.app-green.id}"
        vpc = true
}
