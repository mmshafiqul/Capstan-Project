output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "node_security_group_id" {
  description = "Node security group ID"
  value       = module.eks.node_security_group_id
}

output "ebs_csi_role_arn" {
  description = "IAM role ARN used by the EBS CSI driver service account"
  value       = module.eks.ebs_csi_role_arn
}

output "sonarqube_public_ip" {
  description = "Public IP of the SonarQube EC2 instance (if enabled)"
  value       = try(module.sonarqube_ec2[0].public_ip, null)
}

output "sonarqube_url" {
  description = "SonarQube URL (if enabled)"
  value       = try(module.sonarqube_ec2[0].url, null)
}
