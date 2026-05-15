variable "name" {
  type        = string
  description = "VPC name"
}

variable "cidr" {
  type        = string
  description = "VPC CIDR"
}

variable "azs" {
  type        = list(string)
  description = "AZs"
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet CIDRs"
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet CIDRs"
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use a single NAT gateway"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = {}
}
