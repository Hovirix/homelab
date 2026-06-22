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
      { text: "Home", link: "/" },
      { text: "Architecture", link: "/architecture/" },
      { text: "Infrastructure", link: "/infrastructure/" },
      { text: "Operations", link: "/operations/" }
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/Hovirix/homelab" }
    ],

    search: {
      provider: "local"
    },

    sidebar: {
      "/architecture/": [
        { text: "Overview", link: "/architecture/" }
      ],

      "/infrastructure/": [
        { text: "Overview", link: "/infrastructure/" },
        {
          text: "Ansible",
          collapsed: false,
          items: [
            { text: "Overview", link: "/infrastructure/ansible/" },
            { text: "Inventory", link: "/infrastructure/ansible/inventory" },
            { text: "Playbooks", link: "/infrastructure/ansible/playbooks" },
            { text: "Roles", link: "/infrastructure/ansible/roles" }
          ]
        },
        {
          text: "OpenTofu",
          collapsed: false,
          items: [
            { text: "Overview", link: "/infrastructure/opentofu/" },
            { text: "Proxmox", link: "/infrastructure/opentofu/stacks/proxmox" },
            { text: "Cloudflare", link: "/infrastructure/opentofu/stacks/cloudflare" },
            { text: "Authentik", link: "/infrastructure/opentofu/stacks/authentik" },
            { text: "AdGuard Home", link: "/infrastructure/opentofu/stacks/adguardhome" },
            { text: "State Encryption", link: "/infrastructure/opentofu/state-encryption" }
          ]
        },
        { text: "Secrets", link: "/infrastructure/secrets" }
      ],

      "/operations/": [
        { text: "Overview", link: "/operations/" },
        {
          text: "Runbooks",
          collapsed: false,
          items: [
            { text: "Proxmox API Token", link: "/operations/runbooks/proxmox-api-token" },
            { text: "TrueNAS SCALE Setup", link: "/operations/runbooks/truenas" },
            { text: "Wake on LAN", link: "/operations/runbooks/wake-on-lan" }
          ]
        }
      ]
    }
  }
})
