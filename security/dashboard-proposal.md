# Vulnerability dashboard proposal

## Goal

Show repository-image vulnerabilities in Grafana, with current findings, historical snapshots and lightweight trends.

## Context

GitHub-hosted CI generates vulnerability reports, but Grafana cannot directly consume Actions artifact ZIPs. Publishing dashboard-ready JSON in Git avoids an importer, another database or inbound access to the homelab.

## Approach

- Publish append-only JSON snapshots to a dedicated security-reports branch, named with UTC timestamp, Actions run ID and run attempt.
- Maintain an index for latest complete snapshot, historical selection and compact trend summaries.
- Read reports through Grafana Infinity using the GitHub Contents API; use repository-scoped read-only credentials if required.
- Include source commit, scanner/database timestamps, image digests, coverage, findings and exception status in a versioned report schema.
- Display findings, severity, fix availability, exceptions, coverage and freshness. Label the scope as repository inventory, not verified production state.
- Keep PR previews separate and preserve the existing security gate.

## Done when

- Grafana displays the latest report and can select historical snapshots.
- Snapshot and index publication is atomic; overlapping runs cannot overwrite snapshots or move latest backwards.
- Complete scans publish even when vulnerabilities fail the security gate.
- Failed or incomplete scans do not advance latest; stale or unavailable data never appears as zero findings.
- Report size and query performance are verified in the deployed Grafana before considering implementation complete.

This is a proposal only; implementation belongs to the coding agent.
