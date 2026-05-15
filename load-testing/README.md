# Load Testing (k6)

`k6-load-test.js` simulates a daily traffic spike (12:00 PM scenario) by ramping VUs up and down.

## Run locally

```bash
k6 run load-testing/k6-load-test.js
```

## Run against EKS Ingress

1) Get the NGINX Ingress load balancer hostname/IP.
2) Run k6 with env overrides.

Example (port-forward Python service):

```bash
kubectl -n urlshortner port-forward svc/python-service 5000:5000
k6 run load-testing/k6-load-test.js
```

Example (AWS LoadBalancer DNS):

```bash
BASE_URL="http://<AWS_LB_DNS>" API_BASE_URL="http://<AWS_LB_DNS>" k6 run load-testing/k6-load-test.js
```
