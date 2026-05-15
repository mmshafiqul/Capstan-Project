# Terraform Configuration for URL Shortener Microservices on AWS EKS

This directory contains the Terraform configuration to deploy the URL shortener microservices application on AWS EKS.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- kubectl
- helm

## Architecture

The infrastructure includes:

- **VPC**: Custom VPC with public and private subnets across 3 AZs
- **EKS Cluster**: Kubernetes 1.29 with managed node groups
- **Node Groups**: 
  - General purpose: 3x t3.medium instances (on-demand)
  - Spot instances: 2x t3.small instances (cost optimization)
- **Ingress Controller**: NGINX Ingress with AWS Network Load Balancer
- **Monitoring**: Prometheus and Grafana stack

## Deployment Steps

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Plan and Apply

```bash
# Review the plan
terraform plan -var-file=terrform.tfvars

# Apply the configuration
terraform apply -var-file=terrform.tfvars
```

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --region $(terraform output -raw region) --name $(terraform output -raw cluster_name)
```

### 4. Verify the cluster

```bash
kubectl get nodes
kubectl get pods -A
```

## Add-ons (Ingress + Monitoring)

This repository installs add-ons via `scripts/deploy.sh` (Helm), not Terraform.

## Deploy the Application Manifests

You have two options:

1) Recommended: use the GitHub Actions workflow (`.github/workflows/deploy.yml`)
2) From your machine: `kubectl apply -f k8s/` (or run `./scripts/deploy.sh` which does it automatically)

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-east-1` |
| `project_name` | Project name | `urlshortner-microservices` |
| `environment` | Environment | `dev` |
| `domain_name` | Domain name | `urlshortner.local` |

## Outputs

- `cluster_name`: EKS cluster name
- `cluster_endpoint`: EKS cluster endpoint
- `region`: AWS region
- `vpc_id`: VPC ID

## Cost Optimization

- Mixed instance strategy (on-demand + spot)
- Auto-scaling node groups
- NLB instead of ALB for better performance
- EBS storage for Prometheus metrics

## Security

- Private EKS endpoints
- Security group rules for node communication
- IRSA for EBS CSI driver
- IAM roles with least privilege

## Cleanup

```bash
terraform destroy
```
