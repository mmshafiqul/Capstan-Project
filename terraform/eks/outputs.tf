output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS endpoint"
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "CA data"
}

output "node_security_group_id" {
  value       = module.eks.node_security_group_id
  description = "Node security group"
}

output "ebs_csi_role_arn" {
  value       = try(aws_iam_role.ebs_csi[0].arn, null)
  description = "IAM role ARN used by the EBS CSI driver service account"
}
