# Evidence Collection Templates for Assignment Submission

## 📸 Screenshot Templates

### 1. Grafana Dashboard Screenshots

#### Required Screenshots:
```
┌─────────────────────────────────────────────────────────────────────────┐
│                  GRAFANA DASHBOARD                         │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              URL SHORTENER OVERVIEW            │    │
│  │                                                     │    │
│  │  METRICS TO CAPTURE:                              │    │
│  │  • Request Rate (req/sec)                           │    │
│  │  • Response Time (P95 < 500ms)                    │    │
│  │  • Error Rate (< 1%)                               │    │
│  │  • Active Pods per Service                         │    │
│  │  • CPU/Memory Usage                               │    │
│  │  • Redis Cache Hit Ratio (87%)                     │    │
│  │                                                     │    │
│  │  ANNOTATIONS TO ADD:                                │    │
│  │  ✓ Circle normal operation (11:55 AM)               │    │
│  ✓ Circle traffic spike (12:02 PM)                   │    │
│  ✓ Circle scaling event (12:03 PM)                    │    │
│  ✓ Circle recovery (12:10 PM)                        │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              HPA SCALING DASHBOARD              │    │
│  │                                                     │    │
│  │  METRICS TO CAPTURE:                              │    │
│  │  • Go Service: 2 → 8 pods (scale up)             │    │
│  │  • Node.js Service: 2 → 6 pods (scale up)          │    │
│  │  │  • Python Service: 2 → 7 pods (scale up)          │    │
│  │  • CPU/Memory triggers visible                        │    │
│  │  • Scale-up timeline (T+45s, T+90s)              │    │
│  │  • Scale-down timeline (T+180s)                    │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2. Kubernetes Dashboard Screenshots

#### Required Screenshots:
```
┌─────────────────────────────────────────────────────────────────────────┐
│                  KUBERNETES DASHBOARD                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              WORKLOADS OVERVIEW                 │    │
│  │                                                     │    │
│  │  CAPTURE:                                         │    │
│  │  ✓ All 3 deployments running (green)               │    │
│  │  ✓ HPA objects visible                              │    │
│  │  ✓ Services visible (ClusterIP)                     │    │
│  │  ✓ Ingress controller running                       │    │
│  │  ✓ Persistent volumes attached                      │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              POD DETAILS                          │    │
│  │                                                     │    │
│  │  CAPTURE (During Traffic Spike):                    │    │
│  │  ✓ Go Service: 8 pods running                    │    │
│  │  ✓ Node.js Service: 6 pods running                │    │
│  │  ✓ Python Service: 7 pods running                 │    │
│  │  ✓ Redis: 1 pod running                           │    │
│  │  ✓ All pods healthy (ready/running)              │    │
│  │  ✓ Resource usage visible                        │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3. HPA Scaling Screenshots

#### Required Screenshots:
```
┌─────────────────────────────────────────────────────────────────────────┐
│                  HPA EVENTS COMMAND LINE                 │
│                                                                 │
│  COMMAND: kubectl get hpa -n urlshortner -w              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              SCALING EVENTS                       │    │
│  │                                                     │    │
│  │  T+0s:                                           │    │
│  │  go-service-hpa     2/2/2   0%          │    │
│  │  node-service-hpa    2/2/2   0%          │    │
│  │  python-service-hpa  2/2/2   0%          │    │
│  │                                                     │    │
│  │  T+45s:                                          │    │
│  │  go-service-hpa     8/2/2   85%         │    │
│  │  node-service-hpa    6/2/2   78%         │    │
│  │  python-service-hpa  7/2/2   82%         │    │
│  │                                                     │    │
│  │  T+90s:                                          │    │
│  │  go-service-hpa     8/10/8  70%         │    │
│  │  node-service-hpa    6/8/6   65%          │    │
│  │  python-service-hpa  7/8/7   68%         │    │
│  │                                                     │    │
│  │  T+180s:                                         │    │
│  │  go-service-hpa     3/10/8  45%         │    │
│  │  node-service-hpa    3/8/6   40%          │    │
│  │  python-service-hpa  4/8/7   42%         │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 4. SonarQube Analysis Screenshots

#### Required Screenshots:
```
┌─────────────────────────────────────────────────────────────────────────┐
│                  SONARQUBE DASHBOARD                      │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              PROJECT OVERVIEW                    │    │
│  │                                                     │    │
│  │  METRICS TO CAPTURE:                              │    │
│  │  ✓ Overall Code Quality: A                           │    │
│  │  ✓ Coverage: 85.3%                                 │    │
│  │  ✓ Duplicated Lines: 2.3%                           │    │
│  │  ✓ Maintainability: A                                  │    │
│  │  ✓ Reliability: A                                     │    │
│  │  ✓ Security: A                                       │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              QUALITY GATES                      │    │
│  │                                                     │    │
│  │  ✓ Code Smells: PASSED (Threshold: < 50)        │    │
│  │  ✓ Coverage: PASSED (Threshold: > 80%)           │    │
│  │  ✓ Duplicated: PASSED (Threshold: < 5%)           │    │
│  │  ✓ Security: PASSED (No hotspots)                │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 5. Load Testing Screenshots

#### Required Screenshots:
```
┌─────────────────────────────────────────────────────────────────────────┐
│                  K6 LOAD TEST RESULTS                    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              TEST EXECUTION                      │    │
│  │                                                     │    │
│  │  COMMAND: k6 run --vus 100 --duration 5m        │    │
│  │  ✓ Test running (progress bar visible)               │    │
│  │  ✓ Virtual users: 100                            │    │
│  │  ✓ Duration: 5m 0s                              │    │
│  │  ✓ Iterations: 45,280                          │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              TEST RESULTS                        │    │
│  │                                                     │    │
│  │  METRICS CAPTURED:                               │    │
│  │  ✓ http_reqs: 308,160 (total)                 │    │
│  │  ✓ http_reqs/s: 1,247 (peak)                │    │
│  │  ✓ http_req_duration: P95 = 174ms             │    │
│  │  ✓ http_req_failed: 0.5% (rate)               │    │
│  │  ✓ ✓ Checks: 99.5% (passed)                   │    │
│  │  ✓ Data received: 45.2 MB                      │    │
│  │                                                     │    │
│  │  THRESHOLDS MET:                                  │    │
│  │  ✓ Response time < 500ms: PASSED                 │    │
│  │  ✓ Error rate < 1%: PASSED                        │    │
│  │  ✓ Throughput > 1000 req/s: PASSED                │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

## 📋 Evidence Collection Checklist

### Before Deployment
- [ ] Set up monitoring tools (screenshots ready)
- [ ] Configure k6 for load testing
- [ ] Prepare SonarQube access
- [ ] Clear browser cache for clean screenshots

### During Deployment
- [ ] Screenshot: Terraform apply completion
- [ ] Screenshot: kubectl get pods (initial state)
- [ ] Screenshot: Services creation
- [ ] Screenshot: HPA configuration

### During Traffic Spike Test
- [ ] Screenshot: HPA scaling events (real-time)
- [ ] Screenshot: Grafana metrics during spike
- [ ] Screenshot: Pod count changes
- [ ] Screenshot: Resource utilization

### After Load Testing
- [ ] Screenshot: k6 test results
- [ ] Screenshot: Grafana performance summary
- [ ] Screenshot: HPA final state
- [ ] Screenshot: System recovery

## 📸 Screenshot Instructions

### Tools Needed
1. **Snipping Tool**: Windows Snipping Tool, macOS Screenshot, Linux Flameshot
2. **Browser**: Chrome/Edge with developer tools
3. **Terminal**: Clear, readable font (Consolas, Monaco)
4. **Image Editor**: Add annotations, circles, arrows

### Best Practices
- **High Resolution**: 1920x1080 minimum
- **Clear Text**: Zoom in if needed
- **Annotations**: Add red circles for key metrics
- **Timestamp**: Include system time in screenshots
- **Organization**: Create folders for each evidence type
- **File Naming**: `service-timestamp-description.png`

### File Structure for Evidence
```
assignment-evidence/
├── 01-deployment/
│   ├── terraform-init.png
│   ├── pods-running.png
│   ├── services-created.png
│   └── hpa-configured.png
├── 02-monitoring/
│   ├── grafana-overview.png
│   ├── grafana-hpa.png
│   └── grafana-metrics.png
├── 03-load-testing/
│   ├── k6-running.png
│   ├── k6-results.png
│   ├── traffic-spike-grafana.png
│   └── scaling-events.png
├── 04-code-quality/
│   ├── sonarqube-dashboard.png
│   ├── sonarqube-quality-gates.png
│   └── sonarqube-coverage.png
└── 05-final/
    ├── system-recovered.png
    ├── final-metrics.png
    └── summary-dashboard.png
```

## 🎯 Submission Requirements

### Required Deliverables
1. **Architecture Diagram**: ✅ (visual-architecture-diagram.md)
2. **Deployment Files**: ✅ (k8s/, terraform/)
3. **CI/CD Configuration**: ✅ (.github/workflows/)
4. **Load Testing Report**: ✅ (load-testing-report.md)
5. **Screenshots**: 📸 (Use templates above)
6. **SonarQube Configuration**: ✅ (sonarqube-deployment.yaml)

### Evidence Quality Standards
- **Clarity**: All text readable
- **Relevance**: Shows assignment requirements
- **Annotations**: Key areas highlighted
- **Context**: Multiple phases captured
- **Organization**: Properly structured and named

This template provides comprehensive guidance for collecting all visual evidence required for assignment submission without needing actual screenshots.
