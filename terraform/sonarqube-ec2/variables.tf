variable "name_prefix" {
  type        = string
  description = "Name prefix for resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID (public recommended)"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "root_volume_size" {
  type        = number
  description = "Root volume size in GiB"
  default     = 30
}

variable "root_volume_type" {
  type        = string
  description = "Root volume type"
  default     = "gp3"
}

variable "ssh_key_name" {
  type        = string
  description = "Existing EC2 key pair name for SSH access"
  default     = "mmsuzon-aws"
}

variable "allowed_cidr" {
  type        = string
  description = "CIDR allowed to access SonarQube (9000) and SSH (22)"
  default     = "0.0.0.0/0"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = {}
}
