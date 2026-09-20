# LPI 701 Devops Tools Engineer exam preperation guide

LPI  exam 701 DevOps  Tools Engineer exam preparation guide 

# LPIC DevOps Tools Engineer (Exam 701) — Hands-On Scenario-Based Exam Preparation Guide

## Executive Overview & Study Strategy

- **Certification Overview:** LPI 701 DevOps Tools Engineer Exam Structure, Weightings, & Passing Criteria
- **Learning Methodology:** Scenario-Based Learning, Production Incident Simulations, & Tool Interoperability Labs
- **Lab Environment Architecture:** Local Multi-Node Virtualization Setup (Vagrant, VirtualBox, Docker Desktop, AWS LocalStack)
- **Exam Strategy:** Managing Objective-Specific Weightings, Deconstructing Scenario Questions, & Key Syntax Cheat Sheets

## Part I: Software Configuration Management & Machine Deployment (Weight 10)

### Topic 701: Modern Software Development & DevOps Principles

- **[Chapter 1: 701-1 Principles of Software Development & DevOps Best Practices](Chapter1.md)**
  
  - **Theory & Objectives:** Agile vs. DevOps, Continuous Delivery, Immutable Infrastructure, Infrastructure as Code (IaC), GitOps Paradigms.
  - **Real-World Scenario 1.1:** Deconstructing a Monolithic Deployment Bottleneck — Transitioning an Enterprise E-Commerce Platform to a CI/CD-Driven Microservices Architecture.
  - **Hands-On Lab 1.1:** Standardizing Developer Workspaces using Docker Dev Containers and Local Test Environments.
  - **Scenario Review & Self-Assessment:** Troubleshooting Deployment Friction Points, Value Stream Mapping Analysis, and Exam-Style Practice Questions.

- **[Chapter 2: 701.2 Source Code & Version Control Systems (Git)](Chapter2.md)**
- 
  - **Theory & Objectives:** Advanced Git Workflows (Trunk-Based vs. GitFlow), Rebasing vs. Merging, Submodules/Subtrees, Interactive Rebase, Hooks, Bisecting, and Merge Conflict Resolution.
  - **Real-World Scenario 1.2:** Resolving Production Branch Drift and Broken Release History during a High-Priority Hotfix.
  - **Hands-On Lab 1.2:**
    - Lab 1.2.1: Setting up Pre-Commit and Pre-Push Server-Side Hooks for Automated Linting and Secret Detection.
    - Lab 1.2.2: Utilizing `git bisect` to Isolate a Memory Leak Introduced Across 500+ Commits.
    - Lab 1.2.3: Managing Complex Multi-Repository Dependencies using Git Submodules and `git subtree`.
  - **Command & Syntax Reference:** Deep Dive into `git cherry-pick`, `git rebase -i`, `git reflog`, `git worktree`.
  - **Scenario Review & Self-Assessment:** Resolving Complex Three-Way Merge Conflicts and Exam-Style Practice Questions.

## Part II: Container Management & Orchestration (Weight 13)

### Topic 702: Container Virtualization & Runtime Environments

- **: [Chapter 3: 702.1 Container Virtualization with Docker](Chapter3.md)**
  
  - **Theory & Objectives:** OCI Specifications, Linux Namespaces & cgroups, Docker Engine Architecture, Multistage Builds, Storage Drivers, Networking Modes (Bridge, Host, Overlay, Macvlan), Docker Compose.
  - **Real-World Scenario 2.1:** Hardening and Optimizing a Vulnerable, Bloated Node.js/Python Enterprise Image (Reducing Image Size from 1.8GB to 45MB while Eliminating CVEs).
  - **Hands-On Lab 2.1:**
    - Lab 2.1.1: Authoring Secure Multi-Stage Dockerfiles with Non-Root Users and Minimal Base Images (Distroless/Alpine).
    - Lab 2.1.2: Configuring Container Networking, Custom Bridge Networks, and Inter-Container DNS.
    - Lab 2.1.3: Designing Multi-Service Stacks with `docker-compose.yml` (Healthchecks, Volume Mounts, Environment Injection, Resource Limits).
  - **Command & Syntax Reference:** Complete Docker CLI (`build`, `run`, `network`, `volume`, `exec`, `inspect`, `system prune`).
  - **Scenario Review & Self-Assessment:** Debugging Crashed Containers using `docker logs`, `docker inspect`, and System-Level cgroup Resource Limits.

- ** [Chapter 4: 702.2 Container Orchestration & Clustering (Docker Swarm & Kubernetes Fundamentals)](Chapter4.md)**
  
  - **Theory & Objectives:** Clustering Architecture, Manager/Worker Nodes, Raft Consensus, Service Scaling, Rolling Updates, Secrets Management, Ingress Routers (Traefik/Nginx), Pods, Services, Deployments, ConfigMaps.
  - **Real-World Scenario 2.2:** High-Availability Cluster Outage Recovery — Migrating Services and Zero-Downtime Rolling Upgrades under Heavy Traffic Load.
  - **Hands-On Lab 2.2:**
    - Lab 2.2.1: Initializing a Multi-Node Docker Swarm Cluster with TLS Verification and Network Overlay Encryption.
    - Lab 2.2.2: Deploying Microservices using Docker Stack Declarative YAMLs with Placement Constraints and Resource Limits.
    - Lab 2.2.3: Managing Kubernetes Deployment Manifests, StatefulSets, ClusterIP, NodePort, and LoadBalancer Services.
  - **Command & Syntax Reference:** Docker Swarm Commands (`docker swarm`, `docker node`, `docker service`, `docker stack`) & Key `kubectl` Operations.
  - **Scenario Review & Self-Assessment:** Cluster Node Drain Operations, Stateful Service Recovery, and Exam-Style Practice Questions.

## Part III: Configuration Management & Infrastructure Automation (Weight 14)

### Topic 703: Infrastructure Configuration Management Tools

- **[Chapter 5: 703.1 Infrastructure Automation with Ansible](Chapter5.md)**
  
  - **Theory & Objectives:** Agentless Architecture, Control Nodes vs. Managed Nodes, Inventory Files (Static/Dynamic), Playbooks, Modules, Roles, Handlers, Variables, Vault, Jinja2 Templating, Molecule Testing.
  - **Real-World Scenario 3.1:** Automating Emergency OS Security Patching and Configuration Drift Remediation across 200 Hybrid Infrastructure Servers.
  - **Hands-On Lab 3.1:**
    - Lab 3.1.1: Writing Modular Ansible Roles for Web Server (Nginx) and Database (PostgreSQL) Hardening.
    - Lab 3.1.2: Securing Sensitive Credentials using `ansible-vault` with Role-Based Password Files.
    - Lab 3.1.3: Dynamic Inventory Integration with AWS/GCP APIs and Custom Python Scripts.
    - Lab 3.1.4: Orchestrating Zero-Downtime Database Migration and Web Application Updates with Handlers and Block Conditions.
  - **Command & Syntax Reference:** `ansible-playbook`, `ansible-galaxy`, `ansible-vault`, `ansible-doc`, Ad-hoc Execution Commands.
  - **Scenario Review & Self-Assessment:** Debugging Playbook Execution Failures, Task Idempotence Validation, and Exam-Style Practice Questions.

- **[Chapter 6: 703.2 Infrastructure Provisioning with Terraform / Cloud Architecture]((Chapter6.md))**

  - **Theory & Objectives:** Declarative Infrastructure, HCL Syntax, Providers, Resources, State File Management (Remote Backend, Locking via DynamoDB/S3), Modules, Variables, Data Sources, Workspace Management.
  - **Real-World Scenario 3.2:** Rebuilding a Corrupted Multi-Tier AWS/Cloud Environment from Scratch using Immutable Terraform Code and Remote State Recovery.
  - **Hands-On Lab 3.2:**
    - Lab 3.2.1: Provisioning VPC, Subnets, Security Groups, and Load Balancers via Terraform HCL.
    - Lab 3.2.2: Implementing Remote State Storage with S3/GCS Backends and Distributed State Locking.
    - Lab 3.2.3: Refactoring Monolithic HCL into Reusable, Parameterized Infrastructure Modules.
  - **Command & Syntax Reference:** `terraform init`, `plan`, `apply`, `destroy`, `state`, `import`, `workspace`, `fmt`, `validate`.
  - **Scenario Review & Self-Assessment:** Handling State File Discrepancies, Importing Existing Unmanaged Infrastructure, and Exam-Style Practice Questions.

## Part IV: Continuous Integration & Continuous Delivery (CI/CD) (Weight 12)

### Topic 704: CI/CD Pipelines & Service Integration

- **[Chapter 7: 704.1 Continuous Integration with Jenkins](Chapter7.md)**
  
  - **Theory & Objectives:** Jenkins Architecture (Master/Controller vs. Agents/Executors), Declarative vs. Scripted Pipelines, Jenkinsfile Syntax, Shared Libraries, Credentials Management, Plugins Ecosystem, Webhooks Integration.
  - 
  - **Real-World Scenario 4.1:** Diagnosing and Repairing a Broken Automated CI/CD Deployment Pipeline Blocking Production Hotfixes.
    
  - **Hands-On Lab 4.1:**
    
    - Lab 4.1.1: Constructing a Multi-Stage Declarative `Jenkinsfile` (Checkout, Static Analysis, Unit Testing, Docker Build, Container Scanning, Staging Deployment).
    - Lab 4.1.2: Dynamic Scaling of Jenkins Build Agents using Docker and Kubernetes Executors.
    - Lab 4.1.3: Setting up Pipeline Security, RBAC, Secret Masking, and Webhook Notifications (Slack/Teams).

  - **Command & Syntax Reference:** Jenkinsfile Directives (`pipeline`, `agent`, `stages`, `post`, `environment`, `options`, `when`, `matrix`).
    
  - **Scenario Review & Self-Assessment:** Troubleshooting Build Failures, Flaky Test Resolution, and Exam-Style Practice Questions.

- **[Chapter 8: 704.2 Pipeline Automation with GitLab CI/CD & GitHub Actions](Chapter8.md)**
 
  - **Theory & Objectives:** `.gitlab-ci.yml` Structure, Runners, Executors, Stages, Artifacts, Caching, Environment Variables, GitHub Actions Workflow Syntax (`.github/workflows`), Runners, Actions, Secret Management.
  - 
  - **Real-World Scenario 4.2:** Migrating a Legacy Monolithic Enterprise Build System to a Distributed GitHub Actions / GitLab CI Matrix Build Environment.
  - **Hands-On Lab 4.2:**
    - Lab 4.2.1: Building Parallel Testing Pipelines with Matrix Builds in GitHub Actions.
    - Lab 4.2.2: Implementing Canary and Blue/Green Deployment Strategies in GitLab CI.
    - Lab 4.2.3: Managing Pipeline Caching and Artifact Dependencies for Accelerated Build Speeds.
  - **Command & Syntax Reference:** Key YAML Schema and Keyword Reference for GitLab CI (`stages`, `script`, `artifacts`, `cache`, `rules`) and GitHub Actions (`on`, `jobs`, `steps`, `uses`, `with`).
  - **Scenario Review & Self-Assessment:** Debugging Pipeline Runners, Cache Invalidation Issues, and Exam-Style Practice Questions.

## Part V: Monitoring, Metrics, & Log Analytics (Weight 11)

### Topic 705: System Monitoring & Logging Infrastructure

- **[Chapter 9: 705.1 Metrics Collection & Visualization (Prometheus & Grafana)](Chapter9.md)**
- 
  - **Theory & Objectives:** Pull vs. Push Metrics Architecture, Prometheus Server, Exporters (Node Exporter, cAdvisor), PromQL Queries, Time-Series Data, Alertmanager, Grafana Dashboards & Data Sources.
  - **Real-World Scenario 5.1:** Investigating an Intermittent Production Service Latency Spike using Prometheus Metrics and Grafana Dashboard Analytics.
  - 
  - **Hands-On Lab 5.1:**
    
    - Lab 5.1.1: Deploying Prometheus & Node Exporter to Monitor System and Application Metrics.
    - Lab 5.1.2: Writing Complex PromQL Queries (`rate()`, `increase()`, `histogram_quantile()`, `sum() by()`).
    - Lab 5.1.3: Configuring Prometheus Alertmanager Rules for High Memory, CPU Throttling, and Service Outages.
    - Lab 5.1.4: Building Dynamic, Interactive Grafana Dashboards with Alert Rules and Visual Annotations.
    - 
  - **Command & Syntax Reference:** PromQL Syntax Guide, Alertmanager Routing Configuration Rules.
  - 
  - **Scenario Review & Self-Assessment:** Resolving Missing Metrics, Exporter Scrape Failures, and Exam-Style Practice Questions.

- **[Chapter 10: 705.2 Log Management & Analysis (ELK Stack / OpenSearch & Vector/Fluentd)](Chapter10.md)**
  
  - **Theory & Objectives:** Centralized Logging Topologies, Elasticsearch/OpenSearch indexing, Logstash Pipelines, Kibana Visualizations, Beats Filebeat/Metricbeat, Fluentd/Fluent Bit Log Shippers.
    
  - **Real-World Scenario 5.2:** Root Cause Analysis of an Application Ingress Crash using Centralized Log Aggregation and Correlation.
    
  - **Hands-On Lab 5.2:**
    
    - Lab 5.2.1: Configuring Filebeat for Docker Container Log Collection and Parsing.
    - Lab 5.2.2: Building Logstash Parsing Pipelines using Grok Filters, Mutate Filters, and Elasticsearch Output Routing.
    - Lab 5.2.3: Designing Kibana Discover Views, Saved Queries, Visualization Panels, and Incident Dashboards.
      
  - **Command & Syntax Reference:** Elasticsearch REST API Commands (`_cat`, `_search`, `_cluster/health`), Grok Pattern Formats.
  
  - **Scenario Review & Self-Assessment:** Debugging Log Pipeline Bottlenecks, Unparsed Logs, and Exam-Style Practice Questions.

---

## Part VI: Security, Compliance, & IT Operations (Weight 10)

### Topic 706: DevSecOps, Vulnerability Management, & Compliance

- **706.1 Security Scanning & Vulnerability Assessment Tools**
  
  - **Theory & Objectives:** DevSecOps Integration, Static Application Security Testing (SAST), Dynamic Application Security Testing (DAST), Software Bill of Materials (SBOM), Dependency Scanning (Trivy, Grype, SonarQube, Bandit, OWASP Dependency-Check).
    
  - **Real-World Scenario 6.1:** Automated Security Gate Enforcement — Blocking Vulnerable Docker Images and Dependency CVEs from Reaching Staging and Production Environments.
  - **Hands-On Lab 6.1:**
    
    - Lab 6.1.1: Integrating Trivy Container Scanning into GitHub Actions/Jenkins Pipelines with Severity Threshold Enforcement.
    - Lab 6.1.2: Performing Code Analysis and Quality Gate Setup with SonarQube.
    - Lab 6.1.3: Generating and Auditing Software Bill of Materials (SBOM) with Syft and Grype.
      
  - **Command & Syntax Reference:** `trivy image`, `trivy fs`, `syft`, `grype` Command Options and Configuration Files.
    
  - **Scenario Review & Self-Assessment:** Resolving False Positives, Vulnerability Triage, and Exam-Style Practice Questions.

- **706.2 Identity, Access, & Secrets Management**
  
  - **Theory & Objectives:** Principles of Least Privilege, Secret Management vs. Hardcoded Secrets, HashiCorp Vault Architecture, Dynamic Secrets, Secret Engine Configuration, Token Lifecycle, Auth Methods.
    
  - **Real-World Scenario 6.2:** Remediating Hardcoded Database Credentials Leaked into Source Code — Setting up Automated Key Rotation with HashiCorp Vault.
    
  - **Hands-On Lab 6.2:**
    
    - Lab 6.2.1: Deploying and Initializing HashiCorp Vault in Production-Ready Mode.
    - Lab 6.2.2: Configuring KV Secrets Engines and Injecting Dynamic Database Credentials into Applications.
    - Lab 6.2.3: Integrating HashiCorp Vault with Kubernetes Service Accounts and CI/CD Pipelines.
      
  - **Command & Syntax Reference:** `vault operator`, `vault kv`, `vault secrets`, `vault auth`, `vault policy`.
    
  - **Scenario Review & Self-Assessment:** Managing Vault Lease Expirations, Token Renewal Failures, and Exam-Style Practice Questions.

## Part VII: Comprehensive Capstone Labs & Final Exam Simulation

### Chapter 7: End-to-End Enterprise Scenario Simulations

- **Capstone Project 1:** "The Broken Release" — Full Lifecycle Incident Resolution
  - *Scenario:* A multi-tier microservice release crashes production during a scheduled blue/green deployment.
  - *Objective:* Debug the Git commit history, identify broken Docker images, fix the failed Ansible configuration, re-apply Terraform state, re-run Jenkins pipeline, verify Prometheus alerts clear, and establish Kibana audit trail.
  - 
- **Capstone Project 2:** "Greenfield Infrastructure Provisioning"
  - *Scenario:* Provision a multi-cloud secure Kubernetes stack using Terraform, configure nodes via Ansible, deploy monitoring with Helm/Prometheus, configure GitHub Actions CI/CD, and enforce security policies with HashiCorp Vault and Trivy.

### Chapter 8: Full-Length Practice Examination

- **Practice Exam Overview & Guidelines**
- **Exam Simulation (60 Questions covering all 701-706 Objectives)**
- **Detailed Answer Explanations, Domain Mapping, & Topic Weighting Analysis**

---

## Appendix & Quick-Reference Sheets

- **Appendix A:** Comprehensive Tooling Command Matrix (Git, Docker, Kubernetes, Ansible, Terraform, Jenkins, Prometheus, Vault)
- **Appendix B:** Common Configuration Schemas (`docker-compose.yml`, `Jenkinsfile`, `.gitlab-ci.yml`, Ansible Playbooks, Terraform HCL)
- **Appendix C:** LPIC 701 Exam Objective Mapping Matrix

