This text-based diagram provides a simplified, comparative overview of the two primary container orchestration ecosystems covered by the LPIC-701 exam objectives: **Docker Swarm** and **Kubernetes**.

The diagram visualizes how these systems differ structurally, moving from the high-level management engine down to the operational nodes and functional primitives.

---

### Tier 1: Core Orchestration Engines

This tier separates the fundamental management philosophies of the two systems.

#### 1. Docker Swarm Engine (Raft Consensus & Tasks)

* **Engine Type:** This represents the built-in orchestration capabilities native to the Docker Engine. If you have Docker installed, you have the Swarm engine.
* **Key Concept (Raft Consensus):** Swarm Managers use the Raft Consensus Algorithm to agree on the cluster's state (which services are running, how many replicas, which nodes are healthy). This ensures high availability and state consistency among the management tier.
* **Key Concept (Tasks):** In Swarm, the atomic unit of scheduling is a **Task**. A Task is the combination of a Docker container and the commands required to run it, as dispatched by a manager to a worker node.

#### 2. Kubernetes Control Plane

* **Engine Type:** This represents the "brain" or the central management assembly of a Kubernetes cluster. Kubernetes is typically distinct from the underlying container runtime (like `containerd`).
* **Key Concept (Control Plane):** This is a collection of distinct components (running on master nodes) responsible for maintaining the desired state of the cluster. It handles scheduling, responding to cluster events, and managing the API.

---

### Tier 2: Components and Primitives

This tier illustrates the building blocks used by each engine to execute workloads and manage resources.

#### Docker Swarm Components

1. **Manager / Worker Nodes:**
* **Architecture:** Swarm has a straightforward node-role distinction.
* **Manager Nodes:** Handle cluster management tasks, accept API requests, and maintain the Raft quorum.
* **Worker Nodes:** Receive and execute tasks (containers) from the managers. By default, Managers also act as Workers.


2. **Overlay Routing Mesh:**
* **Networking:** This is Swarm’s powerful, embedded ingress networking feature.
* **Function:** It creates a routing network spanning every node in the Swarm. It allows a service to be reached on its published port on *any* node in the cluster, regardless of which node is actually hosting the running container task. The traffic is automatically routed internally to the correct task.



#### Kubernetes Components

1. **Kube-API / etcd:**
* **Kube-API Server:** The front-end validation and configuration hub of the control plane. All components (kubectl, workers, internal controllers) communicate only with the API server.
* **etcd:** The cluster’s critical "source of truth." It is a distributed, consistent key-value store that holds all cluster data—configuration, state, secrets, and taints. Losing etcd means losing the cluster configuration.


2. **Pods, Services & Deploy:**
* **Primitives:** These represent the primary API Objects defined in Kubernetes YAML manifests that users interact with.
* **Pod:** The smallest deployable unit in Kubernetes (one or more tightly coupled containers).
* **Service:** A stable network abstraction that provides an IP address and load balancing for a dynamic set of backend Pods.
* **Deployment:** A higher-level controller used to declaratively manage Pods and ReplicaSets, handling scaling, rolling updates, and self-healing.
