---
name: hxlab-feature
description: Implement and review HX Lab repository features using repository-first discovery, focused upstream research, safe Git-managed changes, deterministic validation, and independent verification.
---

# HX Lab Feature Workflow

Use this skill for feature implementation or feature review in the HX Lab homelab repository.

Do not use this workflow for:

- general questions that require no repository changes;
- incident investigation that does not involve modifying Git-managed state;
- documentation-only requests unless validation or operational behavior is affected.

## Workflow

```text
request
-> discover
-> define acceptance contract
-> research when necessary
-> implement
-> validate locally
-> independently verify
-> report final status
```

## Operating Principles

- Git is the source of truth.
- Inspect the repository before proposing paths, resources, commands, or abstractions.
- Prefer established repository conventions over new patterns.
- Make the smallest coherent change that satisfies the request.
- Do not modify unrelated files.
- Do not expose, print, or commit plaintext secrets.
- Do not edit generated files unless the repository explicitly expects generated output to be committed.
- Do not create permanent live state outside Git.
- Do not commit, push, merge, apply infrastructure, or mutate production systems unless the user explicitly requests it.
- Report pre-existing failures separately rather than silently fixing them.
- Verify repository commands and task names from the current checkout before using them.

## Discover

Extract the desired outcome, constraints, affected domain, expected observable behavior, and safety risks.

Inspect relevant nearby files before editing. Determine:

- which domain owns the work;
- where comparable components are implemented;
- how secrets are referenced;
- which files are generated;
- which Taskfile or repository commands validate the affected area;
- whether the working tree contains unrelated changes.

## Acceptance Contract

Before editing, define:

- intended outcome;
- files or areas expected to change;
- local validation commands;
- security or production risks;
- conditions that require user approval.

## Implement

- Make the smallest coherent Git-managed change.
- Reuse nearby patterns.
- Preserve naming and directory conventions.
- Avoid unrelated refactoring.
- Add documentation only where it provides operational value.
- Preserve rollback feasibility where practical.

## Validate Locally

Always run:

```bash
git status --short
git diff --check
git diff
```

Also run relevant repository checks for the affected domain, preferring existing Taskfile targets over reconstructed commands.

For every validation command, record:

- exact command;
- result;
- relevant failure details;
- whether the failure was introduced by the current change.

## Independent Verification

Use a separate verifier agent or a fresh verification pass when the change is non-trivial.

The verifier should inspect the original request, acceptance contract, complete diff, relevant surrounding files, deterministic checks, scope control, and security implications.

Findings must be ordered by severity:

- Blocker
- High
- Medium
- Low

Finish with exactly one verdict:

```text
READY FOR REVIEW
CHANGES REQUIRED
BLOCKED BY MISSING INFORMATION
```

## Final Report

Report:

- outcome;
- files changed;
- validation commands and results;
- independent verification verdict when performed;
- assumptions;
- pre-existing failures;
- residual risks;
- suggested commit message when useful.
