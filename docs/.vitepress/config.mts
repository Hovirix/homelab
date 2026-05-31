import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'

export default defineConfig({
  title: "HX Lab",
  description: "Production-grade, self-hosted infrastructure built entirely with Infrastructure as Code and Docs as Code.",
  head: [
    ['link', { rel: 'icon', href: '/logo.ico' }]
  ],

  markdown: {
    config(md) {
      md.use(tabsMarkdownPlugin)
    },
  },

  themeConfig: {
    logo: '/logo.png',
    nav: [
      { text: "Architecture", link: "/architecture/introduction" },
      { text: "Platform", link: "/platform/overview" },
      { text: "Operations", link: "/operations/overview" }
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/Hovirix/homelab" }
    ],

    search: {
      provider: "local"
    },

    sidebar: {
      "/architecture/": [
        { text: "Introduction", link: "/architecture/introduction" },
        {
          text: "Networking",
          collapsed: false,
          items: [
            { text: "Overview", link: "/architecture/networking/overview" },
            { text: "Segmentation & Addressing", link: "/architecture/networking/segmentation" },
            { text: "Traffic Flows", link: "/architecture/networking/traffic-flows" },
            { text: "Security & Controls", link: "/architecture/networking/security" }
          ]
        },
        {
          text: "Compute",
          collapsed: false,
          items: [
            { text: "Overview", link: "/architecture/compute" }
          ]
        },
        {
          text: "Storage",
          collapsed: false,
          items: [
            { text: "Overview", link: "/architecture/storage" }
          ]
        },
        {
          text: "Identity & Access",
          collapsed: false,
          items: [
            { text: "Identity Architecture", link: "/architecture/iam/identity-architecture" },
            { text: "Authentication Flows", link: "/architecture/iam/authentication-flows" }
          ]
        },
        {
          text: "Security",
          collapsed: false,
          items: [
            { text: "Segmentation Model", link: "/architecture/security/segmentation" },
            { text: "Threat Model", link: "/architecture/security/threat-model" },
            { text: "Host Hardening", link: "/architecture/security/hardening" },
            { text: "Zero Trust Design", link: "/architecture/security/zero-trust" }
          ]
        },
        {
          text: "Observability",
          collapsed: false,
          items: [
            { text: "Overview", link: "/architecture/observability" }
          ]
        }
      ],

      "/platform/": [
        { text: "Overview", link: "/platform/overview" },
        { text: "OpenWRT", link: "/platform/network-os/openwrt" },
        {
          text: "Provisioning",
          collapsed: false,
          items: [
            { text: "OpenTofu", link: "/platform/provisioning/opentofu" },
            { text: "Proxmox", link: "/platform/provisioning/proxmox" }
          ]
        },
        {
          text: "Configuration",
          collapsed: false,
          items: [
            { text: "Ansible", link: "/platform/configuration/ansible" },
            { text: "Fedora Hosts", link: "/platform/configuration/fedora" }
          ]
        },
        {
          text: "Security Tooling",
          collapsed: false,
          items: [
            { text: "Secrets Management (SOPS)", link: "/platform/security/sops" },
            { text: "Scanning (Trivy & Gitleaks)", link: "/platform/security/scanning" }
          ]
        },
        {
          text: "Workloads",
          collapsed: false,
          items: [
            { text: "Container Strategy (Podman)", link: "/platform/workloads/podman" },
            { text: "Core Services", link: "/platform/workloads/services" }
          ]
        }
      ],

      "/operations/": [
        { text: "Overview", link: "/operations/overview" },
        {
          text: "Runbooks",
          collapsed: false,
          items: [
            { text: "Restore from Backup", link: "/operations/runbooks/restore" },
            { text: "Certificate Rotation", link: "/operations/runbooks/cert-rotation" },
            { text: "Node Replacement", link: "/operations/runbooks/node-replacement" }
          ]
        },
        {
          text: "Maintenance",
          collapsed: false,
          items: [
            { text: "Patch Strategy", link: "/operations/maintenance/patching" },
            { text: "Upgrade Procedures", link: "/operations/maintenance/upgrades" }
          ]
        },
        {
          text: "Backup & Recovery",
          collapsed: false,
          items: [
            { text: "Backup Strategy", link: "/operations/backup/strategy" },
            { text: "Restore Testing", link: "/operations/backup/testing" }
          ]
        }
      ]
    }
  }
})
