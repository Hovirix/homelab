---
description: Independently review the current HX Lab feature
agent: plan
subtask: true
---

Load the `hxlab-feature` skill.

Review focus supplied by the user:

$ARGUMENTS

Execute only the independent verification phase of the skill.

Requirements:

1. Read the repository instructions and reconstruct the intended outcome from:
   - the parent feature request;
   - the implementation report;
   - the current branch and complete working-tree diff.

2. Inspect relevant surrounding files and compare the implementation with the repository's existing patterns.
3. Use Explore when broader repository inspection would improve the review.
4. Use Scout only when correctness depends on external, current, deprecated, or version-specific upstream behavior that was not already verified.
5. Review:
   - functional correctness;
   - repository and domain consistency;
   - scope control;
   - GitOps integrity;
   - secret safety;
   - exposure, identity, RBAC, permissions, and trust boundaries;
   - dependency ordering;
   - version compatibility;
   - failure and rollback behavior;
   - validation coverage;
   - unrelated or generated-file changes;
   - completion conditions still requiring live verification.
6. Run the smallest relevant deterministic validation commands already provided by the repository.
7. Always inspect:

```bash
git status --short
git diff --check
git diff
```

8. Do not modify files, implement fixes, commit, push, merge, reconcile, or mutate live cluster state.
9. Do not accept implementation-agent claims without verifying them from repository evidence or command output.
10. Do not report live completion before reconciliation and functional verification.

Do not run:

```text
git commit
git push
task cluster:reconcile
flux reconcile
kubectl apply
kubectl create
kubectl edit
kubectl delete
helm upgrade
```

Report findings first, ordered by severity:

```text
BLOCKER
HIGH
MEDIUM
LOW
```

Each finding must include:

- the affected path or command;
- the concrete problem;
- why it matters;
- the required correction or decision.

Then report:

### Validation

List every command executed and its result.

### Upstream verification

State whether Scout was used and summarize any version-specific conclusions.

### Security review

State whether the change is security-sensitive and whether dedicated Security Agent review is still required.

### Completion conditions

Mark each condition as:

- verified locally;
- pending live verification;
- unsatisfied;
- blocked.

### Residual risks

List remaining uncertainty, operational risks, and rollback concerns.

### Live checks required

List the exact checks that `/reconcile` must perform.

Finish with exactly one verdict:

```text
READY FOR RECONCILIATION
CHANGES REQUIRED
BLOCKED BY MISSING INFORMATION
```
