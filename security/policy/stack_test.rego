package main

sha := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

app_image := sprintf("example/app:1.0@sha256:%s", [sha])
traefik_image := sprintf("traefik:v3@sha256:%s", [sha])
socket_image := sprintf("example/socket-proxy:1@sha256:%s", [sha])

test_allows_compliant_stack if {
  violations := deny with input as compliant_stack
  count(violations) == 0
}

test_denies_privileged_containers if {
  deny with input as object.union(compliant_stack, {"services": {"app": {"image": app_image, "privileged": true}}})
}

test_denies_unapproved_capabilities if {
  deny with input as {
    "services": {
      "app": {
        "cap_add": ["SYS_ADMIN"],
        "image": app_image,
      },
    },
  }
}

test_denies_unapproved_explicit_root_user if {
  deny with input as {
    "services": {
      "app": {
        "image": app_image,
        "user": "0:0",
      },
    },
  }
}

test_denies_unpinned_images if {
  deny with input as {"services": {"app": {"image": "example/app:1.0"}}}
}

test_denies_non_ingress_ports if {
  deny with input as {"services": {"app": {"image": app_image, "ports": [{"target": 8080, "published": 8080}]}}}
}

test_denies_plaintext_secret_environment if {
  deny with input as {"services": {"app": {"image": app_image, "environment": {"APP_TOKEN": "plaintext"}}}}
}

compliant_stack := {
  "services": {
    "proxy": {
      "image": traefik_image,
      "ports": [
        {"target": 80, "published": 80},
        {"target": 443, "published": 443},
      ],
    },
    "socket-proxy": {
      "image": socket_image,
      "volumes": ["/var/run/docker.sock:/var/run/docker.sock:ro"],
    },
    "app": {
      "image": app_image,
      "secrets": ["app_token"],
      "environment": {"APP_TOKEN_FILE": "/run/secrets/app_token"},
    },
  },
  "secrets": {"app_token": {"external": true}},
}
