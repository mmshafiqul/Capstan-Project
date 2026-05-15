variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "mmsuzon-urlshortner"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "mmsuzon-urlshortner-eks"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "urlshortner.local"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = []
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway"
  type        = bool
  default     = true
}

variable "eks_general_desired_size" {
  type        = number
  default     = 3
  description = "Desired size for general node group"
}

variable "eks_general_min_size" {
  type        = number
  default     = 1
  description = "Min size for general node group"
}

variable "eks_general_max_size" {
  type        = number
  default     = 10
  description = "Max size for general node group"
}

variable "eks_general_instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = "Instance types for general node group"
}

variable "eks_spot_desired_size" {
  type        = number
  default     = 2
  description = "Desired size for spot node group"
}

variable "eks_spot_min_size" {
  type        = number
  default     = 0
  description = "Min size for spot node group"
}

variable "eks_spot_max_size" {
  type        = number
  default     = 5
  description = "Max size for spot node group"
}

variable "eks_spot_instance_types" {
  type        = list(string)
  default     = ["t3.small"]
  description = "Instance types for spot node group"
}

variable "enable_ebs_csi_addon" {
  description = "Install the aws-ebs-csi-driver via Helm with IRSA (required for dynamic EBS PVC provisioning)"
  type        = bool
  default     = true
}

variable "enable_addons" {
  description = "Deprecated in this repo; add-ons are installed by scripts/deploy.sh"
  type        = bool
  default     = true
}

variable "ingress_nginx_replica_count" {
  description = "Deprecated in this repo; add-ons are installed by scripts/deploy.sh"
  type        = number
  default     = 2
}

variable "grafana_admin_password" {
  description = "Deprecated in this repo; add-ons are installed by scripts/deploy.sh"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "enable_metrics_server" {
  description = "Deprecated in this repo; add-ons are installed by scripts/deploy.sh"
  type        = bool
  default     = true
}

variable "deploy_k8s_manifests" {
  description = "Deprecated in this repo; k8s manifests are applied by scripts/deploy.sh or GitHub Actions"
  type        = bool
  default     = false
}

# Variables kept only to silence warnings from terrform.tfvars (future/optional EC2 approach).
variable "prometheus_storage_size" {
  type    = string
  default = "20Gi"
}

variable "monitoring_namespace" {
  type    = string
  default = "monitoring"
}

variable "sonarqube_instance_type" {
  type    = string
  default = "t3.large"
}

variable "sonarqube_root_volume_size" {
  type    = number
  default = 16
}

variable "sonarqube_root_volume_type" {
  type    = string
  default = "gp3"
}

variable "sonarqube_ssh_key_name" {
  type    = string
  default = ""
}

variable "monitoring_instance_type" {
  type    = string
  default = "t3.large"
}

variable "monitoring_root_volume_size" {
  type    = number
  default = 20
}

variable "monitoring_root_volume_type" {
  type    = string
  default = "gp3"
}

variable "monitoring_ssh_key_name" {
  type    = string
  default = ""
}

variable "allowed_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "ingress_controller_replica_count" {
  type    = number
  default = 2
}

variable "ingress_service_type" {
  type    = string
  default = "LoadBalancer"
}

variable "aws_load_balancer_type" {
  type    = string
  default = "nlb"
}

variable "enable_sonarqube_ec2" {
  description = "Provision a self-hosted SonarQube server on EC2 (Docker)"
  type        = bool
  default     = true
}
