# Chapter 3: 702.1 Container Virtualization with Docker
## 1. Objective Architecture & Theoretical Foundations
Docker and container virtualization form a core component of the LPIC DevOps Tools Engineer (Exam 701) certification. This topic evaluates your understanding of container runtimes, underlying Linux kernel namespaces, control groups (cgroups), Open Container Initiative (OCI) standards, networking topologies, storage drivers, and optimized multi-stage image builds.  ![Container Runtime Architecture](img/lpi-ex701-ch3-container-runtime-architecture.jpeg] 

### Kernel Primitive Isolation
 * **Linux Namespaces:** Provide system resource isolation per container context. Key namespaces include:
   * pid: Isolates process trees (process ID mapping).
   * net: Isolates network interface controllers, routing tables, and port allocations.
   * mnt: Isolates filesystem mount points.
   * ipc: Isolates System V IPC and POSIX message queues.
   * uts: Isolates hostname and NIS domain settings.
   * user: Maps container root users (UID 0) to unprivileged host user IDs.
 * **Control Groups (cgroups):** Limit, account for, and isolate physical system resource utilization (CPU shares, memory allocations, block I/O throughput, network traffic).
 * **OCI Specifications:** The Open Container Initiative standardizes image formats (image-spec) and runtime behavior (runtime-spec, managed via runc).
### Docker Storage Drivers & Filesystem Mechanics
 * **Storage Drivers:** Docker uses Copy-on-Write (CoW) filesystems to layer changes on top of base images.
   * **Overlay2:** The default storage driver for Linux distributions. Combines an lowerdir (read-only image layers) and an upperdir (read-write container layer) into a unified merged view.
 * **Persistent Data Management:**
   * **Bind Mounts:** Maps an explicit path on the host system filesystem directly into a container directory. Dependent on host path structures.
   * **Named Volumes:** Managed by Docker within designated host locations (e.g., /var/lib/docker/volumes/). Decoupled from host path configurations and suitable for persistent backing databases.
   * **tmpfs Mounts:** Mounts data directly into host memory without persisting to non-volatile disk storage.
### Docker Networking Drivers
 * **Bridge (default):** Creates a virtual software bridge (docker0) isolated from host interfaces. Containers obtain internal private IPs and expose ports via NAT (iptables).
 * **Host:** Removes network isolation between the container and the Docker host. The container binds directly to host network interfaces without NAT overhead.
 * **Overlay:** Enables multi-host network routing across distributed cluster daemon nodes (used in Docker Swarm and multi-host setups).
 * **Macvlan:** Assigns a unique MAC address to a container, making it appear as a physical network device connected directly to the physical host subnet.
 * **None:** Disables network interfaces for the container, retaining only the loopback interface (lo).
## 2. Real-World Production Scenario
### System Under Hardening
An enterprise Node.js microservice image is deployed in production using a single-stage build. The container runs as root, packages unnecessary OS build tools (gcc, make, python), weighs 1.8 GB, contains critical CVE vulnerabilities, and lacks container resource limits.
```
[ Vulnerable Legacy Build: 1.8 GB ]
+-----------------------------------------------------------------+
| Node.js App Base Image (Ubuntu/Debian full OS dependencies)      |
|  - Runs as `root` user                                           |
|  - Contains build tools (gcc, make) and unneeded packages       |
|  - Unlimited CPU & Memory usage                                 |
+-----------------------------------------------------------------+
                                  |
                                  |  OPTIMIZATION & HARDENING PIPELINE
                                  v
[ Hardened Production Image: 45 MB ]
+-----------------------------------------------------------------+
| Multi-Stage Alpine/Distroless Runtime Container                 |
|  - Non-root unprivileged process context (`node` user)          |
|  - Unneeded toolchains discarded in build stage                 |
|  - Memory & CPU resource limits enforced in Compose             |
|  - Read-only root filesystem enabled                            |
+-----------------------------------------------------------------+

```
### Architectural Objectives
 1. Construct a hardened multi-stage Dockerfile that drops image size from ~1.8 GB to ~45 MB and strips non-essential build packages.
 2. Execute container runtimes under an unprivileged user context (UID 10001).
 3. Configure custom bridge networking with internal DNS resolution.
 4. Enforce runtime memory and CPU allocations using docker-compose.yml specs.
## 3. Hands-On Step-by-Step Implementation Lab
### Lab Environment Setup
Create a working directory for the lab:
```bash
mkdir -p devops-701-docker-lab && cd devops-701-docker-lab

```
### Step 1: Constructing a Hardened Multi-Stage Dockerfile
Create a sample application file (app.js):
```javascript
const http = require('http');
const port = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'HEALTHY', timestamp: new Date() }));
    return;
  }
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('Hardened Node.js Microservice Executing\n');
});

server.listen(port, () => {
  console.log(`Application active and listening on port ${port}`);
});

```
Create an application dependency manifest (package.json):
```json
{
  "name": "hardened-service",
  "version": "1.0.0",
  "main": "app.js",
  "dependencies": {
    "express": "^4.18.2"
  }
}

```
Write a multi-stage Dockerfile enforcing security best practices:
```dockerfile
# Stage 1: Dependencies & Compilation Build Engine
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./
# Install production dependencies cleanly
RUN npm ci --only=production

# Stage 2: Hardened Runtime Container
FROM node:20-alpine AS runner

WORKDIR /usr/src/app

# Hardening: Run as an unprivileged node user
USER node

# Copy dependencies and application logic from builder stage
COPY --chown=node:node --from=builder /usr/src/app/node_modules ./node_modules
COPY --chown=node:node app.js package.json ./

ENV NODE_ENV=production \
    PORT=3000

EXPOSE 3000

# Health check probe configuration
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/healthz || exit 1

CMD ["node", "app.js"]

```
### Step 2: Configuring Custom Bridge Networks & Inter-Container Communication
Create a separate reverse-proxy configuration (nginx.conf) to test custom container bridge networking:
```nginx
events { worker_connections 1024; }

http {
    upstream backend_app {
        server app-service:3000;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://backend_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}

```
### Step 3: Orchestrating the Hardened Stack with Resource Limits
Create docker-compose.yml to declare networks, volumes, health checks, and cgroup resource allocations:
```yaml
version: '3.8'

services:
  # App Layer: Hardened Multi-Stage Microservice
  app-service:
    build:
      context: .
      dockerfile: Dockerfile
    image: microservice:v1.0.0
    container_name: hardened-app
    restart: unless-stopped
    networks:
      - internal-bridge
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 256M
        reservations:
          cpus: '0.10'
          memory: 64M
    security_opt:
      - no-new-privileges:true

  # Ingress Proxy Layer: Nginx Ingress Controller
  ingress-proxy:
    image: nginx:1.25-alpine
    container_name: edge-proxy
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - internal-bridge
    depends_on:
      app-service:
        condition: service_healthy
    deploy:
      resources:
        limits:
          cpus: '0.25'
          memory: 128M

networks:
  internal-bridge:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16

```
## 4. Verification & Validation Steps
### 1. Build Image and Compare Layer Optimization
Build the optimized multi-stage image:
```bash
docker compose build

```
Verify the compact footprint of the resulting image:
```bash
docker images | grep microservice

```
*Expected Output:* The image size remains under ~50 MB, dropping runtime overhead compared to standard Linux distribution images.
### 2. Launch Stack and Verify Health Checks
Bring up the multi-container stack:
```bash
docker compose up -d

```
Verify container status, health state, and network allocations:
```bash
docker compose ps

```
*Expected Output:*
```text
NAME           IMAGE                 COMMAND                  SERVICE         CREATED         STATUS                   PORTS
edge-proxy     nginx:1.25-alpine     "/docker-entrypoint.…"   ingress-proxy   10 seconds ago  Up 8 seconds             0.0.0.0:8080->80/tcp
hardened-app   microservice:v1.0.0   "docker-entrypoint.s…"   app-service     10 seconds ago  Up 9 seconds (healthy)   3000/tcp

```
### 3. Verify Non-Root Execution & Container Inspection
Inspect the process list inside the running application container to confirm it executes as an unprivileged user (node / UID 1000):
```bash
docker exec hardened-app id

```
*Expected Output:*
```text
uid=1000(node) gid=1000(node) groups=1000(node)

```
### 4. Verify Internal Network Resolution & Resource Constraints
Verify that Nginx successfully routes traffic over the custom bridge network (internal-bridge) via embedded container DNS:
```bash
curl -i http://localhost:8080/healthz

```
*Expected Output:*
```http
HTTP/1.1 200 OK
Content-Type: application/json

{"status":"HEALTHY","timestamp":"..."}

```
Check real-time system resource utilization to verify cgroup resource enforcement:
```bash
docker stats --no-stream hardened-app edge-proxy

```
## 5. Command & Tool Quick Reference
| Command / Flag | Purpose / Objective | Example Usage |
|---|---|---|
| docker build --target | Builds an image up to a specific intermediate stage defined in a multi-stage Dockerfile. | docker build --target builder -t app:build . |
| docker system prune -a --volumes | Removes unused container data, networks, stopped containers, and unreferenced volumes. | docker system prune -a --volumes |
| docker inspect --format | Extracts specific metadata attributes from container JSON manifests using Go templates. | docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' hardened-app |
| docker run --read-only | Mounts the root filesystem of the container as read-only. | docker run --read-only --tmpfs /tmp microservice:v1.0.0 |
| docker stats | Displays a live stream of container resource consumption statistics (CPU, memory, I/O). | docker stats hardened-app |
## 6. Exam-Style Self-Assessment Questions
### Question 1
A DevOps engineer needs to build an efficient Docker container image for a compiled Go application. The application requires build dependencies (golang SDK) during compilation, but the final production runtime needs only the compiled binary executable. Which strategy minimizes the final production image size while maintaining single-command build functionality?
A. Write two separate Dockerfiles (Dockerfile.build and Dockerfile.run) and use a host shell script to copy the compiled binary between images.
B. Author a multi-stage Dockerfile using FROM golang AS builder for compilation, and FROM scratch or FROM alpine for the final stage, copying the binary using COPY --from=builder.
C. Use a standard golang base image and run apt-get remove --purge golang at the end of the RUN instruction chain.
D. Compile the binary on the developer's local workstation OS and use COPY to move it into a node:latest container image.
### Question 2
When using the default overlay2 storage driver in Docker on a Linux system, where does Docker locate and store container layer data and volume storage by default?
A. /etc/docker/daemon.json
B. /usr/local/bin/docker/storage/
C. /var/lib/docker/
D. /opt/containerd/overlay2/
### Answer Key & Explanations
#### Question 1
 * **Correct Answer:** **B**
 * **Explanation:** Multi-stage builds allow developers to use large base images containing compilers and SDKs in earlier stages, then copy *only* the resulting compiled binaries into a minimal base runtime stage (scratch or alpine). This reduces image size and eliminates unnecessary build tools from production environments. Choice A works but breaks single-file build conventions, and Choice C fails to recover disk space because deleted files remain stored in prior image layers.
#### Question 2
 * **Correct Answer:** **C**
 * **Explanation:** Docker's default root storage directory on Linux hosts is /var/lib/docker/. This directory stores container layers, volumes, images, and runtime driver states (including Overlay2 structures under /var/lib/docker/overlay2).
 
