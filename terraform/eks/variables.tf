variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_version" {
  type        = string
  description = "EKS version"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for nodes"
}

variable "eks_general_desired_size" {
  type        = number
  description = "General node group desired size"
}
variable "eks_general_min_size" {
  type        = number
  description = "General node group min size"
}
variable "eks_general_max_size" {
  type        = number
  description = "General node group max size"
}
variable "eks_general_instance_types" {
  type        = list(string)
  description = "General node group instance types"
}

variable "eks_spot_desired_size" {
  type        = number
  description = "Spot node group desired size"
}
variable "eks_spot_min_size" {
  type        = number
  description = "Spot node group min size"
}
variable "eks_spot_max_size" {
  type        = number
  description = "Spot node group max size"
}
variable "eks_spot_instance_types" {
  type        = list(string)
  description = "Spot node group instance types"
}

variable "enable_ebs_csi_addon" {
  type        = bool
  description = "Install aws-ebs-csi-driver via Helm with IRSA"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = {}
}
