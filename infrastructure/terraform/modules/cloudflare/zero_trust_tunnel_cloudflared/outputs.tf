output "id" {
  value = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "name" {
  value = cloudflare_zero_trust_tunnel_cloudflared.this.name
}

output "cname" {
  value = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
}
