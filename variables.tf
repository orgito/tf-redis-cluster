variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "namespace" {
  description = "Namespace, which could be your organization name or abbreviation, e.g. 'co' or 'company'"
}

variable "stage" {
  description = "Stage, e.g. 'prod', 'staging', 'dev'"
}

variable "region" { }

variable "vpc" {
  description = "VPC ID where to deploy the instances"
}

variable "master_subnet" {
  description = "Subnet ID where to deploy master nodes."
}

variable "slave_subnet" {
  description = "Subnet ID where to deploy slave nodes."
}

variable "instance_type" {
  description = "Redis node instance type"
}

variable "cluster_size" {
  description = "Number of instances to deploy. The final deployment will use double that size, since it will be used for the number of masters and the number of slaves"
  default     = 3
}

variable "storage_size" {
  description = "Root storage size (GB)"
  default     = 100
}

variable "ssh_key_pair" {
  description = "EC2 SSH key name to manage the instances"
}

variable "version" {
  description = "Redis version (5.0.x)."
  default = "5.0.3"
}
