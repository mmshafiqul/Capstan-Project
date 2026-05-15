# URL Shortener Microservices Architecture

## Overview

This document describes the architecture of the URL Shortener Microservices platform deployed on AWS EKS, designed to handle high traffic spikes with auto-scaling capabilities.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    AWS Cloud                                   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                            AWS EKS Cluster                             │   │
│  │                                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐    │   │
│  │  │                    Ingress Controller                          │    │   │
│  │  │                  (NGINX + NLB)                                │    │   │
│  │  └─────────────────────────────────────────────────────────────────┘    │   │
│  │                               │                                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │   │
│  │  │ Python       │  │ Go Service   │  │ Node.js      │  │ Redis      │ │   │
│  │  │ Service      │  │ (Redirect)  │  │ Service      │  │ (Cache &   │ │   │
│  │  │ (Dashboard)  │  │              │  │ (Metadata)   │  │ Message)   │ │   │
│  │  │              │  │              │  │              │  │            │ │   │
│  │  │ - Analytics  │  │ - URL Short │  │ - Page Info  │  │ - Cache    │ │   │
│  │  │ - UI         │  │ - Redirect  │  │ - Titles     │  │ - Pub/Sub  │ │   │
│  │  │ - Orchestrate│  │ - Events    │  │ - Descriptions│  │            │ │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘ │   │
│  │         │                 │                 │                 │        │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │   │
│  │  │ SQLite DB    │  │ SQLite DB    │  │ SQLite DB    │  │ Persistent │ │   │
│  │  │ (Analytics)  │  │ (URLs)       │  │ (Metadata)   │  │ Volume     │ │   │
│  │  └──────────────┘  ┌──────────────┘  └──────────────┘  └────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                      Monitoring Stack                                  │   │
│  │                                                                         │   │
│  │  ┌──────────────┐           ┌──────────────┐                          │   │
│  │  │ Prometheus   │◄─────────►│ Grafana      │                          │   │
│  │  │ (Metrics)    │           │ (Dashboard)  │                          │   │
│  │  └──────────────┘           └──────────────┘                          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ External Traffic
                                      ▼
                              ┌──────────────┐
                              │ Users        │
                              │ (Browsers)   │
                              └──────────────┘
```

## Component Details

### 1. Infrastructure Layer

**AWS EKS Cluster**
- Kubernetes 1.29 with managed node groups
- Mixed instance strategy (on-demand + spot)
- Auto-scaling node groups
- Private subnets across 3 AZs

**VPC Configuration**
- 10.0.0.0/16 CIDR block
- 3 public and 3 private subnets
- NAT gateways for internet access
- Security groups for service isolation

### 2. Application Layer

**Python Service (Analytics & Dashboard)**
- Port: 5000
- Replicas: 2-8 (auto-scaling)
- Database: SQLite (analytics.db)
- Responsibilities:
  - Web dashboard UI
  - URL creation orchestration
  - Analytics and reporting
  - Redis event subscription

**Go Service (URL Shortening & Redirect)**
- Port: 8000
- Replicas: 2-10 (auto-scaling)
- Database: SQLite (urls.db)
- Responsibilities:
  - URL shortening algorithm
  - Fast redirects
  - Click event publishing
  - Redis caching

**Node.js Service (Metadata Enrichment)**
- Port: 3000
- Replicas: 2-8 (auto-scaling)
- Database: SQLite (metadata.db)
- Responsibilities:
  - Page title extraction
  - Meta descriptions
  - Favicon retrieval
  - HTML parsing

**Redis (Cache & Message Broker)**
- Port: 6379
- Replicas: 1 (with persistence)
- Memory: 256MB max
- Responsibilities:
  - URL cache for fast lookups
  - Pub/Sub for click events
  - Session storage
  - Rate limiting

### 3. Ingress Layer

**NGINX Ingress Controller**
- Type: Network Load Balancer (NLB)
- SSL termination
- Rate limiting (100 req/min)
- Sticky sessions for dashboard
- Health checks

**Routing Rules**
- `urlshortner.local` → Python Service (dashboard)
- `api.urlshortner.local` → Go/Node Services (API)
- `redirect.urlshortner.local` → Go Service (redirects)

### 4. Auto-scaling Configuration

**Horizontal Pod Autoscalers (HPA)**
- CPU threshold: 70%
- Memory threshold: 80%
- Scale up: 100% or 4 pods/min
- Scale down: 10% per minute
- Stabilization windows: 60s (up), 300s (down)

**Traffic Spike Handling**
- Redis caching reduces database load
- HPA automatically scales during 12:00 PM spike
- Load balancer distributes traffic
- Circuit breakers prevent cascading failures

### 5. Monitoring & Observability

**Prometheus**
- Metrics collection from all services
- Custom business metrics
- Resource utilization tracking
- Alerting rules

**Grafana**
- Real-time dashboards
- Historical analytics
- Performance visualization
- Alert notifications

**Key Metrics**
- Request rate and response times
- Error rates and status codes
- Pod resource usage
- HPA scaling events
- Redis operations

## Data Flow

### URL Creation Flow
```
User → Dashboard (Python) → Go Service (Create URL) → Node.js (Metadata)
                                    ↓
                              Store in SQLite
                                    ↓
                              Cache in Redis
```

### Redirect Flow
```
User → NLB → Ingress → Go Service
                     ↓
              Check Redis Cache
                     ↓
          ┌─ Hit: Return cached URL
          │
          └─ Miss: Query SQLite → Cache → Return
                     ↓
              Publish Click Event
                     ↓
              Redis Pub/Sub → Python Service
```

### Analytics Flow
```
Click Events → Redis Pub/Sub → Python Service
                                    ↓
                              Store in SQLite
                                    ↓
                              Aggregate Data
                                    ↓
                              Dashboard Display
```

## Security Considerations

### Network Security
- Private EKS endpoints
- Security group isolation
- Network policies
- VPC flow logs

### Application Security
- Environment variables for secrets
- Redis authentication
- Rate limiting
- Input validation

### Infrastructure Security
- IAM roles with least privilege
- Encrypted EBS volumes
- Private subnets for workloads
- WAF integration (optional)

## Performance Optimizations

### Caching Strategy
- Redis LRU eviction policy
- URL cache with TTL
- Session caching
- Metadata caching

### Database Optimization
- SQLite with WAL mode
- Connection pooling
- Query optimization
- Indexing strategy

### Resource Management
- Resource requests/limits
- Pod affinity/anti-affinity
- Node selectors
- Priority classes

## Disaster Recovery

### High Availability
- Multi-AZ deployment
- Pod anti-affinity
- Auto-recovery mechanisms
- Health checks

### Data Persistence
- EBS persistent volumes
- Redis AOF persistence
- Regular backups
- Point-in-time recovery

### Monitoring & Alerting
- Prometheus alerting
- Grafana notifications
- Slack integration
- Email alerts

## Cost Optimization

### Infrastructure
- Spot instances for cost savings
- Auto-scaling to match demand
- Right-sized instances
- Reserved instances (optional)

### Storage
- EBS gp2 volumes
- Lifecycle policies
- Compression
- Cleanup policies

### Network
- Data transfer optimization
- CDN integration (optional)
- Regional deployment
- Traffic compression

## Deployment Strategy

### CI/CD Pipeline
1. Code quality checks (SonarQube)
2. Automated testing
3. Docker image building
4. Security scanning
5. Kubernetes deployment
6. Smoke testing
7. Load testing

### Rollout Strategy
- Blue-green deployment
- Rolling updates
- Health checks
- Automatic rollback

### Environment Management
- Development/Staging/Production
- Configuration management
- Secrets management
- Environment isolation

This architecture ensures high availability, scalability, and observability for the URL shortener microservices platform, capable of handling traffic spikes while maintaining optimal performance.
