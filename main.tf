# Backend 
####################
provider "aws" {
  region       = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-jpr"
    key    = "weave/example"
    region = "us-east-1"
  }
}

# VPC and Networking
######################
resource "aws_vpc" "container_vpc" {
  cidr_block           = "172.31.0.0/28"
  enable_dns_support   = true
  enable_dns_hostnames = true 

  tags {
    Name = "${var.vpc-name}"
  }
}

resource "aws_subnet" "container_subnet" {
  vpc_id               = "${aws_vpc.container_vpc.id}"
  cidr_block           = "172.31.0.0/28"
  
  tags {
    Name = "${var.subnet-name}"
  }
}

resource "aws_internet_gateway" "container_gateway" {
  vpc_id               = "${aws_vpc.container_vpc.id}"

  tags {
    Name = "${var.gateway-name}"
  }
}

resource "aws_route" "default_conatainer_route" {
  route_table_id         = "${aws_vpc.container_vpc.default_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.container_gateway.id}"
}

# Security Groups
########################

resource "aws_security_group" "weave_demo" {
  name        = "${var.security-group-name}"
  description = "Weave Demo"
  vpc_id      = "${aws_vpc.container_vpc.id}"
}

resource "aws_security_group_rule" "out" {
  type            = "egress"
  from_port       = 0
  to_port         = 0
  protocol        = "-1"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.weave_demo.id}"
}

resource "aws_security_group_rule" "ssh" {
  type            = "ingress"
  from_port       = "22"
  to_port         = "22"
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.weave_demo.id}"
}

resource "aws_security_group_rule" "http" {
  type            = "ingress"
  from_port       = "80"
  to_port         = "80"
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.weave_demo.id}"
}
  
resource "aws_security_group_rule" "weave_scope_ext" {
  type            = "ingress"
  from_port       = "4040"
  to_port         = "4040"
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.weave_demo.id}"
}
  
resource "aws_security_group_rule" "weave_scope_int" {
  type                     = "ingress"
  from_port                = "4040"
  to_port                  = "4040"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.weave_demo.id}"

  security_group_id        = "${aws_security_group.weave_demo.id}"
}
  
resource "aws_security_group_rule" "weave_tcp" {
  type                     = "ingress"
  from_port                = "6783"
  to_port                  = "6783"
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.weave_demo.id}"

  security_group_id        = "${aws_security_group.weave_demo.id}"
}
  
resource "aws_security_group_rule" "weave_udp" {
  type                     = "ingress"
  from_port                = "6783"
  to_port                  = "6783"
  protocol                 = "udp"
  source_security_group_id = "${aws_security_group.weave_demo.id}"

  security_group_id        = "${aws_security_group.weave_demo.id}"
}
  
resource "aws_security_group_rule" "fast_dp" {
  type                     = "ingress"
  from_port                = "6784"
  to_port                  = "6784"
  protocol                 = "udp"
  source_security_group_id = "${aws_security_group.weave_demo.id}"

  security_group_id        = "${aws_security_group.weave_demo.id}"
}

# AWS IAM
########################

resource "aws_iam_role" "weave_ecs_role" {
  name       = "${var.role-name}"
 assume_role_policy = "${file("data/weave-ecs-role.json")}"
}

resource "aws_iam_role_policy" "weave_ecs_policy" {
  name       = "${var.policy-name}"
  role       = "${aws_iam_role.weave_ecs_role.name}"
  policy     = "${file("data/weave-ecs-policy.json")}"
}

resource "aws_iam_instance_profile" "weave_ecs_instance_profile" {
  name       = "${var.instance-profile-name}"
  role       = "${aws_iam_role.weave_ecs_role.name}"
}

# ECS and EC2
########################
resource "aws_ecs_cluster" "weave_example" {
  name = "${var.cluster-name}"
}

resource "aws_launch_configuration" "weave_ecs_lc" {
  name                        = "${var.launch-configuration-name}"
  image_id                    = "ami-cc6c71b7"
  key_name                    = "weave-ecs-demo-key"
  security_groups             = ["${aws_security_group.weave_demo.id}"]
  instance_type               = "t2.micro"
  user_data                   = "${file("user_data.sh")}"
  iam_instance_profile        = "${aws_iam_instance_profile.weave_ecs_instance_profile.id}"
  associate_public_ip_address = true
  enable_monitoring           = false
}

resource "aws_autoscaling_group" "weave_ecs_demo" {
  name                        = "${var.auto-scaling-group-name}"
  launch_configuration        = "${aws_launch_configuration.weave_ecs_lc.name}"
  min_size                    = 3
  max_size                    = 3
  desired_capacity            = 3 
  vpc_zone_identifier         = ["${aws_subnet.container_subnet.id}"]
}

resource "aws_ecs_task_definition" "weave_demo" {
  family     = "${var.task-name}"
  container_definitions = "${file("data/weave-ecs-demo-containers.json")}"
}

resource "aws_ecs_service" "weave_demo" {
  name       = "${var.service-name}"
  cluster    = "${aws_ecs_cluster.weave_example.id}"
  task_definition = "${aws_ecs_task_definition.weave_demo.arn}"
  desired_count   = 3
  depends_on      = ["aws_iam_role_policy.weave_ecs_policy"]
}
