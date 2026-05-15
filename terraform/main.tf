locals {
  name = var.project_name
  tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
    },
    var.tags
  )
}

module "vpc" {
  source = "./vpc"

  name               = "${local.name}-vpc"
  cidr               = var.vpc_cidr
  azs                = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  single_nat_gateway = var.single_nat_gateway

  tags = local.tags
}

module "eks" {
  source = "./eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_general_desired_size   = var.eks_general_desired_size
  eks_general_min_size       = var.eks_general_min_size
  eks_general_max_size       = var.eks_general_max_size
  eks_general_instance_types = var.eks_general_instance_types

  eks_spot_desired_size   = var.eks_spot_desired_size
  eks_spot_min_size       = var.eks_spot_min_size
  eks_spot_max_size       = var.eks_spot_max_size
  eks_spot_instance_types = var.eks_spot_instance_types

  enable_ebs_csi_addon = var.enable_ebs_csi_addon

  tags = local.tags
}

module "sonarqube_ec2" {
  source = "./sonarqube-ec2"
  count  = var.enable_sonarqube_ec2 ? 1 : 0

  name_prefix = local.name
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.public_subnets[0]

  instance_type    = var.sonarqube_instance_type
  root_volume_size = var.sonarqube_root_volume_size
  root_volume_type = var.sonarqube_root_volume_type
  ssh_key_name     = var.sonarqube_ssh_key_name
  allowed_cidr     = var.allowed_cidr

  tags = local.tags
}
