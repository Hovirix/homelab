---
name: opentofu
description: Use for HX Lab OpenTofu work under infrastructure/opentofu/**, including stacks, modules, providers, state, imports, outputs, and validation.
---

# OpenTofu

Use this skill for changes under `infrastructure/opentofu/**`.

Read the relevant stack, module, provider configuration, variables, locals, outputs, and calling code before changing behavior. Follow the conventions already present in the touched stack or module.

Use upstream docs when resource semantics, imports, state handling, replacement behavior, backend behavior, provider behavior, or validation behavior matters:

- OpenTofu docs: https://opentofu.org/docs/
- OpenTofu language: https://opentofu.org/docs/language/
- OpenTofu CLI: https://opentofu.org/docs/cli/
- OpenTofu state: https://opentofu.org/docs/language/state/
- Provider registry: https://search.opentofu.org/provider

Prefer direct provider resources. Add modules only when they remove real repetition or define a durable boundary.

Keep stack boundaries explicit. Before changing resource names, module paths, `for_each` keys, provider aliases, VM IDs, DNS names, or storage identifiers, identify replacement risk, state movement, imports, and rollback impact.

Sensitive inputs should remain referenced through encrypted secret workflows or variables. Do not decrypt, print, or write plaintext secrets. Do not edit state files.

Validation should use formatting, validation, and plans only when safe and authorized. Local validation proves syntax and provider consistency, not successful deployment.
