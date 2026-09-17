# Chapter 5: Advanced Infrastructure Automation & Orchestration with Ansible

This chapter provides a practical, enterprise-grade guide to mastering Ansible for infrastructure automation. It covers inventory architecture, role modularization, dynamic secret handling, custom filter development, and execution environment patterns.

---

## 1. Advanced Inventory Management & Dynamic Inventories

In enterprise production, static inventory files (`hosts.ini`) are replaced by dynamic inventories and multi-layered inventory hierarchies to handle ephemeral nodes and multi-region infrastructure.

### 1.1 Multi-Environment Directory Structure

Organize inventories by environment to isolate variables and prevent configuration drift:

```text
inventory/
├── production/
│   ├── group_vars/
│   │   ├── all.yml
│   │   ├── webservers.yml
│   │   └── dbservers.yml
│   ├── host_vars/
│   │   └── db-prod-01.yml
│   └── hosts.yaml
└── staging/
    ├── group_vars/
    │   └── all.yml
    └── hosts.yaml

```

### 1.2 Writing a Custom Dynamic Inventory Plugin in Python

When third-party CMDBs or proprietary cloud APIs are used, custom dynamic inventory plugins parse real-time metadata into Ansible-compliant JSON.

Create `plugins/inventory/custom_cmdb.py`:

```python
#!/usr/bin/env python3
"""
Custom Dynamic Inventory Plugin for Enterprise CMDB
"""

import json
import argparse
import sys

def build_inventory():
    return {
        "webservers": {
            "hosts": ["192.168.10.11", "192.168.10.12"],
            "vars": {
                "ansible_user": "automation",
                "http_port": 8080
            }
        },
        "dbservers": {
            "hosts": ["192.168.10.21"],
            "vars": {
                "ansible_user": "automation",
                "db_port": 5432
            }
        },
        "_meta": {
            "hostvars": {
                "192.168.10.11": {
                    "ansible_host": "192.168.10.11",
                    "datacenter": "us-east-1"
                },
                "192.168.10.12": {
                    "ansible_host": "192.168.10.12",
                    "datacenter": "us-east-1"
                },
                "192.168.10.21": {
                    "ansible_host": "192.168.10.21",
                    "datacenter": "us-west-2"
                }
            }
        }
    }

def main():
    parser = argparse.ArgumentParser(description="Custom CMDB Inventory Script")
    parser.add_argument("--list", action="store_true", help="List active hosts")
    parser.add_argument("--host", action="store", help="Host detail lookup")
    args = parser.parse_args()

    if args.list:
        print(json.dumps(build_inventory(), indent=2))
    elif args.host:
        # Return empty dictionary if hostvars are handled in _meta
        print(json.dumps({}))
    else:
        print(json.dumps({}))

if __name__ == "__main__":
    main()

```

Make the script executable and test execution:

```bash
chmod +x plugins/inventory/custom_cmdb.py
ansible-inventory -i plugins/inventory/custom_cmdb.py --list

```

---

## 2. Production Ansible Role Architecture

Roles enforce code reusability, modular structure, and clean variable precedence.

### 2.1 Role Directory Scaffold

Standard Ansible role hierarchy for a hardened Web Application firewall and proxy (`nginx_hardened`):

```text
roles/nginx_hardened/
├── defaults/
│   └── main.yml        # Lowest precedence default variables
├── vars/
│   └── main.yml        # Role-specific locked variables
├── tasks/
│   ├── main.yml        # Primary execution entry point
│   ├── install.yml     # Package installation steps
│   └── configure.yml   # Template and service configuration
├── templates/
│   └── nginx.conf.j2   # Jinja2 template for configuration
├── handlers/
│   └── main.yml        # Idempotent service restart triggers
└── meta/
    └── main.yml        # Role dependencies and metadata

```

### 2.2 Task Decomposition & Handler Triggering

`roles/nginx_hardened/defaults/main.yml`:

```yaml
---
nginx_worker_processes: "auto"
nginx_worker_connections: 1024
nginx_client_max_body_size: "10M"
nginx_tls_protocols: "TLSv1.2 TLSv1.3"

```

`roles/nginx_hardened/handlers/main.yml`:

```yaml
---
- name: Validate Nginx configuration
  ansible.builtin.command:
    cmd: nginx -t
  register: nginx_check
  changed_when: false
  listen: "reload nginx"

- name: Reload Nginx service
  ansible.builtin.systemd:
    name: nginx
    state: reloaded
  when: nginx_check.rc == 0
  listen: "reload nginx"

```

`roles/nginx_hardened/tasks/main.yml`:

```yaml
---
- name: Install required dependencies
  ansible.builtin.package:
    name:
      - nginx
      - ca-certificates
    state: present

- name: Deploy secure Nginx configuration template
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
    validate: 'nginx -t -c %s'
  notify: "reload nginx"

- name: Ensure Nginx is started and enabled
  ansible.builtin.systemd:
    name: nginx
    state: started
    enabled: true

```

---

## 3. Dynamic Secrets Management with HashiCorp Vault Integration

Hardcoding sensitive credentials in source control introduces critical vulnerabilities. Integrating Ansible with HashiCorp Vault or Ansible Vault allows dynamic runtime secret decryption.

### 3.1 Ansible Vault CLI Operations

Create and manage encrypted variable files using Ansible Vault:

```bash
# Encrypt an existing secret variable file
ansible-vault encrypt group_vars/production/vault.yml --vault-password-file .vault_pass

# View encrypted contents without modifying
ansible-vault view group_vars/production/vault.yml --vault-password-file .vault_pass

# Re-key vault file with new passphrase
ansible-vault rekey group_vars/production/vault.yml --vault-password-file .vault_pass

```

### 3.2 Dynamic Lookup via HashiCorp Vault API

Lookup dynamic database passwords from HashiCorp Vault at runtime without storing secrets on disk:

```yaml
---
- name: Deploy App Server with HashiCorp Vault Credentials
  hosts: appservers
  gather_facts: false
  vars:
    db_credentials: "{{ lookup('community.hashi_vault.vault_kv2_get', 'secret/data/production/database', url='https://vault.internal:8200', engine_version=2) }}"

  tasks:
    - name: Configure database connection string
      ansible.builtin.template:
        src: db_config.j2
        dest: /opt/app/config/db.json
        owner: appuser
        group: appuser
        mode: '0600'
      no_log: true # Prevents secret output from leaking in log files

```

---

## 4. Custom Jinja2 Filter Development

Custom Python filters allow data transformations, network sub-calculations, or policy validation directly inside playbooks.

### 4.1 Filter Implementation

Create `filter_plugins/network_filters.py`:

```python
#!/usr/bin/env python3
"""
Custom Jinja2 Filters for Enterprise Ansible Automation
"""

import ipaddress

def to_cidr_mask(ip_with_prefix):
    """Converts IP/prefix notation to Subnet Mask (e.g. 192.168.1.0/24 -> 255.255.255.0)"""
    try:
        net = ipaddress.ip_network(ip_with_prefix, strict=False)
        return str(net.netmask)
    except ValueError as e:
        raise ValueError(f"Invalid IP/Prefix provided to to_cidr_mask: {e}")

def sanitize_hostname(raw_string):
    """Sanitizes string into standard RFC 1123 compliant hostname"""
    import re
    sanitized = re.sub(r'[^a-zA-Z0-9-]', '-', raw_string).lower()
    return sanitized.strip('-')

class FilterModule(object):
    def filters(self):
        return {
            'to_cidr_mask': to_cidr_mask,
            'sanitize_hostname': sanitize_hostname
        }

```

### 4.2 Playbook Filter Execution

```yaml
---
- name: Test Custom Filter Pipeline
  hosts: localhost
  gather_facts: false
  vars:
    raw_node_name: "Prod_Web-Node#01_US-East"
    ip_subnet: "10.240.0.0/20"

  tasks:
    - name: Transform inputs using custom filters
      ansible.builtin.debug:
        msg:
          - "Original Name: {{ raw_node_name }}"
          - "Sanitized Hostname: {{ raw_node_name | sanitize_hostname }}"
          - "IP Subnet: {{ ip_subnet }}"
          - "Subnet Mask: {{ ip_subnet | to_cidr_mask }}"

```

---

## 5. Enterprise Execution Environments & Ansible Builder

Modern automation builds containerized execution environments using `ansible-builder` to eliminate dependency conflicts across CI/CD workers and Ansible Automation Controller nodes.

### 5.1 Execution Environment Definition

Create `execution-environment.yml`:

```yaml
version: 3
images:
  base_image:
    name: registry.redhat.io/ansible-automation-platform-24/ee-minimal-rhel9:latest

dependencies:
  galaxy:
    collections:
      - name: community.general
      - name: community.hashi_vault
      - name: containers.podman
  python:
    - hvac>=1.2.0
    - netaddr>=0.8.0
    - psycopg2-binary
  system:
    - openssl-devel
    - libcurl-devel
    - gcc

additional_build_steps:
  prepend_builder:
    - RUN pip install --upgrade pip
  append_final:
    - RUN echo "Container Execution Environment Build Complete"

```

### 5.2 Building and Deploying the EE Image

Build the container image using `ansible-builder` and Podman:

```bash
# Build the EE image
ansible-builder build --tag enterprise-ee:v1.0.0 -v 3

# Test collection availability inside the local execution environment container
podman run --rm enterprise-ee:v1.0.0 ansible-doc community.hashi_vault.vault_kv2_get

# Push image to enterprise registry
podman tag enterprise-ee:v1.0.0 registry.internal/automation/enterprise-ee:v1.0.0
podman push registry.internal/automation/enterprise-ee:v1.0.0

```

---

## 6. End-to-End Orchestration Playbook

This playbook ties together dynamic variable resolution, custom filters, vault secrets, role execution, and error handling with blocks and rescue loops.

```yaml
---
- name: Enterprise Infrastructure Provisioning & Hardening Pipeline
  hosts: webservers
  become: true
  strategy: linear
  vars_files:
    - "group_vars/{{ env | default('staging') }}/vault.yml"

  pre_tasks:
    - name: Validate system requirements
      ansible.builtin.assert:
        that:
          - ansible_memtotal_mb >= 2048
          - ansible_distribution in ["RedHat", "CentOS", "Rocky", "Debian", "Ubuntu"]
        fail_msg: "Host does not meet deployment minimum requirements."

  tasks:
    - name: Execute Infrastructure Deployment Block
      block:
        - name: Apply Nginx Hardened Role
          ansible.builtin.include_role:
            name: nginx_hardened

        - name: Configure Application Firewall Parameters
          ansible.builtin.template:
            src: templates/waf_policy.j2
            dest: /etc/nginx/conf.d/waf.conf
            owner: root
            group: root
            mode: '0640'
          notify: "reload nginx"

      rescue:
        - name: Log deployment failure
          ansible.builtin.debug:
            msg: "Deployment failed on {{ inventory_hostname }}. Initiating rollback tasks..."

        - name: Restore backup configuration
          ansible.builtin.copy:
            src: /var/backups/nginx.conf.bak
            dest: /etc/nginx/nginx.conf
            remote_src: true
          ignore_errors: true

        - name: Notify SOC / Slack Channel
          community.general.slack:
            token: "{{ vault_slack_token }}"
            channel: "#infra-alerts"
            msg: "Deployment failed on node {{ inventory_hostname }}. Immediate attention required."
          delegate_to: localhost

      always:
        - name: Verify service uptime state
          ansible.builtin.uri:
            url: "http://localhost:8080/healthz"
            status_code: 200
          register: health_check
          until: health_check.status == 200
          retries: 3
          delay: 5

```
