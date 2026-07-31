---
name: hxlab-feature
description: Implement, review, reconcile, and verify HX Lab repository features using repository-first discovery, focused upstream research, GitOps-safe changes, deterministic validation, independent verification, and explicit live acceptance checks.
---

# HX Lab feature workflow

Use this skill for feature implementation, feature review, GitOps reconciliation, or post-reconciliation verification in the HX Lab homelab repository.

Do not use this workflow for:

- general questions that require no repository changes;
- incident investigation that does not involve modifying Git-managed state;
- documentation-only requests unless validation or deployment behavior is affected;
- reconciliation requests unrelated to an implemented or reviewed feature.

## Workflow

```text
request
→ discover
→ define acceptance contract
→ research when necessary
→ implement
→ validate locally
→ independently verify
→ user publishes Git revision
→ reconcile with approval
→ verify live behavior
→ report final status
```

## Operating principles

- Git is the source of truth.
- Inspect the repository before proposing paths, resources, commands, or abstractions.
- Prefer established repository conventions over new patterns.
- Make the smallest coherent change that satisfies the request.
- Do not modify unrelated files.
- Do not expose, print, or commit plaintext secrets.
- Do not edit generated files unless the repository explicitly expects generated output to be committed.
- Do not create permanent live state outside Git.
- Do not repair GitOps-managed resources through imperative cluster mutations.
- Do not commit, push, merge, or reconcile unless the user explicitly requests the relevant action.
- Report pre-existing failures separately rather than silently fixing them.
- Do not claim completion while required live checks remain pending.
- Verify repository commands and task names from the current checkout before using them.
- Use specialized agents only when they are available and materially improve the result.

# Phase 1: Discover

## 1.1 Understand the request

Extract:

- desired outcome;
- explicit requirements;
- constraints;
- affected environment;
- expected observable behavior;
- security, availability, migration, or data risks;
- decisions that cannot safely be inferred.

Translate vague requests into observable completion conditions.

Example:

```text
Weak:
Install external-dns.

Observable:
- external-dns is declared through the repository's existing Flux structure;
- the deployment follows the repository's namespace and dependency conventions;
- credentials use the existing secret-management pattern;
- required source types are enabled;
- relevant local validation passes;
- Flux reports the affected resources ready;
- a representative source resource produces the expected DNS record.
```

Do not stop for minor missing details. Infer reasonable defaults from repository conventions and record those assumptions.

Request user input only when a missing decision materially affects:

- architecture;
- external exposure;
- authentication or authorization;
- trust boundaries;
- secret handling;
- destructive behavior;
- data migration;
- downtime;
- rollback feasibility.

## 1.2 Inspect the repository

Before proposing implementation details, determine:

- which domain owns the feature;
- where comparable components are implemented;
- how the target environment or cluster is wired;
- how Flux, Helm, Kustomize, namespaces, dependencies, and versions are structured;
- how secrets are referenced;
- which files are generated;
- which Taskfile or repository commands validate the affected area;
- whether the working tree contains unrelated changes.

Inspect relevant nearby files, not only filenames returned by search.

Repository evidence should answer questions such as:

- Where should the feature live?
- What is the closest existing pattern?
- How are dependencies expressed?
- How are Helm values organized?
- How are namespaces and service accounts created?
- Which validation target covers this area?
- Which branch or revision does Flux observe?
- What rollback pattern is already used?

Do not invent a new repository convention until existing patterns have been checked.

Use a repository exploration agent when available and when broad or parallel inspection would materially improve discovery.

# Phase 2: Define the acceptance contract

Before editing, establish a concise implementation contract.

## Outcome

Describe the intended result in one or two sentences.

## Completion conditions

Define observable conditions in five categories.

### Repository state

Examples:

- required manifests or modules exist in the correct domain;
- environment wiring includes the feature;
- versions and dependencies follow repository conventions;
- no unrelated files are changed;
- no plaintext secrets are present.

### Local validation

Examples:

- repository validation targets pass;
- rendered manifests build successfully;
- schemas validate;
- formatting and static checks pass;
- the final diff passes inspection.

### GitOps readiness

Examples:

- Flux dependencies are explicit;
- required namespaces, sources, releases, and secrets are referenced correctly;
- the intended Git revision is published to the branch observed by Flux.

### Workload health

Examples:

- affected Kustomizations and HelmReleases become ready;
- expected workloads become available;
- events and logs show no feature-related failure.

### Functional acceptance

Examples:

- DNS records resolve;
- a route is accepted and serves traffic;
- a claim binds and preserves data;
- metrics appear in the expected query;
- an authentication flow succeeds;
- a backup or restore operation produces the expected result.

A healthy pod alone is not functional acceptance.

## Plan

Record:

- files or areas expected to change;
- repository patterns being followed;
- upstream questions requiring confirmation;
- local validation commands;
- independent review scope;
- live checks required after reconciliation.

## Risks

Review:

- external exposure;
- authentication and authorization;
- RBAC expansion;
- secret handling;
- availability;
- dependency ordering;
- storage changes;
- data loss;
- irreversible migration;
- rollback complexity;
- version compatibility.

Continue automatically unless a material user decision is required.

# Phase 3: Research when necessary

Repository context takes priority. Use upstream research only when implementation depends on facts not reliably established by the repository.

Research is required for current or version-specific behavior such as:

- supported APIs or custom resources;
- Helm chart values;
- controller flags;
- deprecated configuration;
- breaking changes;
- component compatibility;
- installation requirements;
- RBAC requirements;
- behavior documented only in upstream source;
- version-specific Talos, Kubernetes, Flux, Cilium, or controller behavior.

Do not research facts already established by the repository unless they appear stale or contradictory.

When using a research agent, provide:

- component name;
- repository version, chart version, or application version;
- exact behavior to verify;
- implementation decision that depends on the answer.

Require the result to include:

1. applicable version;
2. authoritative evidence;
3. deprecated or version-specific behavior;
4. direct repository implication;
5. unresolved uncertainty.

Prefer:

- official documentation;
- upstream source;
- chart source;
- release notes;
- versioned API references.

Do not blindly copy upstream examples. Adapt confirmed behavior to repository conventions.

When upstream guidance conflicts with the repository, determine whether:

- the repository intentionally uses another valid pattern;
- versions differ;
- the repository is outdated;
- a migration is required.

State the conflict and its implementation consequence explicitly.

# Phase 4: Implement

The primary implementation agent owns the complete feature and integration.

Delegate only when useful and supported by available agents.

Typical domains:

- provisioning and infrastructure state;
- Kubernetes, Flux, Helm, networking, and platform services;
- Taskfile, scripts, validation, and operational automation;
- security, identity, exposure, secrets, RBAC, and trust boundaries.

Implementation rules:

- make the smallest coherent change;
- reuse nearby patterns;
- preserve naming and directory conventions;
- keep dependencies explicit;
- pin versions according to repository conventions;
- avoid unrelated refactoring;
- avoid speculative abstractions;
- add documentation only where it provides operational value;
- update all required environment wiring;
- preserve rollback feasibility where practical;
- do not claim live success during local implementation.

During implementation, do not run commands that mutate Git history, publish changes, reconcile GitOps, or directly mutate managed cluster state.

Prohibited unless explicitly authorized in the appropriate later phase:

```text
git commit
git push
git merge
flux reconcile
kubectl apply
kubectl create
kubectl edit
kubectl delete
helm install
helm upgrade
helm uninstall
```

Read-only cluster inspection is permitted when needed for discovery or diagnosis, provided it does not create or modify live state.

# Phase 5: Validate locally

Discover and use repository-provided validation entrypoints.

Always run:

```bash
git diff --check
git status --short
git diff
```

Also run the relevant repository checks for the affected domain.

Possible examples:

```bash
task checks:all
task checks:platform
nix flake check
kustomize build <path>
kubeconform ...
```

Examples are not defaults. Prefer existing Taskfile or repository targets over manually reconstructed command sequences.

For every validation command, record:

- exact command;
- result;
- relevant failure details;
- whether the failure was introduced by the current change;
- whether the command fully or partially covers the acceptance contract.

Correct failures caused by the feature.

Do not silently repair unrelated or pre-existing failures. Report them separately.

## Final diff inspection

Inspect the complete diff for:

- unintended files;
- plaintext secrets;
- generated-file changes;
- formatting errors;
- incorrect paths;
- duplicated configuration;
- missing dependency declarations;
- missing environment wiring;
- incomplete migrations or deletions;
- accidental broad permissions;
- inconsistent versions;
- changes outside scope.

Do not treat a successful command as a substitute for diff review.

# Phase 6: Implementation report

After local implementation and validation, report:

```text
Outcome

Files changed

Acceptance conditions
- satisfied locally
- pending publication
- pending live verification

Validation
- command: result

Upstream research
- used or not used
- version checked
- conclusions affecting implementation

Security review
- performed
- required before publication
- not applicable

Assumptions

Pre-existing failures

Residual risks

Live checks still required

Readiness for independent verification
```

Do not describe the feature as complete while publication, reconciliation, or live acceptance checks remain pending.

# Phase 7: Independent verification

Independent verification must be separated from implementation reasoning.

Use a separate verifier agent or a fresh verification pass that:

- receives the original request and acceptance contract;
- does not rely on the implementation summary as proof;
- does not modify files;
- independently inspects the repository and complete diff;
- independently selects or confirms deterministic checks;
- challenges claims made by the implementation report.

The verifier must:

1. read the original request;
2. read the acceptance contract;
3. inspect the complete diff;
4. inspect relevant surrounding repository files;
5. compare the change with established patterns;
6. run appropriate deterministic checks;
7. review security and failure behavior;
8. verify scope control;
9. identify conditions that still require publication or live verification.

Review for:

- correctness;
- repository consistency;
- secret safety;
- scope control;
- exposure and RBAC;
- version compatibility;
- dependency ordering;
- failure behavior;
- rollback behavior;
- sufficient validation;
- unsupported assumptions;
- false claims of completion.

Findings must be ordered by severity:

- Blocker
- High
- Medium
- Low

Every finding should include:

- affected file or area;
- evidence;
- operational consequence;
- required correction.

Finish with exactly one verdict:

```text
READY FOR RECONCILIATION
CHANGES REQUIRED
BLOCKED BY MISSING INFORMATION
```

`READY FOR RECONCILIATION` means the Git-managed change is suitable for publication and live reconciliation. It does not mean the feature is already deployed or functionally complete.

When changes are required:

```text
verifier findings
→ implementation fixes Git-managed files
→ local validation
→ independent verification again
```

# Phase 8: Git publication gate

The user owns:

- staging;
- commit creation;
- push;
- pull-request review;
- merge.

The agent may provide:

- suggested commit message;
- pull-request title;
- pull-request summary;
- test evidence;
- reviewer notes.

Do not claim the feature is available to Flux until the intended revision is committed and published to the branch or revision observed by Flux.

Before reconciliation, establish:

- current branch;
- current commit;
- intended commit;
- clean or intentionally dirty working-tree state;
- publication state;
- branch or revision observed by Flux;
- latest independent verification verdict.

Reconciliation is blocked when:

- the intended revision is not published;
- the verifier verdict is not `READY FOR RECONCILIATION`;
- relevant local validation is failing;
- unrelated working-tree state makes the target revision ambiguous;
- the reconciliation entrypoint has not been verified.

# Phase 9: Reconcile

Reconcile only when the user explicitly requests reconciliation.

Before execution:

1. inspect current Git state;
2. confirm the intended revision is published;
3. confirm relevant local validation passed;
4. confirm the latest verifier verdict is `READY FOR RECONCILIATION`;
5. check for unrelated working-tree changes;
6. verify the repository's current reconciliation entrypoint;
7. summarize expected live changes;
8. state the rollback or recovery path;
9. obtain approval for the exact reconciliation command if it has not already been explicitly approved.

Use the repository's existing reconciliation entrypoint.

The expected command may currently be:

```bash
task cluster:reconcile
```

Do not assume it is still correct. Verify it from the current Taskfile or repository documentation before running it.

Do not replace the repository entrypoint with direct Flux or Kubernetes mutation commands.

# Phase 10: Verify live state

After reconciliation, use read-only checks to verify the actual outcome.

Possible commands include:

```bash
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
kubectl get pods -A
kubectl get events -A
kubectl describe ...
kubectl logs ...
```

Prefer checks scoped to affected namespaces, controllers, resources, and dependencies.

Verify:

## GitOps state

- Flux observes the intended Git revision;
- relevant GitRepository sources are ready;
- affected Kustomizations are ready;
- affected HelmReleases are ready;
- dependency ordering completed as expected.

## Workload state

- expected workloads exist;
- readiness and availability conditions are satisfied;
- events contain no feature-related failure;
- logs contain no unresolved feature-related error;
- required external dependencies are reachable.

## Functional state

Test every feature-specific acceptance condition.

Examples:

```text
Gateway:
- Gateway is accepted;
- expected routes are attached;
- endpoint resolves;
- representative request succeeds.

DNS:
- controller detects the source resource;
- provider record is created;
- authoritative or expected resolver returns the record.

Storage:
- claim binds;
- workload mounts the volume;
- read/write test succeeds;
- data survives the required restart or reschedule test.

Observability:
- target is discovered;
- data is ingested;
- expected query returns current results.

Authentication:
- identity provider integration is ready;
- expected user flow succeeds;
- unauthorized access is denied.
```

Do not infer functional success solely from resource readiness.

# Phase 11: Failure handling

When reconciliation or live verification fails, classify the cause as:

- introduced by the feature;
- pre-existing;
- external dependency;
- publication or revision mismatch;
- unclear.

## Feature-introduced failure

1. diagnose with read-only commands;
2. modify Git-managed source;
3. rerun local validation;
4. rerun independent verification;
5. have the user commit and publish the fix;
6. reconcile again;
7. repeat live verification.

Do not repair the live cluster imperatively.

## Pre-existing or unrelated failure

- report the blocker;
- provide evidence;
- do not alter unrelated systems;
- distinguish feature correctness from environmental readiness;
- identify which acceptance conditions remain blocked.

## External failure

- identify the external dependency;
- provide observable evidence;
- state whether retry, credential correction, provider action, or configuration change is required;
- avoid claiming repository completion when functional acceptance is still blocked.

## Unclear failure

- preserve evidence;
- narrow the failure using read-only checks;
- avoid speculative changes;
- state what remains unknown.

# Phase 12: Final report

The final deployment report must include:

```text
Outcome

Git revision
- branch
- commit
- publication state
- revision observed by Flux

Files changed

Local validation
- command: result

Independent verification
- verdict
- unresolved findings

Reconciliation
- command
- result

Flux readiness
- sources
- Kustomizations
- HelmReleases

Workload readiness

Functional acceptance evidence

Completion conditions
- satisfied
- unsatisfied
- blocked

Pre-existing or external failures

Residual risks

Rollback or recovery notes
```

A feature is complete only when:

- the intended Git revision is published;
- local validation has passed or documented exceptions are accepted;
- independent verification returned `READY FOR RECONCILIATION`;
- reconciliation succeeded;
- GitOps resources are ready;
- workloads are healthy;
- all required functional acceptance conditions have been verified.

# Compact execution checklist

```text
[ ] Request translated into observable acceptance conditions
[ ] Repository and nearby patterns inspected
[ ] Existing validation and reconciliation entrypoints verified
[ ] Upstream behavior researched where version-sensitive
[ ] Smallest coherent Git-managed change implemented
[ ] No unrelated files or plaintext secrets
[ ] Relevant local validation passed
[ ] Complete diff inspected
[ ] Independent verifier returned READY FOR RECONCILIATION
[ ] Intended revision committed and published by the user
[ ] Reconciliation explicitly approved and executed through repository tooling
[ ] Flux observes the intended revision
[ ] Affected resources are ready
[ ] Functional behavior verified
[ ] Final report distinguishes satisfied, unsatisfied, and blocked conditions
```
