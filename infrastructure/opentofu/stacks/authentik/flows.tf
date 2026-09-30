data "authentik_flow" "authorization" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "authentication" {
  slug = "default-authentication-flow"
}

data "authentik_flow" "invalidation" {
  slug = "default-provider-invalidation-flow"
}
