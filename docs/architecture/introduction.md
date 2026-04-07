# Introduction

The HX Lab is a personal self-hosted infrastructure for operating critical services and conducting security.
It is treated like production with different environments for testing and exploring purposes


## Architecture Stack

#### Networking: <img src="https://img.shields.io/badge/OpenWRT-00B5A4?logo=openwrt&logoColor=white"> <img src="https://img.shields.io/badge/Cloudflare-F38020?logo=cloudflare&logoColor=white"> <img src="https://img.shields.io/badge/Tailscale-242424?logo=tailscale&logoColor=white">

#### Compute: <img src="https://img.shields.io/badge/Proxmox-E57000?logo=proxmox&logoColor=white">

#### Storage: <img src="https://img.shields.io/badge/ZFS-000000?logo=openzfs&logoColor=white">

#### Identity: <img src="https://img.shields.io/badge/Authentik-FD4B2D?logo=authentik&logoColor=white">

## Design Principles

The objective is to have an "enterprise-grade" solution without the overhead of corporate processes. The system is designed as follows:

1. **Security by Design**:
  - Zero Trust model
  - Defense in Depth
  - Least Privilege
  - Network Segmentation

2. **Development**:
  - DevSecOps approach
  - GitOps workflow
  - Shift-left security
  - Immutable infrastructure

3. **Operations**:
  - Infrastructure as Code
  - Configuration as Code 
  - Declarative workloads
  - Automated deployments and reconciliation

4. **Reliability**:
  - Self-healing systems
  - Service isolation
  - Backup and recovery strategy
  - Minimal external dependencies

The HX Lab combines enterprise-grade practices with the flexibility of a self-hosted environment, ensuring security, reliability, and operational excellence.
