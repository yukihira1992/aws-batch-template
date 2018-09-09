####################
# Tag
####################

variable "tag_name" {
  default = "aws-batch-template"
}

####################
# Provider
####################

variable "aws_region" {
  default = "ap-northeast-1"
}

variable "aws_profile" {
  default = "default"
}

####################
# IAM
####################

variable "ecs_instance_role_name" {
  default = "ECSInstanceRole"
}

variable "aws_batch_service_role_name" {
  default = "AWSBatchServiceRole"
}

variable "ecs_tasks_service_role_name" {
  default = "ECSTasksServiceRoleName"
}

####################
# Networks
####################

variable "vpc_cidr_block" {
  default = "10.1.0.0/16"
}

variable "subnet_cidr_block" {
  default = "10.1.1.0/24"
}

####################
# Batch Environment
####################

variable "batch_compute_environment_instance_types" {
  type = "list"
  default = [
    "optimal",
  ]
}

variable "batch_compute_environment_min_vcpus" {
  default = 0
}

variable "batch_compute_environment_max_vcpus" {
  default = 16
}

variable "batch_job_queue_priority" {
  default = 1
}
