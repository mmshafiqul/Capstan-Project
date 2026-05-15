# Monitoring (Prometheus + Grafana)

This folder contains artifacts used by the monitoring stack:

- `prometheus-rules.yaml`: example alerting rules for the URL shortener
- `grafana-dashboards/dashboard.json`: example dashboard JSON export

## Deploy (recommended via Helm)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

## Import artifacts

```bash
# Apply custom Prometheus rules (if you enabled rule selectors appropriately)
kubectl apply -n monitoring -f monitoring/prometheus-rules.yaml
```

For Grafana, import `monitoring/grafana-dashboards/dashboard.json` in the Grafana UI (Dashboards -> Import).
