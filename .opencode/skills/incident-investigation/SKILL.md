---
name: incident-investigation
description: Use when investigating slowness, outages, errors, restarts, alerts, or historical runtime behavior in HX Lab.
---

# Incident Investigation

When asked why a service was slow, unavailable, erroring, restarting, or unhealthy:

1. Resolve the exact service and requested time range.
2. Read repository configuration only when needed to identify:
   - stack/service names
   - dependencies
   - expected topology
3. Use Grafana MCP to discover actual metrics and Loki labels.
   Never invent metric names.
4. Inspect the affected service:
   - CPU
   - memory
   - throttling if available
   - network
   - I/O
   - restarts/OOM/state
5. Inspect the node hosting it:
   - CPU/load
   - CPU/memory/I/O PSI
   - memory availability
   - disk/filesystem
   - network errors
6. Inspect relevant dependencies only when evidence or topology points to them.
7. Query Loki around anomalous timestamps for:
   - errors
   - timeouts
   - retries
   - connection failures
8. Compare against a nearby healthy period when useful.
9. Correlate signals by timestamp.

Do not assume correlation proves causation.

Prefer multiple independent signals before identifying a likely cause.

## Output

Return:

### Finding

The most likely explanation in 1-2 sentences.

### Evidence

Only the strongest supporting observations with timestamps/values.

### Confidence

High / Medium / Low.

### Missing telemetry

Only include this when unavailable data materially limits the conclusion.
