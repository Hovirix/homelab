package main

deny contains msg if {
  some name
  service := input.services[name]
  service.privileged == true
  msg := sprintf("service %q must not be privileged", [name])
}

deny contains msg if {
  some name
  service := input.services[name]
  service.network_mode == "host"
  msg := sprintf("service %q must not use host networking", [name])
}

deny contains msg if {
  some name
  service := input.services[name]
  not contains(service.image, "@sha256:")
  msg := sprintf("service %q image must be pinned by digest", [name])
}

deny contains msg if {
  some name
  service := input.services[name]
  mount := service.volumes[_]
  docker_socket_mount(mount)
  not allowed_socket_mount(name, mount)
  msg := sprintf("service %q must not mount the Docker socket", [name])
}

deny contains msg if {
  some name
  service := input.services[name]
  mount := service.volumes[_]
  docker_socket_mount(mount)
  not socket_read_only(mount)
  msg := sprintf("service %q Docker socket mount must be read-only", [name])
}

deny contains msg if {
  some name
  service := input.services[name]
  port := service.ports[_]
  not allowed_port(name, service, port)
  msg := sprintf("service %q must not publish host ports", [name])
}

deny contains msg if {
  some name
  service := input.services[name]
  secret := service.secrets[_]
  secret_name := service_secret_name(secret)
  not input.secrets[secret_name].external
  msg := sprintf("service %q secret %q must be an external Swarm secret", [name, secret_name])
}

deny contains msg if {
  secret_name := object.keys(input.secrets)[_]
  not input.secrets[secret_name].external
  msg := sprintf("secret %q must use the external Swarm secret model", [secret_name])
}

deny contains msg if {
  some name
  service := input.services[name]
  key := object.keys(service.environment)[_]
  secret_environment_key(key)
  not endswith(key, "_URL")
  not endswith(key, "_FILE")
  value := service.environment[key]
  is_string(value)
  not startswith(value, "/run/secrets/")
  not startswith(value, "file:///run/secrets/")
  msg := sprintf("service %q environment variable %q must reference a Swarm secret", [name, key])
}

docker_socket_mount(mount) if {
  is_string(mount)
  startswith(mount, "/var/run/docker.sock:")
}

docker_socket_mount(mount) if {
  mount.type == "bind"
  mount.source == "/var/run/docker.sock"
}

# Alloy needs a local read-only socket for node-local Docker discovery and logs.
allowed_socket_mount(name, mount) if {
  name == "socket-proxy"
  socket_read_only(mount)
}

allowed_socket_mount(name, mount) if {
  name == "alloy"
  socket_read_only(mount)
}

socket_read_only(mount) if {
  is_string(mount)
  endswith(mount, ":ro")
}

socket_read_only(mount) if {
  mount.read_only == true
}

allowed_port(name, service, port) if {
  startswith(service.image, "traefik:")
  name == "proxy"
  port.target == 80
  port.published == 80
}

allowed_port(name, service, port) if {
  startswith(service.image, "traefik:")
  name == "proxy"
  port.target == 443
  port.published == 443
}

service_secret_name(secret) := secret if is_string(secret)

service_secret_name(secret) := secret.source if {
  is_object(secret)
  secret.source
}

secret_environment_key(key) if regex.match("(?i)(password|secret|token|api_key)", key)
