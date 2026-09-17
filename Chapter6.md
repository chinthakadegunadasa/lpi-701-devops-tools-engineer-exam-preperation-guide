# Chapter 6: Infrastructure Provisioning with Terraform & Cloud Architecture

This chapter provides an enterprise-grade, hands-on guide to infrastructure provisioning using Terraform (OpenTofu) and modern cloud architectural design principles. It covers declarative state management, custom module design, remote backends with locking, dynamic workspaces, multi-provider orchestrations, and automated CI/CD pipeline integration.

---

## 1. Enterprise Terraform Directory & Workspace Layout

Production environments enforce isolation between environments (development, staging, production) and underlying infrastructure components (networking, compute, storage) to limit blast radius and prevent state file locks across teams.

### 1.1 Structural Layout

```text
terraform-infrastructure/
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── compute_cluster/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev/
    │   ├── main.tf
    │   ├── providers.tf
    │   ├── backend.tf
    │   └── terraform.tfvars
    └── prod/
        ├── main.tf
        ├── providers.tf
        ├── backend.tf
        └── terraform.tfvars

```

---

## 2. Remote State Backend & State Locking Architecture

Storing state locally introduces security risks and race conditions. Remote backends ensure state file encryption at rest, versioning, and atomic state locking.

### 2.1 Backend Configuration (`backend.tf`)

```hcl
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "enterprise-tf-state-prod-01"
    key            = "infrastructure/cloud-arch/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "enterprise-tf-locks-prod"
  }
}

```

### 2.2 Provider Declarations (`providers.tf`)

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "Infrastructure-Automation"
    }
  }
}

```

---

## 3. Reusable Custom Module Design

Modules isolate architectural patterns, enforcing design standards, compliance controls, and consistent resource tagging across an enterprise.

### 3.1 Networking Module Inputs (`modules/networking/variables.tf`)

```hcl
variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.100.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The vpc_cidr value must be a valid CIDR block."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of public subnet CIDR blocks"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDR blocks"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones for multi-AZ resiliency"
}

```

### 3.2 Networking Implementation (`modules/networking/main.tf`)

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "main-nat-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

```

### 3.3 Module Outputs (`modules/networking/outputs.tf`)

```hcl
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the provisioned VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of public subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List of private subnet IDs"
}

```

---

## 4. Advanced Dynamic Expressions & Iteration

Use dynamic blocks, `for_each`, and expressions to generate scalable configurations declaratively.

### 4.1 Dynamic Security Group Rules

```hcl
variable "ingress_rules" {
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    { port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow HTTP" },
    { port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"], description = "Allow HTTPS" },
    { port = 22, protocol = "tcp", cidr_blocks = ["10.0.0.0/8"], description = "Allow VPN SSH" }
  ]
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Ingress control for Load Balancer"
  vpc_id      = module.networking.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

```

---

## 5. Main Environment Orchestration (`environments/prod/main.tf`)

This composition ties modules together into an enterprise application architecture.

```hcl
module "networking" {
  source = "../../modules/networking"

  vpc_cidr             = "10.50.0.0/16"
  public_subnet_cidrs  = ["10.50.1.0/24", "10.50.2.0/24"]
  private_subnet_cidrs = ["10.50.10.0/24", "10.50.20.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
}

resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "db_subnets" {
  name       = "prod-db-subnet-group"
  subnet_ids = module.networking.private_subnet_ids
}

resource "aws_db_instance" "postgresql" {
  allocated_storage      = 50
  max_allocated_storage  = 200
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.r6g.xlarge"
  db_name                = "production_db"
  username               = "db_admin"
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = false
  final_snapshot_identifier = "prod-db-final-snapshot"
  multi_az               = true
}

resource "aws_security_group" "db_sg" {
  name        = "db-security-group"
  description = "Restrict access to database layer"
  vpc_id      = module.networking.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

```

---

## 6. Automated Pipeline Integration (GitLab CI / GitHub Actions)

To maintain state consistency, prevent unreviewed changes, and enforce policy checks, run Terraform inside automated CI/CD execution pipelines.

### 6.1 GitHub Actions Deployment Workflow (`.github/workflows/terraform.yml`)

```yaml
name: "Terraform Infrastructure Deployment"

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  terraform:
    name: "Terraform Validation & Plan"
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./environments/prod

    steps:
      - name: Checkout Code Repository
        uses: actions/checkout@v3

      - name: Setup Terraform CLI
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.7

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Initialize Backend & Providers
        run: terraform init
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Validate Configuration Syntax
        run: terraform validate

      - name: Generate Speculative Execution Plan
        run: terraform plan -no-color -out=tfplan
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Apply Infrastructure Changes
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -input=false tfplan
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

```

---

## 7. State Management & Troubleshooting Commands

Use these CLI workflows for manual inspections, resource import, and state operations:

```bash
# Refresh and sync state with actual cloud infrastructure
terraform refresh

# Import an existing unmanaged cloud resource into Terraform state
terraform import module.networking.aws_vpc.main vpc-0a1b2c3d4e5f6g7h8

# Inspect current state values
terraform state list
terraform state show module.networking.aws_vpc.main

# Move or rename resources within state without destroying them
terraform state mv aws_db_instance.postgresql module.database.aws_db_instance.postgresql

# Forcefully unlock state after a failed or interrupted execution pipeline
terraform force-unlock <LOCK-ID>

```
