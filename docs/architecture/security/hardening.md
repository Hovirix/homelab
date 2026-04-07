# Host Hardening

Standard hardening procedures for all hosts.

## Operating System

- Fedora CoreOS for production hosts
- Minimal installation with required packages only
- Automatic updates enabled

## Baseline Configuration

- Firewall (firewalld) enabled
- SELinux enforced
- SSH key-based authentication only
- Root login disabled
- Password authentication disabled

## Network Hardening

- Default deny all incoming traffic
- Only allow required ports
- ARP filtering enabled
- IP forwarding disabled where not needed

## Service Hardening

- Services run with minimal privileges
- Service accounts with no shell access
- Resource limits enforced

## Monitoring

- Audit logging enabled
- Failed login attempts logged
- Process activity monitoring
- File integrity monitoring
