####################
# Tag
####################

locals {
  tags = {
    Name = "${var.tag_name}"
  }
}

####################
# Provider
####################

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

####################
# IAM
####################

data aws_iam_policy_document "ecs_instance_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow",
    principals {
      identifiers = [
        "ec2.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.ecs_instance_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_instance_role.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role" {
  name = "${var.ecs_instance_role_name}"
  role = "${aws_iam_role.ecs_instance_role.name}"
}

data aws_iam_policy_document "aws_batch_service_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow",
    principals {
      identifiers = [
        "batch.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "aws_batch_service_role" {
  name = "${var.aws_batch_service_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.aws_batch_service_role.json}"
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role = "${aws_iam_role.aws_batch_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

data aws_iam_policy_document "ecs_tasks_service_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    effect = "Allow",
    principals {
      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "ecs_tasks_service_role" {
  name = "${var.ecs_tasks_service_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_tasks_service_role.json}"
}

#
# Comment in when tasks use s3 access.
#
# resource "aws_iam_role_policy_attachment" "ecs_tasks_service_role" {
#   role = "${aws_iam_role.ecs_tasks_service_role.name}"
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
# }
#

####################
# Networks
####################

resource "aws_vpc" "this" {
  cidr_block = "${var.vpc_cidr_block}"
  tags = "${local.tags}"
}

resource "aws_subnet" "this" {
  vpc_id = "${aws_vpc.this.id}"
  cidr_block = "${var.subnet_cidr_block}"
  map_public_ip_on_launch = true
  tags = "${local.tags}"
}

resource "aws_internet_gateway" "this" {
  vpc_id = "${aws_vpc.this.id}"
  tags = "${local.tags}"
}

resource "aws_route_table" "this" {
  vpc_id = "${aws_vpc.this.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.this.id}"
  }

  tags = "${local.tags}"
}

resource "aws_route_table_association" "this" {
  subnet_id = "${aws_subnet.this.id}"
  route_table_id = "${aws_route_table.this.id}"
}

####################
# Security Groups
####################

resource "aws_security_group" "this" {
  vpc_id = "${aws_vpc.this.id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = "${local.tags}"
}

####################
# Batch Environment
####################

resource "aws_batch_compute_environment" "this" {
  compute_environment_name = "${var.tag_name}-compute-environment"
  compute_resources {
    instance_role = "${aws_iam_instance_profile.ecs_instance_role.arn}"
    instance_type = [
      "${var.batch_compute_environment_instance_types}",
    ]
    min_vcpus = "${var.batch_compute_environment_min_vcpus}"
    max_vcpus = "${var.batch_compute_environment_max_vcpus}"
    security_group_ids = [
      "${aws_security_group.this.id}"
    ]
    subnets = [
      "${aws_subnet.this.id}"
    ]
    type = "EC2"
    tags = "${local.tags}"
  }
  service_role = "${aws_iam_role.aws_batch_service_role.arn}"
  type = "MANAGED"
  depends_on = [
    "aws_iam_role_policy_attachment.aws_batch_service_role",
  ]
  lifecycle {
    ignore_changes = [
      "compute_resources.0.desired_vcpus",
    ]
  }
}

resource "aws_batch_job_queue" "this" {
  name = "${var.tag_name}-job-queue"
  state = "ENABLED"
  priority = "${var.batch_job_queue_priority}"
  compute_environments = [
    "${aws_batch_compute_environment.this.arn}",
  ]
}

####################
# Batch Job
####################

resource "aws_batch_job_definition" "example" {
  name = "${var.tag_name}-job-definition"
  type = "container"
  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["echo", "Hello World"],
    "image": "busybox",
    "memory": 1024,
    "vcpus": 1,
    "environment": [
        {"name": "EXAMPLE_KEY", "value": "EXAMPLE_VALUE"}
    ]
}
CONTAINER_PROPERTIES
}
