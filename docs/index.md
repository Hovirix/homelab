---
layout: home

hero:
  name: "HX Lab"
  text: "The Self-Hosted DevSecOps Platform"
  tagline: "Security-focused infrastructure, designed and operated like production."
  
  image:
    src: /logo.png
    alt: HX Lab logo
    
  actions:
    - theme: brand
      text: View Architecture
      link: /architecture/overview
    - theme: alt
      text: GitHub
      link: https://github.com/Hovirix/homelab

features:
  - icon: 🌐
    title: Networking
    details: Segmented VLAN architecture, routing, DNS control, and secure service exposure across internal and external boundaries.
    link: /architecture/networking/overview

  - icon: 🪪
    title: Identity
    details: Centralized identity and authentication flows using Authentik, with controlled access across services and environments.
    link: /architecture/iam/identity-architecture

  - icon: 🛡️
    title: Security
    details: Zero trust design, host hardening, threat modeling, and continuous scanning with DevSecOps tools.
    link: /architecture/security/threat-model

  - icon: 🖥️
    title: Platform
    details: Infrastructure provisioning with OpenTofu, configuration via Ansible, and containerized workloads using Podman.
    link: /platform/overview
---
