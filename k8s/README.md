# Kubernetes Manifests for URL Shortener Microservices

This directory contains all the Kubernetes manifests needed to deploy the URL shortener microservices application on EKS.

## Architecture

The deployment includes:

- **Redis**: Cache and message broker
- **Go Service**: URL shortening and redirection
- **Node.js Service**: Metadata enrichment
- **Python Service**: Analytics dashboard
- **Ingress**: NGINX Ingress Controller for external access
- **HPA**: Horizontal Pod Autoscalers for traffic spikes
- **ConfigMaps**: Application configuration
- **Secrets**: Sensitive data (passwords, API keys)

## Deployment Order

1. **Namespace**: Creates the urlshortner namespace
2. **Redis**: Cache and message broker (dependency for other services)
3. **Services**: Deploy all microservices
4. **Ingress**: External access configuration
5. **HPA**: Auto-scaling configuration

## Quick Start

```bash
# Apply all manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n urlshortner
kubectl get services -n urlshortner
kubectl get ingress -n urlshortner

# Check HPA status
kubectl get hpa -n urlshortner
```

## Configuration

### Environment Variables

Update the following in the deployment files:

- **Image names**: Replace `your-dockerhub-username` with your actual Docker Hub username
- **Resource limits**: Adjust based on your requirements
- **Replica counts**: Modify as needed

### Secrets

Before deploying, update the secrets:

```bash
# Edit k8s/secrets.yaml and replace the placeholder values under stringData.
# (Kubernetes will base64-encode them when stored.)
#
# NOTE: `REDIS_PASSWORD` is stored for assignment/demo, but the current services do not use Redis AUTH.
# Do not enable `requirepass` in Redis unless you also update the services to authenticate.
```

### Ingress Configuration

The ingress is configured for path-based routing so you can use the AWS LoadBalancer DNS name without Route53:

- `/` → Python service (dashboard + Python APIs like `/create`, `/api/stats`)
- `/api/shorten` → Go service
- `/api/metadata` → Node service
- `/r/<code>` → Go service redirects (Ingress rewrites `/r/<code>` to `/<code>`)

## Auto-scaling Configuration

The HPA is configured to:

- **Scale up**: 100% increase or up to 4 pods per minute
- **Scale down**: 10% decrease per minute
- **CPU threshold**: 70% utilization
- **Memory threshold**: 80% utilization
- **Min/Max replicas**: 
  - Go service: 2-10
  - Node.js service: 2-8
  - Python service: 2-8

## Monitoring

The deployment includes readiness and liveness probes for all services:

- **Liveness**: Restart unhealthy containers
- **Readiness**: Remove unhealthy pods from service endpoints

Note: `go-service` does not expose a dedicated `/health` endpoint, so it uses `tcpSocket` probes on port `8000`.

### HPA Metrics (Required)

HPAs require `metrics-server` to be installed in the cluster.

If you provision the cluster with the Terraform in `terraform/`, `metrics-server` is installed via Helm by default.

### Prometheus/Grafana

If you install `kube-prometheus-stack`, you can also apply `k8s/monitoring-servicemonitor.yaml` to scrape ingress-nginx controller metrics for dashboards.

## Storage

Each service uses persistent volumes:

- **Redis**: 5Gi for data persistence
- **Go Service**: 5Gi for SQLite database
- **Node.js Service**: 5Gi for SQLite database
- **Python Service**: 5Gi for SQLite database

## Traffic Spike Handling

The system is designed to handle traffic spikes at 12:00 PM:

1. **Redis caching**: Reduces database load
2. **HPA**: Automatically scales pods based on CPU/memory
3. **Load balancing**: Distributes traffic across pods
4. **Rate limiting**: Prevents abuse (100 requests/minute)

## Troubleshooting

```bash
# Check pod logs
kubectl logs -f deployment/go-service -n urlshortner
kubectl logs -f deployment/python-service -n urlshortner
kubectl logs -f deployment/node-service -n urlshortner
kubectl logs -f deployment/redis -n urlshortner

# Check events
kubectl get events -n urlshortner --sort-by=.metadata.creationTimestamp

# Describe resources
kubectl describe hpa go-service-hpa -n urlshortner
kubectl describe ingress urlshortner-ingress -n urlshortner
```

## Cleanup

```bash
# Delete all resources
kubectl delete -f k8s/

# Or delete namespace (removes everything)
kubectl delete namespace urlshortner
```
