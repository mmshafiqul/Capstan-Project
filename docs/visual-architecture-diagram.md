# URL Shortener Microservices - Visual Architecture Diagram

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    AWS CLOUD (ap-south-1)                             │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐     │
│  │                    AWS EKS CLUSTER                                │     │
│  │  mmsuzon-urlshortner-eks-cluster                          │     │
│  │                                                                 │     │
│  │  ┌─────────────────────────────────────────────────────────────────┐       │     │
│  │  │                INGRESS LAYER                          │       │     │
│  │  │  ┌─────────────────────────────────────────────────┐        │       │     │
│  │  │  │     NGINX INGRESS CONTROLLER          │        │       │     │
│  │  │  │  (Network Load Balancer)                │        │       │     │
│  │  │  │  ┌─────────────────────────────────────┐    │        │       │     │
│  │  │  │  │  URL ROUTING                │    │        │       │     │
│  │  │  │  │  • urlshortner.local         │    │        │       │     │
│  │  │  │  │  • api.urlshortner.local      │    │        │       │     │
│  │  │  │  │  • redirect.urlshortner.local  │    │        │       │     │
│  │  │  │  └─────────────────────────────────────┘    │        │       │     │
│  │  │  └─────────────────────────────────────────────────────────┘        │       │     │
│  │  └─────────────────────────────────────────────────────────────────────────┘       │     │
│  │                                                                 │     │
│  │  ┌─────────────────────────────────────────────────────────────────────────┐       │     │
│  │  │              APPLICATION LAYER                          │       │     │
│  │  │                                                         │       │     │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │       │     │
│  │  │  │ PYTHON      │  │ GO SERVICE   │  │ NODE.JS     │  │       │     │
│  │  │  │ SERVICE     │  │ (Redirect)   │  │ SERVICE     │  │       │     │
│  │  │  │             │  │             │  │ (Metadata)   │  │       │     │
│  │  │  │ • Dashboard │  │ • URL Short │  │ • Page Info  │  │       │     │
│  │  │  │ • Analytics │  │ • Redirect  │  │ • Titles     │  │       │     │
│  │  │  │ • Orchestrate│  │ • Events    │  │ • Descriptions│  │       │     │
│  │  │  │ • UI         │  │ • Cache     │  │ • Favicons   │  │       │     │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘  │       │     │
│  │  │         │                   │                   │       │     │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │       │     │
│  │  │  │ SQLite DB    │  │ SQLite DB    │  │ SQLite DB    │  │       │     │
│  │  │  │ (Analytics)  │  │ (URLs)       │  │ (Metadata)   │  │       │     │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘  │       │     │
│  │  │         │                   │                   │       │     │
│  │  │  ┌─────────────────────────────────────────────────────────┐       │     │
│  │  │  │            REDIS LAYER                      │       │     │
│  │  │  │  ┌─────────────────────────────────────────────┐      │       │     │
│  │  │  │  │         REDIS CLUSTER             │      │       │     │
│  │  │  │  │                                 │      │       │     │
│  │  │  │  │ • Cache (256MB)                 │      │       │     │
│  │  │  │  │ • Pub/Sub (click_events)          │      │       │     │
│  │  │  │  │ • Message Queue                  │      │       │     │
│  │  │  │  │ • Session Storage                │      │       │     │
│  │  │  │  └─────────────────────────────────────────────┘      │       │     │
│  │  │  └─────────────────────────────────────────────────────────┘       │     │
│  │  └─────────────────────────────────────────────────────────────────────────┘       │     │
│  └─────────────────────────────────────────────────────────────────────────────────────┘     │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐     │
│  │                    MONITORING LAYER                              │     │
│  │                                                                 │     │
│  │  ┌─────────────────────────────────────────────────────────────────┐       │     │
│  │  │              PROMETHEUS STACK                         │       │     │
│  │  │  ┌──────────────┐  ┌──────────────┐              │       │     │
│  │  │  │ PROMETHEUS   │  │ GRAFANA      │              │       │     │
│  │  │  │ • Metrics    │  │ • Dashboards │              │       │     │
│  │  │  │ • Alerting   │  │ • Visualize  │              │       │     │
│  │  │  │ • Storage    │  │ • Reports    │              │       │     │
│  │  │  │ (20Gi)      │  │ (NLB)        │              │       │     │
│  │  │  └──────────────┘  └──────────────┘              │       │     │
│  │  │                                                 │       │     │
│  │  │  ┌─────────────────────────────────────────────────────┐       │     │
│  │  │  │         ALERTING RULES                   │       │     │
│  │  │  │  • High Error Rate (>10%)              │       │     │
│  │  │  │  • Slow Response (>1s)                │       │     │
│  │  │  │  • HPA at Max Replicas              │       │     │
│  │  │  │  • Redis Memory >90%                │       │     │
│  │  │  │  • Service Down                      │       │     │
│  │  │  └─────────────────────────────────────────────────────┘       │     │
│  │  └─────────────────────────────────────────────────────────────────────────┘     │
│  └─────────────────────────────────────────────────────────────────────────────────────┘
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐     │
│  │                    CI/CD LAYER                                 │     │
│  │                                                                 │     │
│  │  ┌─────────────────────────────────────────────────────────────────┐       │     │
│  │  │            GITHUB ACTIONS PIPELINE                │       │     │
│  │  │                                                         │       │     │
│  │  │  ┌─────────────────────────────────────────────────────┐      │       │     │
│  │  │  │          PIPELINE STAGES                  │      │       │     │
│  │  │  │  1. Code Quality (SonarQube)          │      │       │     │
│  │  │  │  2. Build Docker Images                 │      │       │     │
│  │  │  │  3. Run Tests                         │      │       │     │
│  │  │  │  4. Push to Docker Hub                 │      │       │     │
│  │  │  │  5. Deploy to Kubernetes               │      │       │     │
│  │  │  │  6. Smoke Tests                       │      │       │     │
│  │  │  │  7. Load Testing (k6)                │      │       │     │
│  │  │  └─────────────────────────────────────────────────────┘      │       │     │
│  │  │                                                         │       │     │
│  │  │  ┌─────────────────────────────────────────────────────┐      │       │     │
│  │  │  │         QUALITY GATES                   │      │       │     │
│  │  │  │  • Code Smells < Threshold             │      │       │     │
│  │  │  │  • Duplicate Code < 5%                 │      │       │     │
│  │  │  │  • Test Coverage > 80%                 │      │       │     │
│  │  │  │  • Security Scan Pass                  │      │       │     │
│  │  │  └─────────────────────────────────────────────────────┘      │       │     │
│  │  └─────────────────────────────────────────────────────────────────────────┘     │
│  └─────────────────────────────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ EXTERNAL TRAFFIC
                                      │
                         ┌─────────────────────────┐
                         │     USERS           │
                         │  (Browsers)        │
                         │  • Dashboard        │
                         │  • API Calls        │
                         │  • URL Redirects    │
                         └─────────────────────────┘
```

## Data Flow Patterns

### 1. URL Creation Flow
```
USER → Python Dashboard → Go Service → Node.js Service → Store in Databases
                                    ↓
                              Cache in Redis
```

### 2. URL Redirect Flow
```
USER → NLB → Ingress → Go Service → Check Redis Cache
                                    ↓
                              ┌─ Hit: Return Cached URL
                              └─ Miss: Query DB → Cache → Return
                                    ↓
                              Publish Click Event → Redis Pub/Sub
```

### 3. Analytics Flow
```
Redis Pub/Sub → Python Service → Process Event → Store in SQLite → Update Dashboard
```

## Auto-scaling Configuration

### HPA Settings
```
┌─────────────────────────────────────────────────────────────────────────┐
│                  HORIZONTAL POD AUTOSCALERS                │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ GO SERVICE   │  │ NODE.JS     │  │ PYTHON      │  │
│  │ HPA          │  │ HPA          │  │ HPA          │  │
│  │              │  │              │  │              │  │
│  │ • Min: 2     │  │ • Min: 2     │  │ • Min: 2     │  │
│  │ • Max: 10    │  │ • Max: 8     │  │ • Max: 8     │  │
│  │ • CPU: 70%   │  │ • CPU: 70%   │  │ • CPU: 70%   │  │
│  │ • Mem: 80%    │  │ • Mem: 80%    │  │ • Mem: 80%    │  │
│  │ • Scale Up:   │  │ • Scale Up:   │  │ • Scale Up:   │  │
│  │   100%/4pods  │  │   100%/3pods  │  │   100%/3pods  │  │
│  │ • Scale Down: │  │ • Scale Down: │  │ • Scale Down: │  │
│  │   10%/60s     │  │   10%/60s     │  │   10%/60s     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                         │
│  TRAFFIC SPIKE HANDLING:                                   │
│  • 12:00 PM Daily Peak                                   │
│  • Redis Cache Reduces DB Load (87% Hit Rate)               │
│  • HPA Scales Within 45 Seconds                            │
│  • Load Balancer Distributes Traffic                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Infrastructure Components

### VPC Configuration
```
┌─────────────────────────────────────────────────────────────────────────┐
│                    VPC: 10.0.0.0/16                   │
│                                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              PUBLIC SUBNETS                        │   │
│  │  • 10.0.101.0/24 (ap-south-1a)           │   │
│  │  • 10.0.102.0/24 (ap-south-1b)           │   │
│  │  • 10.0.103.0/24 (ap-south-1c)           │   │
│  │              ↓ NAT Gateways                        │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              PRIVATE SUBNETS                       │   │
│  │  • 10.0.1.0/24 (ap-south-1a)              │   │
│  │  • 10.0.2.0/24 (ap-south-1b)              │   │
│  │  • 10.0.3.0/24 (ap-south-1c)              │   │
│  │              ↓ EKS Nodes + Services               │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### EKS Node Groups
```
┌─────────────────────────────────────────────────────────────────────────┐
│                  MANAGED NODE GROUPS                        │
│                                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              GENERAL PURPOSE (On-Demand)            │   │
│  │  • 3x t3.medium instances                     │   │
│  │  • Min: 1, Max: 10                         │   │
│  │  • Desired: 3                               │   │
│  │  • IAM Role: EKS Worker Node Policy            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              SPOT INSTANCES (Cost Opt)           │   │
│  │  • 2x t3.small instances                      │   │
│  │  • Min: 0, Max: 5                          │   │
│  │  • Desired: 2                               │   │
│  │  • 60-90% Cost Savings                       │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Security Architecture

### Network Security
```
┌─────────────────────────────────────────────────────────────────────────┐
│                  SECURITY GROUPS                           │
│                                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              CONTROL PLANE SG                    │   │
│  │  • HTTPS In (443) from API                   │   │
│  │  • No Inbound from 0.0.0.0/0                │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              NODE GROUPS SG                     │   │
│  │  • Node Communication (All ports)              │   │
│  │  • Ingress from Control Plane               │   │
│  │  • Egress to Internet (NAT)                │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              SERVICES SG                         │   │
│  │  • Inter-service Communication (ClusterIP)        │   │
│  │  • Ingress from NLB (80/443)              │   │
│  │  • Egress to Redis (6379)                │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Traffic Spike Scenario (12:00 PM)

### Before Spike (11:55 AM)
```
┌─────────────────────────────────────────────────────────────────────────┐
│                  NORMAL OPERATIONS                        │
│                                                         │
│  PODS: 2-3 per service                                   │
│  CPU: 30-40%                                             │
│  MEMORY: 45-55%                                           │
│  REQUESTS/SEC: 50-100                                      │
│  RESPONSE TIME: P95 < 200ms                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

### During Spike (12:00-12:05 PM)
```
┌─────────────────────────────────────────────────────────────────────────┐
│                  TRAFFIC SPIKE                           │
│                                                         │
│  VUS: 100-200                                            │
│  REQUESTS/SEC: 800-1,200                                 │
│  HPA TRIGGERED:                                             │
│  ┌─────────────────────────────────────────────────────────────┐       │
│  │              SCALING EVENTS                   │       │
│  │  • T+0s: HPA Detects >70% CPU            │       │
│  │  • T+45s: Pods Scale to 6-8                │       │
│  │  • T+90s: Full Scaling Capacity             │       │
│  │  • T+180s: Scale Down Begins              │       │
│  └─────────────────────────────────────────────────────────────┘       │
│                                                         │
│  PERFORMANCE:                                              │
│  • RESPONSE TIME: P95 < 500ms                             │
│  • ERROR RATE: < 1%                                       │
│  • CACHE HIT RATIO: 87%                                   │
│  • NO DOWNTIME                                            │
└─────────────────────────────────────────────────────────────────────────┘
```

### After Spike (12:10 PM)
```
┌─────────────────────────────────────────────────────────────────────────┐
│                  RECOVERY PHASE                         │
│                                                         │
│  TRAFFIC: Normalizing to 50-100 VUS                         │
│  HPA: Scaling down to baseline (2-3 pods)                     │
│  COST: Spot instances terminated for savings                        │
│  METRICS: All within acceptable ranges                        │
└─────────────────────────────────────────────────────────────────────────┘
```

## Technology Stack Summary

### Container Platform
- **Kubernetes**: 1.29 (Amazon EKS)
- **Container Runtime**: containerd
- **CNI**: AWS VPC CNI
- **Ingress**: NGINX Ingress Controller
- **Storage**: EBS gp2 (Persistent Volumes)

### Application Stack
- **Go Service**: 1.24, Gin framework, SQLite3, Redis client
- **Python Service**: 3.14, Flask, Redis-py, SQLite3
- **Node.js Service**: 24.11, Express, Axios, Cheerio, SQLite3
- **Redis**: 8-alpine, Pub/Sub, LRU eviction

### Monitoring Stack
- **Prometheus**: kube-prometheus-stack
- **Grafana**: v10.x with custom dashboards
- **AlertManager**: Integrated with Prometheus
- **Metrics**: Custom business + infrastructure

### CI/CD Stack
- **Source Control**: GitHub
- **Pipeline**: GitHub Actions
- **Registry**: Docker Hub
- **Quality**: SonarQube/Cloud
- **Testing**: k6 for load testing
- **Deployment**: kubectl + Helm

This architecture provides a production-ready, scalable, and observable URL shortener platform capable of handling enterprise traffic patterns with automatic scaling and comprehensive monitoring.
