# HX Lab

[![Explore the Architecture →](https://img.shields.io/badge/Explore%20the%20Architecture%20→-000000?style=for-the-badge&logo=mintlify&logoColor=18E299)](https://docs.nemnix.site)

Production-grade self-hosted infrastructure built entirely with Infrastructure-as-Code and docs-as-code.  
Powered by Proxmox VE, Fedora CoreOS, OpenWRT, and systemd-managed Podman containers.

## Tech Stack

[![Proxmox](https://img.shields.io/badge/Proxmox-E57000?style=for-the-badge&logo=proxmox&logoColor=white)](https://www.proxmox.com/)
[![Fedora CoreOS](https://img.shields.io/badge/Fedora_CoreOS-294172?style=for-the-badge&logo=fedora&logoColor=white)](https://fedoraproject.org/coreos)
[![OpenWRT](https://img.shields.io/badge/OpenWRT-00B5A4?style=for-the-badge&logo=openwrt&logoColor=white)](https://openwrt.org/)
[![OpenTofu](https://img.shields.io/badge/OpenTofu-FFDA18?style=for-the-badge&logo=opentofu&logoColor=black)](https://opentofu.org/)
[![Podman](https://img.shields.io/badge/Podman-892CA9?style=for-the-badge&logo=podman&logoColor=white)](https://podman.io/)
[![SOPS](https://img.shields.io/badge/SOPS-6C78AF?style=for-the-badge&logo=mozilla&logoColor=white)](https://getsops.io/)

## Repository Structure

```
.
├── docs/               # Mintlify documentation site
├── firmware/           # OpenWRT router builds
├── hosts/              # Butane/Ignition templates for VM provisioning
├── secrets/            # SOPS-encrypted secrets (age)
├── terraform/          # IaC configurations
├── flake.nix           # Nix dev shell
└── README.md
```

## Contributing

This is a personal homelab project. Discussions and ideas are welcome — open an issue to start a conversation.

## License

[MIT](./LICENSE)
