---
name: taskfile
description: Use for Taskfile and operations workflow work under Taskfile.yml and operations/**, including local validation, wrappers, diagnostics, and CI entrypoints.
---

# Taskfile

Use this for changes to `Taskfile.yml`, `operations/**`, workflow wrappers, local validation, diagnostics, and CI orchestration.

Read the relevant included taskfile, script, workflow, and root `Taskfile.yml` before changing behavior. Keep tasks thin and predictable. Move complex shell logic into scripts only when Taskfile syntax becomes unclear. Always follow the Task Style guide.

Use upstream docs when Taskfile behavior, variable expansion, includes, loops, status checks, or command execution semantics matter:

- Task documentation: https://taskfile.dev/
- Task style guide: https://taskfile.dev/docs/styleguide
- Task schema reference: https://taskfile.dev/reference/schema/

Taskfile is the operational interface. It should wrap desired-state tools safely; it should not hide destructive behavior or imply runtime success from local checks.

Treat remote execution, apply/destroy/import/state movement, Swarm mutation, service restarts, secret decryption, and backup/restore execution as explicit-authorization workflows.

Validation should use current task entrypoints when they exist. Inspect `task --list` when task availability is unclear. Report exactly what ran and what was skipped.

Watch for failure modes such as masked shell-loop failures, unsafe variable interpolation, missing fail-fast behavior, remote drift, and tasks whose names make mutating operations look read-only.
