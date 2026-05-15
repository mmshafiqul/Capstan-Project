# URL Shortener Microservices - AWS EKS Deployment Guide

## Project Overview

This project demonstrates a production-ready deployment of a URL shortener microservices application on AWS EKS with comprehensive CI/CD, monitoring, and auto-scaling capabilities.

## Architecture Components

### 🏗️ Infrastructure
- **AWS EKS** (Kubernetes 1.29)
- **VPC** with multi-AZ deployment
- **NLB** for high-performance ingress
- **Auto-scaling node groups** (on-demand + spot)

### 🚀 Microservices
- **Go Service**: URL shortening and redirects
- **Python Service**: Analytics dashboard and orchestration
- **Node.js Service**: Metadata enrichment
- **Redis**: Caching and message broker

### 📊 Monitoring
- **Prometheus**: Metrics collection
- **Grafana**: Visualization and dashboards
- **Alerting**: Proactive monitoring

### 🔄 CI/CD
- **GitHub Actions**: Automated pipeline
- **Docker Hub**: Container registry
- **SonarQube**: Code quality analysis
- **k6**: Load testing

## Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0
3. **kubectl** and **helm**
4. **Docker Hub** account
5. **GitHub** repository with required secrets

### Required GitHub Secrets

Create these secrets in your GitHub repository:

```bash
# AWS Credentials
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key

# Docker Hub
DOCKERHUB_USERNAME=your_dockerhub_username
DOCKERHUB_TOKEN=your_dockerhub_token

# SonarQube
SONAR_TOKEN=your_sonarqube_token
SONAR_HOST_URL=https://sonarcloud.io

# Notifications (optional)
SLACK_WEBHOOK=your_slack_webhook_url
```

### Deployment Steps

#### Option 1: Automated Deployment (Recommended)

```bash
# Clone the repository
git clone <your-repo-url>
cd urlshortner-microservices

# Run the deployment script
export DOCKERHUB_USERNAME=your-dockerhub-username
./scripts/deploy.sh
```

#### Option 2: Manual Deployment

1. **Deploy Infrastructure**
```bash
cd terraform
terraform init
terraform apply
```

2. **Configure kubectl**
```bash
aws eks update-kubeconfig --region us-east-1 --name urlshortner-eks-cluster
```

3. **Deploy Monitoring**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install NGINX Ingress
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer

# Install Prometheus & Grafana
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

4. **Deploy Applications**
```bash
# Update Docker Hub username in deployment files
sed -i 's/your-dockerhub-username/your-actual-username/g' k8s/*.yaml

# Deploy all services
kubectl apply -f k8s/
```

### Access the Application

After deployment, get the load balancer URLs:

```bash
# Get Ingress Load Balancer
kubectl get svc nginx-ingress-ingress-nginx-controller -n ingress-nginx

# Get Grafana URL
kubectl get svc prometheus-grafana -n monitoring
```

**Access Points:**
- **Dashboard**: `http://<ingress-lb-url>/`
- **API**: `http://<ingress-lb-url>/api/`
- **Grafana**: `http://<grafana-lb-url>` (admin/admin123)

## Traffic Spike Testing

The system is designed to handle traffic spikes at 12:00 PM. To test this:

### Automated Load Testing

```bash
# Install k6
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# Run load test
k6 run --vus 100 --duration 5m load-testing/k6-load-test.js
```

### Manual Traffic Simulation

```bash
# Create multiple short URLs
for i in {1..50}; do
  curl -X POST http://<ingress-lb-url>/create \
    -d "long_url=https://example.com/page$i"
done

# Simulate redirects
for i in {1..100}; do
  curl -L http://<ingress-lb-url>/abc123
done
```

### Monitor Auto-scaling

```bash
# Watch HPA scaling
watch kubectl get hpa -n urlshortner

# Watch pod scaling
watch kubectl get pods -n urlshortner

# Check metrics
kubectl top pods -n urlshortner
```

## Monitoring & Observability

### Grafana Dashboards

Access Grafana at `http://<grafana-lb-url>` with credentials `admin/admin123`.

**Available Dashboards:**
- **URL Shortener Overview**: Request rates, response times, error rates
- **Resource Usage**: CPU, memory, and storage metrics
- **HPA Status**: Auto-scaling events and pod counts
- **Redis Metrics**: Cache hit rates and operations

### Key Metrics to Monitor

1. **Performance Metrics**
   - Request rate (requests/sec)
   - Response time (p95 < 500ms)
   - Error rate (< 1%)

2. **Business Metrics**
   - URLs created per minute
   - Redirects per minute
   - Cache hit ratio (> 80%)

3. **Infrastructure Metrics**
   - Pod CPU/Memory usage
   - HPA replica counts
   - Node resource utilization

### Alerting Rules

The system includes pre-configured alerts for:
- High error rates (> 10%)
- Slow response times (> 1s)
- Pod restarts
- HPA at max replicas
- Redis memory usage > 90%

## CI/CD Pipeline

The GitHub Actions pipeline includes:

1. **Code Quality**
   - SonarQube analysis
   - Test coverage checks
   - Code smell detection

2. **Build & Deploy**
   - Multi-architecture Docker builds
   - Security scanning
   - Kubernetes deployment
   - Health checks

3. **Testing**
   - Smoke tests
   - Load testing with k6
   - Performance validation

### Pipeline Triggers

- **Push to main**: Full deployment
- **Pull requests**: Code quality checks only
- **Manual**: Specific stage execution

## Troubleshooting

### Common Issues

1. **Pods Not Starting**
```bash
# Check pod status
kubectl get pods -n urlshortner -o wide

# Check pod logs
kubectl logs -f deployment/<service-name> -n urlshortner

# Describe pod for events
kubectl describe pod <pod-name> -n urlshortner
```

2. **High Memory Usage**
```bash
# Check resource usage
kubectl top pods -n urlshortner

# Check HPA status
kubectl describe hpa <service-name>-hpa -n urlshortner
```

3. **Ingress Issues**
```bash
# Check ingress status
kubectl get ingress -n urlshortner

# Check ingress controller logs
kubectl logs -f deployment/nginx-ingress-ingress-nginx-controller -n ingress-nginx
```

4. **Redis Connection Issues**
```bash
# Test Redis connection
kubectl exec -it deployment/redis -n urlshortner -- redis-cli ping

# Check Redis logs
kubectl logs -f deployment/redis -n urlshortner
```

### Performance Tuning

1. **Database Optimization**
   - Increase SQLite cache size
   - Add appropriate indexes
   - Monitor query performance

2. **Redis Optimization**
   - Adjust maxmemory policy
   - Monitor key expiration
   - Optimize data structures

3. **Application Optimization**
   - Adjust resource limits/requests
   - Tune HPA thresholds
   - Optimize container images

## Security Considerations

### Network Security
- All services run in private subnets
- Security groups restrict traffic
- Network policies implement zero-trust

### Application Security
- Secrets stored in Kubernetes Secrets
- Environment variables for configuration
- Rate limiting prevents abuse

### Infrastructure Security
- IAM roles follow least privilege
- EBS volumes encrypted
- Private EKS endpoints

## Cost Optimization

### Instance Strategy
- Mixed on-demand and spot instances
- Auto-scaling based on demand
- Right-sized resource allocations

### Storage Optimization
- EBS gp2 volumes for performance
- Lifecycle policies for backups
- Compression where possible

### Network Optimization
- Regional deployment reduces latency
- Data transfer monitoring
- CDN integration for static assets

## Maintenance

### Regular Tasks

1. **Weekly**
   - Review monitoring dashboards
   - Check resource utilization
   - Update container images

2. **Monthly**
   - Review and update dependencies
   - Backup configurations
   - Performance tuning

3. **Quarterly**
   - Capacity planning
   - Cost analysis
   - Security audit

### Backup Strategy

- **EBS Snapshots**: Daily automated snapshots
- **Configuration**: Git version control
- **Docker Images**: Multi-tag retention policy
- **Monitoring Data**: Prometheus retention policies

## Scaling Guidelines

### Vertical Scaling
- Increase resource limits for CPU/memory intensive services
- Monitor resource utilization before scaling
- Test performance impact

### Horizontal Scaling
- Adjust HPA min/max replicas
- Consider custom metrics for scaling
- Test scaling behavior under load

### Database Scaling
- For high write loads, consider external databases
- Implement read replicas for analytics
- Use connection pooling

## Support & Documentation

- **Architecture Diagram**: See `docs/architecture.md`
- **API Documentation**: Available in service README files
- **Terraform Documentation**: `terraform/README.md`
- **Kubernetes Manifests**: `k8s/README.md`

For additional support or questions, refer to the project documentation or create an issue in the repository.
