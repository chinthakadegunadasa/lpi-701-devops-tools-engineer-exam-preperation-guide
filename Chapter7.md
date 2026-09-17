# Chapter 7: Metrics Collection & Visualization with Prometheus & Grafana

This chapter provides a practical, enterprise-grade guide to telemetry, metrics aggregation, time-series querying, and visual dashboards using Prometheus and Grafana. It covers the pull-based metrics model, Exporter deployment, PromQL querying, Alertmanager routing, and Grafana dashboard-as-code automation.


---

## 1. Prometheus Architecture & Core Fundamentals

Prometheus is an open-source systems monitoring and alerting toolkit built around a multidimensional data model, pull-based scraping over HTTP, and a time-series database (TSDB).
![Metrics Endpoint](lpi-ex701-ch7-Metrics-Endpoint.jpeg)

### 1.1 Data Model & Metric Types

Prometheus stores time series data identified by a metric name and key-value pairs (labels).

* **Counter:** A cumulative metric that only increases or resets to zero on restart (e.g., `http_requests_total`).
* **Gauge:** A metric that can arbitrarily go up and down (e.g., `node_memory_Active_bytes`, CPU temperature).
* **Histogram:** Samples observations (usually durations or response sizes) and counts them in configurable buckets.
* **Summary:** Calculates configurable quantiles over a sliding time window on the client side.

---

## 2. Deploying and Configuring Prometheus

Prometheus uses a declarative YAML file to manage global settings, scraping targets, alerting rules, and service discovery integrations.

### 2.1 Configuration File (`/etc/prometheus/prometheus.yml`)

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  scrape_timeout: 10s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 'localhost:9093'

rule_files:
  - '/etc/prometheus/rules/*.yml'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['192.168.10.11:9100', '192.168.10.12:9100']
        labels:
          environment: 'production'
          tier: 'frontend'

  - job_name: 'dynamic_file_sd'
    file_sd_configs:
      - files:
          - '/etc/prometheus/targets/*.json'
        refresh_interval: 5m

```

### 2.2 Systemd Unit File Setup

Create `/etc/systemd/system/prometheus.service`:

```ini
[Unit]
Description=Prometheus Time Series Collection and Processing Server
Wants=network-online.target
After=network-online.target

[ExecStart]
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --storage.tsdb.retention.time=30d \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target

```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus

```

Reload configuration without restarting the process:

```bash
curl -X POST http://localhost:9090/-/reload

```

---

## 3. Metrics Exporters: Node Exporter Installation

Exporters run alongside targets to extract host-level, runtime, or service metrics and expose them via HTTP endpoints formatted for Prometheus.

### 3.1 Node Exporter Setup

Download, extract, and configure `node_exporter` to track kernel and hardware statistics:

```bash
# Download and install Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xvf node_exporter-1.6.1.linux-amd64.tar.gz
sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/

# Create system user
sudo useradd --no-create-home --shell /bin/false node_exporter

```

Create systemd service `/etc/systemd/system/node_exporter.service`:

```ini
[Unit]
Description=Node Exporter Metrics Collector
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --collector.systemd \
  --collector.processes

[Install]
WantedBy=multi-user.target

```

Start the collector and verify output:

```bash
sudo systemctl enable --now node_exporter
curl -s http://localhost:9100/metrics | grep node_cpu_seconds_total

```

---

## 4. PromQL (Prometheus Query Language) Deep Dive

PromQL enables instant time-series querying, aggregation, rate calculations, and subqueries.

### 4.1 Common PromQL Queries

* **Calculate Per-Second Rate of HTTP Errors:**
```promql
rate(http_requests_total{status=~"5.."}[5m])

```


* **Overall CPU Usage Percentage across Nodes:**
```promql
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

```


* **Percentage of Used Memory:**
```promql
((node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes) * 100

```


* **Disk Space Usage Threshold (90% Limit Detection):**
```promql
(node_filesystem_size_bytes{fstype!~"tmpfs|overlay"} - node_filesystem_free_bytes{fstype!~"tmpfs|overlay"}) 
/ node_filesystem_size_bytes{fstype!~"tmpfs|overlay"} * 100 > 90

```


* **Predicting Disk Space Running Out in 4 Hours:**
```promql
predict_linear(node_filesystem_free_bytes{mountpoint="/"}[1h], 4 * 3600) < 0

```



---

## 5. Alert Rule Definition & Alertmanager Integration

Prometheus evaluates alerting rules and pushes active alerts to an Alertmanager instance for deduplication, grouping, and notification routing.

### 5.1 Prometheus Alert Rules (`/etc/prometheus/rules/host_alerts.yml`)

```yaml
groups:
  - name: host_monitoring_alerts
    rules:
      - alert: HighNodeCpuLoad
        expr: (100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU load detected on {{ $labels.instance }}"
          description: "CPU load is at {{ $value | printf \"%.2f\" }}% for over 5 minutes."

      - alert: ServiceDown
        expr: up == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Target instance down: {{ $labels.instance }}"
          description: "Prometheus failed to scrape endpoint {{ $labels.instance }} for job {{ $labels.job }}."

```

### 5.2 Alertmanager Configuration (`/etc/alertmanager/alertmanager.yml`)

```yaml
global:
  resolve_timeout: 5m

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'slack-notifications'

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/T000/B000/XXXXXX'
        channel: '#ops-alerts'
        send_resolved: true
        text: "Summary: {{ .CommonAnnotations.summary }}\nDescription: {{ .CommonAnnotations.description }}"

```

---

## 6. Visualization with Grafana

Grafana converts Prometheus time-series data into interactive, real-time visual dashboards.

### 6.1 Configuring Prometheus Data Source via Code (`/etc/grafana/provisioning/datasources/prometheus.yml`)

```yaml
apiVersion: 1

datasources:
  - name: Prometheus-Production
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    jsonData:
      httpMethod: POST
      timeInterval: 15s
    editable: false

```

### 6.2 Declarative Dashboard Provisioning (`/etc/grafana/provisioning/dashboards/dashboards.yml`)

```yaml
apiVersion: 1

providers:
  - name: 'System Performance Dashboards'
    orgId: 1
    folder: 'Infrastructure'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards

```

### 6.3 Sample Grafana Panel JSON Definition (CPU Metric Panel)

Save as `/var/lib/grafana/dashboards/node_overview.json`:

```json
{
  "annotations": {
    "list": []
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": 1,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "type": "timeseries",
      "title": "CPU Usage (%)",
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "id": 1,
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "Prometheus-Production"
          },
          "editorMode": "code",
          "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
          "legendFormat": "{{instance}}",
          "range": true,
          "refId": "A"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "custom": {
            "drawStyle": "line",
            "lineInterpolation": "smooth"
          },
          "unit": "percent"
        }
      }
    }
  ],
  "refresh": "10s",
  "schemaVersion": 38,
  "style": "dark",
  "tags": ["infrastructure", "node-exporter"],
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "title": "Node Health Overview"
}

```

---

## 7. Verification & Troubleshooting Workflows

Use these operational commands to audit Prometheus TSDB integrity, check scrapers, and validate syntax:

```bash
# Validate Prometheus configuration file syntax
promtool check config /etc/prometheus/prometheus.yml

# Validate alert rules configuration
promtool check rules /etc/prometheus/rules/host_alerts.yml

# Query endpoint status via Prometheus API
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .discoveredLabels.job, status: .health, lastError: .lastError}'

# Query TSDB block details and stats
promtool tsdb analyze /var/lib/prometheus/

```
