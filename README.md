# Falco Eye


The project demonstrates a **runtime security monitoring setup** using **Falco** for Kubernetes real-time threat detection, integrated with **Prometheus** and **Grafana** for observability and alerting. This setup provides real-time security event detection, metrics collection, and alerting capabilities for your Kubernetes cluster.

This architecture leverages **Falco's kernel-level monitoring** to detect suspicious activities, with **Falcosidekick** routing security events, **Prometheus** collecting metrics, and **Alertmanager** sending notifications to external systems like Slack.

<br>

<div align="center">
  <img src="https://raw.githubusercontent.com/JunedConnect/project-kubernetes-falco/main/images/falco-logo.png" width="300" alt="Falco Logo">
</div>

<br>

## Key Features

- **Falco** - Runtime security monitoring with kernel-level event detection
- **Falcosidekick** - Alert routing and web ui for Falco events
- **Event Generator** - Security event simulation for testing Falco rules
- **Prometheus** - Metrics collection, storage, and querying
- **Grafana** - Visualisation dashboards for Falco
- **Alertmanager** - Alert routing and notification management with Slack integration

<br>

## Directory Structure

```
./
├── helm-values/              # Helm chart values for all components
│   ├── falco-values.yml      # Falco configuration
│   ├── prom-graf-values.yml  # Prometheus Stack configuration
│   └── event-generator-values.yml  # Event Generator configuration
├── kind-conf.yaml            # Kind cluster configuration
├── Makefile                  # Automation commands
└── README.md                 # This file
```

<br>

## Configuration Dependencies

Before deploying, update these configuration values:

**Alertmanager Slack Integration** (`helm-values/prom-graf-values.yml`):
- Slack webhook URL - Update `slack_api_url` with your Slack webhook URL
- Slack channel - Update `channel` with your desired Slack channel name

<br>

## How to Deploy

**Prerequisites**:
- **Kind** - For creating local Kubernetes clusters
- **kubectl** - Kubernetes command-line tool
- **Helm** - Package manager for Kubernetes

1. Update configuration values in `helm-values` directory (see Configuration Dependencies above)

2. Run the below command in order to create the Kind cluster and deploy all components:
   ```bash
   make setup
   ```

3. Start port-forwards to access services locally:
   ```bash
   make portforward
   ```

4. Access the services:
   - **Prometheus**: http://localhost:9090
   - **Grafana**: http://localhost:8080
   - **Alertmanager**: http://localhost:9093
   - **Falco Sidekick UI**: http://localhost:2802

<br>

## Configuration

### Alert Routing

This setup is configured to have **Prometheus send alerts to Alertmanager**. Falco metrics are scraped by Prometheus via ServiceMonitor, and Prometheus evaluates PrometheusRules to generate alerts.

**Alternative: Direct Falcosidekick to Alertmanager**

To configure Falcosidekick to send alerts directly to Alertmanager (bypassing Prometheus), update `helm-values/falco-values.yml`:

```yaml
falcosidekick:
  enabled: true
  config:
    alertmanager:
      hostport: "http://prom-graf-kube-prometheus-alertmanager.monitor:9093"
      endpoint: "/api/v2/alerts"

  prometheusRules:
    enabled: false  # Disable PrometheusRules to avoid duplicate alerts
```

Then upgrade:
   ```bash
   make upgrade-falco
   ```
   
<br>

### Accessing Services

Once port-forwards are active:
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:8080
  - Username: `admin`
  - Password: Retrieve from secret and decode from base64:
    ```bash
    kubectl get secret -n monitor prom-graf-grafana -o jsonpath="{.data.admin-password}" | base64 -d
    ```
- **Alertmanager**: http://localhost:9093
- **Falco Sidekick UI**: http://localhost:2802

<br>

## Cleanup

Remove all components and Kind cluster:
```bash
make destroy
```
