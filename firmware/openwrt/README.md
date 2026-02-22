# Homelab OpenWRT
This is my current repo for building my OpenWRT images for my GL-Net Flint 2 router, only packages and simple custom configs are added, the rest of the configuration is made with the [LuCI](https://github.com/openwrt/luci/wiki)

## Installation
```bash
git clone https://github.com/Hovirix/homelab-openwrt.git
cd homelab-openwrt
nix develop
just build
```
then flash the image on the router

## Tasks

- [ ] Setup Wireguard
- [ ] Setup VLAN & Segmentation
- [ ] Firewall Policy (fine-tuned)
- [ ] DMZ Setup
- [ ] Monitoring & Observability
- [ ] Security Hardening
