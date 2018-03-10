# VPC and Network Settings
variable "vpc-name" {
	type = "string"
	default = "weave-ecs-demo-vpc"
}
variable "subnet-name" {
	type = "string"
	default = "weave-ecs-demo-subnet"
}
variable "gateway-name" {
	type = "string"
	default = "weave-ecs-demo"
}
variable "security-group-name" {
	type = "string"
	default = "weave-ecs-demo"
}

# IAM settings
variable "role-name" {
  type = "string"
	default = "weave-ecs-role"
}
variable "policy-name" {
	type = "string"
	default = "weave-ecs-policy"
}
variable "instance-profile-name" {
	type = "string"
	default = "weave-ecs-instance-profile"
}

# EC2 settings
variable "key-name" {
	type = "string"
	default = "weave-ecs-demo-key"
}
variable "launch-configuration-name" {
	type = "string"
	default = "weave-ecs-launch-configuration"
}
variable "auto-scaling-group-name" {
	type = "string"
	default = "weave-ecs-demo-group"
}

# ECS settings
variable "cluster-name" {
	type = "string"
	default = "weave-ecs-demo-cluster"
}
variable "task-name" {
	type = "string"
	default = "weave-ecs-demo-task"
}
variable "service-name" {
	type = "string"
	default = "weave-ecs-demo-service"
}
