---
description: Investigate an HX Lab problem without making changes
agent: plan
---

$ARGUMENTS

Investigate using the relevant repository desired state and read-only runtime evidence.

Prefer Grafana metrics and Loki logs for runtime incidents when relevant. Distinguish observed facts from hypotheses and do not infer runtime state from configuration.

Do not mutate systems or access secret values.

Return the likely cause, strongest evidence, confidence, and next action.
