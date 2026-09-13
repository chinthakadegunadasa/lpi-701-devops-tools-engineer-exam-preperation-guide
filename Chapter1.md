# Chapter 1: 701.1 Principles of Software Development & DevOps Best Practices
## 1. Objective Architecture & Theoretical Foundations
This topic addresses the core concepts of modern application design, cloud-native architecture, and operational practices required for the LPI DevOps Tools Engineer (Exam 701) certification.
(img/DevOps.svg)
```
                     +---------------------------------------+
                     |        Agile & DevOps Workflows       |
                      +---------------------------------------+
                                         |
               +-------------------------+-------------------------+
               |                                                   |
               v                                                   v
  +--------------------------+                           +-------------------+
  | Application Architecture |                           |   Cloud-Native    |
  |  (12-Factor / Stateless) |                           | Operations Model  |
  +--------------------------+                           +-------------------+
               |                                                   |
        +------+------+                                     +------+------+
        |             |                                     |             |
        v             v                                     v             v
  +-----------+ +-----------+                         +-----------+ +-----------+
  | Session   | | DB Schema |                         | Immutable | | GitOps    |
  | Decoupling| | Migrations|                         | Containers| | Workflows |
  +-----------+ +-----------+                         +-----------+ +-----------+

```
### 12-Factor App Methodology
 * **Codebase:** One repository tracked in version control per application, with multiple deployments (dev, staging, production) originating from identical code assets.
 * **Dependencies:** Explicitly declare and isolate dependencies using explicit manifest locks (e.g., package-json.lock, Pipfile.lock) rather than relying on implicit system-level packages.
 * **Config:** Store configuration variables that vary across environments (database URIs, API tokens) strictly in environment variables, completely separated from code.
 * **Backing Services:** Treat attached resources (databases, message brokers, caching nodes) as bound remote resources consumed via URL endpoints and credentials without code modifications.
 * **Build, Release, Run:** Strictly separate execution stages. The *Build* stage converts code into an immutable executable bundle; the *Release* stage combines the build with environment configuration; the *Run* stage executes the application runtime.
 * **Processes:** Execute the application as one or more stateless, share-nothing processes. Persistent data must be offloaded to a backing store (e.g., PostgreSQL, Redis).
 * **Port Binding:** Applications must be fully self-contained and export services by binding directly to a network port, eliminating reliance on external web server injection.
 * **Concurrency:** Scale out horizontally by relying on the process model, distributing workloads across lightweight, discrete processes.
 * **Disposability:** Maximize robustness with fast startup routines and graceful shutdown handovers when receiving system signals (SIGTERM).
 * **Dev/Prod Parity:** Maintain dev, staging, and production environments as close to identical as possible by keeping tools, backing services, and deployment pipelines consistent.
 * **Logs:** Treat log outputs as unbuffered event streams (stdout/stderr), routing them to centralized aggregation infrastructure rather than internal log files.
 * **Admin Processes:** Run administrative or maintenance tasks (such as database migrations) as one-off processes in environments identical to long-running application tasks.
### Monolithic vs. Microservices Architectures
 * **Monolithic Architecture:** Combines business logic, data access, and UI layers into a single deployment artifact. Scales vertically; deployment requires rebuilding and redeploying the entire codebase.
 * **Microservices Architecture:** Decomposes systems into autonomous, loosely coupled services communicating via lightweight protocols (gRPC, REST/JSON). Services scale independently, support isolated technology stacks, and minimize failure blast radiuses.
 * **Migration Risks:** Breaking down monoliths risks network latency overhead, complex distributed tracing requirements, eventual consistency trade-offs (BASE vs. ACID), and service discovery management issues.
### Data Persistence, State & Session Handling
 * **Stateless Runtimes:** Application containers must remain stateless to enable instant scaling, migration, and replacement without losing user state.
 * **Externalized Sessions:** Sticky sessions tied to specific server IP addresses hinder horizontal autoscaling. Session state should be stored in high-performance external key-value stores like Redis or Memcached.
 * **Database Schema Migrations:** Database modifications must remain backward-compatible to support zero-downtime deployments. Schema migrations must run using version-controlled, idempotent scripts executed separately from application boot cycles.
### Immutable Infrastructure & GitOps
 * **Immutable Infrastructure:** Server instances or container runtimes are never modified in-place post-deployment. Infrastructure updates require building a new image, deploying it alongside the old instance, and terminating the obsolete version.
 * **GitOps:** Uses Git repositories as the single source of truth for infrastructure and application declarations. Automated operators reconcile state drift between the desired architecture stored in Git and the actual runtime environment.
## 2. Real-World Production Scenario
### System Under Migration
An enterprise platform suffers from high latency, frequent deployment downtime, and deployment friction. The monolithic system uses server-bound PHP sessions and executes inline raw SQL database migrations during application startup, causing database lockups during traffic spikes.
```
[ Legacy Architecture: Monolithic & Vulnerable ]
+-----------------------------------------------------------------+
| Enterprise Monolith Node (Single Point of Failure)              |
|                                                                 |
|  +------------------+   +------------------+   +--------------+ |
|  | Web UI & API     |   | Sticky Sessions  |   | Startup SQL  | |
|  | Processing       |   | (/var/lib/php/)  |   | Migrations   | |
|  +------------------+   +------------------+   +--------------+ |
+-----------------------------------------------------------------+
                                  |
                                  v
                    +---------------------------+
                    | Monolithic Relational DB  |
                    +---------------------------+

                                  |
                                  |  TRANSITION TO GITOPS & 12-FACTOR
                                  v

[ Modernized Cloud-Native Target Architecture ]
                     +--------------------------+
                     | Git Repository (GitOps)  |
                     +--------------------------+
                                  |
                                  v
                     +--------------------------+
                     |  CI/CD Automated Runner  |
                     +--------------------------+
                                  |
          +-----------------------+-----------------------+
          |                                               |
          v                                               v
+------------------+                             +------------------+
| One-Off Job:     |                             | Stateless App    |
| Schema Migration |                             | Containers (xN)  |
+------------------+                             +------------------+
          |                                               |
          | (Pre-Deployment Schema Patch)                 | (REST / API)
          v                                               v
+------------------+                             +------------------+
| Relational DB    |                             | Redis External   |
| (PostgreSQL)     |                             | Session Cluster  |
+------------------+                             +------------------+

```
### Architectural Objectives
 1. Decouple session management into an external Redis layer.
 2. Isolate schema modifications from the application binary lifecycle using decoupled migration scripts.
 3. Enforce 12-Factor principles by passing runtime configurations strictly via environment variables.
 4. Containerize the application into stateless, immutable Docker runtimes.
## 3. Hands-On Step-by-Step Implementation Lab
### Lab Environment Setup
Create a dedicated project directory:
```bash
mkdir -p devops-701-lab1 && cd devops-701-lab1

```
### Step 1: Externalizing Session State & Writing Stateless Application Code
Create a stateless Python application (app.py) using Flask and Redis for decoupled session handling:
```python
import os
import redis
from flask import Flask, session, jsonify

app = Flask(__name__)

# 12-Factor Configuration: Read backing service connections from environment
app.config['SECRET_KEY'] = os.getenv('APP_SECRET_KEY', 'default-dev-key-change-in-prod')
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))

# Initialize Redis client for external session storage
redis_client = redis.StrictRedis(host=REDIS_HOST, port=REDIS_PORT, db=0, decode_responses=True)

@app.route('/healthz', methods=['GET'])
def health_check():
    """Liveness probe returning application and backing service status."""
    try:
        redis_client.ping()
        return jsonify(status="HEALTHY", backing_services={"redis": "CONNECTED"}), 200
    except redis.ConnectionError:
        return jsonify(status="UNHEALTHY", backing_services={"redis": "DISCONNECTED"}), 500

@app.route('/session/visit', methods=['POST'])
def track_visit():
    """Decoupled session tracking leveraging external memory store."""
    user_id = os.getenv('DEMO_USER_ID', 'user_default')
    visits = redis_client.incr(f"session:{user_id}:visits")
    return jsonify(user=user_id, total_visits=visits, storage="redis-external")

if __name__ == '__main__':
    # Port binding via app configuration
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port)

```
### Step 2: Decoupling Database Schema Migrations
Create an isolated, idempotent schema migration runner (migrate.py) to manage database schema updates independently:
```python
import os
import sys
import psycopg2

def run_migrations():
    """Executes database schema updates out-of-band from application deployment."""
    db_uri = os.getenv('DATABASE_URL')
    if not db_uri:
        print("CRITICAL: DATABASE_URL environment variable is missing.")
        sys.exit(1)

    print("Connecting to database for schema migration...")
    try:
        conn = psycopg2.connect(db_uri)
        cursor = conn.cursor()
        
        # Schema migration SQL: Idempotency via IF NOT EXISTS
        migration_sql = """
        CREATE TABLE IF NOT EXISTS schema_migrations (
            id SERIAL PRIMARY KEY,
            version VARCHAR(50) NOT NULL UNIQUE,
            applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        
        CREATE TABLE IF NOT EXISTS user_accounts (
            user_id VARCHAR(100) PRIMARY KEY,
            email VARCHAR(255) NOT NULL UNIQUE,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        cursor.execute(migration_sql)
        conn.commit()
        print("SUCCESS: Database schema migrations applied successfully.")
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"FAILED: Database migration failed with error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    run_migrations()

```
### Step 3: Containerizing for Immutable Infrastructure
Create a multi-stage Dockerfile to produce lightweight container images with minimal attack surfaces:
```dockerfile
# Stage 1: Build & Dependencies
FROM python:3.11-slim AS builder

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Immutable Runtime Image
FROM python:3.11-slim AS runner

WORKDIR /app

# Non-root user setup for secure execution
RUN groupadd -r devops && useradd -r -g devops devops

COPY --from=builder /root/.local /home/devops/.local
COPY app.py migrate.py ./

ENV PATH=/home/devops/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PORT=8080

USER devops

EXPOSE 8080

ENTRYPOINT ["python", "app.py"]

```
Create the requirements.txt manifest:
```text
Flask==3.0.0
redis==5.0.1
psycopg2-binary==2.9.9

```
### Step 4: Orchestrating the Stateless Stack with Docker Compose
Define the multi-service deployment spec in docker-compose.yml:
```yaml
version: '3.8'

services:
  # Backing Store 1: PostgreSQL Relational Database
  postgres-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: app_db
      POSTGRES_USER: db_admin
      POSTGRES_PASSWORD: secure_password123
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U db_admin -d app_db"]
      interval: 5s
      timeout: 5s
      retries: 5

  # Backing Store 2: Redis Session Cache
  redis-cache:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5

  # One-Off Job: Isolated Migration Runner
  schema-migration:
    build: .
    entrypoint: ["python", "migrate.py"]
    environment:
      DATABASE_URL: "postgres://db_admin:secure_password123@postgres-db:5432/app_db"
    depends_on:
      postgres-db:
        condition: service_healthy

  # Application Tier: Scalable Stateless Runtimes
  web-application:
    build: .
    ports:
      - "8080:8080"
    environment:
      PORT: 8080
      APP_SECRET_KEY: "prod-environment-secret-key"
      REDIS_HOST: "redis-cache"
      REDIS_PORT: 6379
      DATABASE_URL: "postgres://db_admin:secure_password123@postgres-db:5432/app_db"
    depends_on:
      redis-cache:
        condition: service_healthy
      schema-migration:
        condition: service_completed_successfully

```
## 4. Verification & Validation Steps
### 1. Build and Launch the Stack
Run the container environment using Docker Compose:
```bash
docker compose up --build -d

```
### 2. Verify Decoupled Schema Migration Execution
Confirm that the migration job ran independently to completion without disrupting application deployment:
```bash
docker compose logs schema-migration

```
*Expected Output:*
```text
Connecting to database for schema migration...
SUCCESS: Database schema migrations applied successfully.

```
### 3. Test Application Health Endpoint
Query the /healthz endpoint to confirm backing store connections:
```bash
curl -i http://localhost:8080/healthz

```
*Expected Output:*
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "backing_services": {
    "redis": "CONNECTED"
  },
  "status": "HEALTHY"
}

```
### 4. Validate Session Persistence Across Containers
Simulate traffic to verify stateless session tracking in Redis:
```bash
curl -X POST http://localhost:8080/session/visit
curl -X POST http://localhost:8080/session/visit

```
*Expected Output:*
```json
{
  "storage": "redis-external",
  "total_visits": 2,
  "user": "user_default"
}

```
### 5. Verify Immutability by Restarting Application Containers
Destroy and recreate the web application container:
```bash
docker compose restart web-application
curl -X POST http://localhost:8080/session/visit

```
*Result:* The counter increments to 3, confirming that state is fully decoupled from the container runtime.
## 5. Command & Tool Quick Reference
| Command / Flag | Purpose / Objective | Example Usage |
|---|---|---|
| docker compose up --build | Builds immutable images and starts declared services. | docker compose up --build -d |
| docker compose run --rm | Runs a one-off administrative task in an isolated container context. | docker compose run --rm web-application python migrate.py |
| docker compose scale | Scales a stateless application service horizontally. | docker compose up -d --scale web-application=3 |
| pg_isready | Database CLI utility used to check network readiness in health probes. | pg_isready -h localhost -p 5432 |
| redis-cli ping | Redis CLI command verifying cache node operational status. | redis-cli -h 127.0.0.1 -p 6379 ping |
## 6. Exam-Style Self-Assessment Questions
### Question 1
An organization needs to update its database schema during a deployment. Under modern DevOps practices and the 12-Factor App methodology, which approach should be implemented?
A. Write inline code within the application startup sequence that executes database migrations on process boot.
B. Execute database schema migrations as a decoupled, isolated administrative step prior to running the new application version.
C. Connect directly to the production database via an SSH tunnel and manually apply DDL statements while traffic is active.
D. Rebuild the database image with the new schema embedded and replace the production database container without persistent storage.
### Question 2
When migrating a monolithic web application to a stateless containerized runtime, how should user session data be handled to support horizontal scaling?
A. Enable sticky sessions on the load balancer to route each client to the same container instance.
B. Store session data in the container's local /tmp directory using ephemeral file storage.
C. Offload session state to an external, high-performance backing store like Redis or Memcached.
D. Compile session management state into the Docker container image layer.
### Answer Key & Explanations
#### Question 1
 * **Correct Answer:** **B**
 * **Explanation:** The 12-Factor App methodology dictates that administrative tasks (such as database migrations) should run as one-off processes in an isolated container context. Running migrations directly inside application boot routines (Choice A) creates race conditions when scaling out horizontally. Manual database changes (Choice C) violate automation principles, and Choice D causes data loss.
#### Question 2
 * **Correct Answer:** **C**
 * **Explanation:** Stateless application containers must not store session state locally. Storing session data in an external backing store like Redis ensures any application container can serve any incoming request, enabling seamless horizontal autoscaling. Sticky sessions (Choice A) create state coupling at the network layer and reduce fault tolerance. Options B and D violate container immutability and statelessness principles.
 
