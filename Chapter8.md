# Chapter 8: Objective 705.2 Log Management & Analysis

In a modern cloud-native architecture, distributed systems generate high-volume, heterogeneous log streams across containers, microservices, and underlying infrastructure. Objective 705.2 of the LPI 701-200 exam validates your ability to design, configure, and maintain unified log aggregation, processing pipelines, and index management using modern open-source solutions: **Vector**, **Fluentd**, **Elasticsearch**, **OpenSearch**, and **Kibana/OpenSearch Dashboards**.

---

## 1. Architectural Overview & Toolchain Comparison

Log management relies on a decoupled, three-stage architecture: **Collection & Forwarding**, **Log Ingestion & Indexing**, and **Visualization**.

![Log-Management-Architecture](img/pi-ex701-ch8-Log-Management-Architecture.jpeg)

| Component | Modern Open-Source Tool | Legacy / Enterprise Alternative | Primary Role in Pipeline |
| --- | --- | --- | --- |
| **Agent / Forwarder** | **Vector** (Rust-based, high throughput) | **Fluentd / Logstash** | Scrapes, parses, enriches, and forwards logs with low overhead. |
| **Indexing Engine** | **OpenSearch** | **Elasticsearch** (SSPL) | Distributed document store, indexer, and search/analytics engine. |
| **Visualization** | **OpenSearch Dashboards** | **Kibana** | User interface for querying logs, setting alerts, and monitoring visual dashboards. |

---

## 2. Log Collection & Processing: Vector vs. Fluentd

### Vector (High-Performance Vector Pipeline)

Vector is a lightweight, Rust-based log agent configured via TOML or YAML (`/etc/vector/[vector.yaml](http://vector.yaml)`).

#### Declarative Vector Pipeline Example (`vector.yaml`)

```yaml
sources:
  container_logs:
    type: docker_logs
    include_containers:
      - "api-gateway"

transforms:
  parse_json:
    type: remap
    inputs:
      - container_logs
    source: |
      . = parse_json!(.message)
      .environment = "production"
      del(.headers)

sinks:
  opensearch_sink:
    type: opensearch
    inputs:
      - parse_json
    endpoint: "https://opensearch-cluster.internal:9200"
    mode: "bulk"
    index: "logs-api-gateway-%Y.%m.%d"
    auth:
      strategy: "basic"
      user: "admin"
      password: "StrongPassword123!"
    tls:
      verify_certificate: false

```

### Fluentd (Pluggable Log Forwarding)

Fluentd uses a unified logging layer with JSON data structures and a tag-based routing model (`/etc/td-agent/[td-agent.conf](http://td-agent.conf)`).

#### Fluentd Match & Filter Configuration (`td-agent.conf`)

```xml
<source>
  @type tail
  path /var/log/nginx/access.log
  pos_file /var/log/td-agent/nginx.access.pos
  tag nginx.access
  <parse>
    @type nginx
  </parse>
</source>

<filter nginx.access>
  @type record_transformer
  <record>
    cluster_name production-us-east
  </record>
</filter>

<match nginx.**>
  @type opensearch
  host opensearch-node1.internal
  port 9200
  logstash_format true
  logstash_prefix nginx-logs
  flush_interval 5s
</match>

```

---

## 3. Storage & Search: Elasticsearch & OpenSearch

OpenSearch and Elasticsearch store logs as semi-structured JSON documents inside time-series indices.

### OpenSearch Index Lifecycle Management (ISM)

To keep search performant and control disk utilization, indices are dynamically managed using Index State Management (ISM).

#### ISM Policy Definition (`ism_policy.json`)

```json
{
  "policy": {
    "description": "Hot-Warm-Delete 30-day log lifecycle",
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "actions": [
          {
            "rollover": {
              "min_index_age": "7d",
              "min_primary_shard_size": "30gb"
            }
          }
        ],
        "transitions": [{ "state_name": "warm" }]
      },
      {
        "name": "warm",
        "actions": [
          {
            "replica_count": { "number_of_replicas": 1 }
          }
        ],
        "transitions": [{ "state_name": "delete", "conditions": { "min_index_age": "30d" } }]
      },
      {
        "name": "delete",
        "actions": [{ "delete": {} }]
      }
    ]
  }
}

```

---

## 4. Practical Hands-On Lab: Deploying a Complete OpenSearch & Vector Stack

In this scenario, you will deploy a containerized OpenSearch instance along with OpenSearch Dashboards, and run Vector to process simulated application JSON logs.

### Step 1: Deploy OpenSearch and Dashboards via Compose

Create a `docker-compose.yaml` file:

```yaml
version: '3.8'

services:
  opensearch:
    image: opensearchproject/opensearch:2.12.0
    container_name: opensearch-node
    environment:
      - discovery.type=single-node
      - DISABLE_SECURITY_PLUGIN=true
      - OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m
    ports:
      - "9200:9200"
    networks:
      - logging-net

  dashboards:
    image: opensearchproject/opensearch-dashboards:2.12.0
    container_name: opensearch-dashboards
    ports:
      - "5601:5601"
    environment:
      - OPENSEARCH_HOSTS=["http://opensearch:9200"]
      - DISABLE_SECURITY_PLUGIN=true
    networks:
      - logging-net

networks:
  logging-net:
    driver: bridge

```

Start the services:

```bash
docker compose up -d

```

### Step 2: Configure and Run Vector Log Processing

Create a local Vector configuration file named `vector-standalone.yaml`:

```yaml
sources:
  dummy_logs:
    type: demo_logs
    format: "json"
    interval: 1.0

transforms:
  tag_severity:
    type: remap
    inputs:
      - dummy_logs
    source: |
      .processed_by = "Vector-LPI-Lab"
      if .status > 400 {
        .level = "ERROR"
      } else {
        .level = "INFO"
      }

sinks:
  opensearch_out:
    type: opensearch
    inputs:
      - tag_severity
    endpoint: "http://localhost:9200"
    index: "demo-logs-%Y.%m.%d"
    compression: "gzip"

```

Execute Vector inside a Docker container using the local configuration:

```bash
docker run --net=host -v $(pwd)/vector-standalone.yaml:/etc/vector/vector.yaml:ro timberio/vector:0.35.0-alpine

```

### Step 3: Validate Index Creation and Ingestion

Verify that OpenSearch is receiving log records directly using `curl`:

```bash
# Query OpenSearch Indices
curl -s "http://localhost:9200/_cat/indices?v"

# Query Ingested Documents inside the demo-logs index
curl -s -X GET "http://localhost:9200/demo-logs-*/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "level": "ERROR"
    }
  }
}'

```

---

## 5. Exam Preparation Practice Questions

1. **Which Vector configuration section is responsible for transforming raw log strings into structured JSON fields?**
* A. `sources`
* B. `transforms`
* C. `sinks`
* D. `providers`


2. **In Fluentd tag matching, which pattern matches two specific paths like `nginx.access` and `nginx.error`?**
* A. `nginx.*`
* B. `nginx.**`
* C. `nginx.access+error`
* D. `<match nginx>`


3. **What is the primary function of an Index State Management (ISM) policy in OpenSearch?**
* A. To automatically parse unstructured Nginx text logs into JSON fields.
* B. To automate index transitions (e.g., rollover, replica adjustment, and deletion) based on age or size limits.
* C. To encrypt log communications between Fluentd agents and OpenSearch nodes.
* D. To route incoming traffic evenly across Kibana dashboards.



---

### Answer Key

1. **B** — The `transforms` stage uses VRL (Vector Remap Language) or parsing modules to modify, enrich, and restructure logs.
2. **A** — Single asterisk (`*`) matches exactly one tag element (e.g., `nginx.access`), whereas `**` matches zero or more dot-delimited elements.
3. **B** — ISM automates life-cycle tasks such as index rollover, tier moving, and automated purge operations based on time or disk size thresholds.
