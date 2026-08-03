---
description: Implement and locally validate an HX Lab feature
agent: build
---

Load the `hxlab-feature` skill.

Feature request:

$ARGUMENTS

Execute the skill workflow from understanding the request through the
implementation report. Stop before independent verification, Git publication,
or live reconciliation.

Requirements:

1. Read the existing repository instructions and inspect the working tree.
2. Use Explore for focused repository discovery when useful.
3. Delegate focused upstream research to Scout whenever implementation depends
   on external, current, deprecated, or version-specific behavior.
4. Follow the repository's existing agent-routing and domain-ownership rules.
5. Establish observable completion conditions and a concise implementation plan.
6. Implement the smallest coherent Git-managed change.
7. Request Security Agent review when the change affects secrets, identity,
   permissions, RBAC, exposure, certificates, destructive behavior, or trust
   boundaries.
8. Run the repository's relevant deterministic validation entrypoints.
9. Inspect the complete final diff and preserve unrelated user changes.
10. Do not commit, push, merge, apply infrastructure, or mutate live production state.

Do not run:

```text
git commit
git push
tofu apply
tofu destroy
ansible-playbook --limit production
```

End with the implementation report defined by the skill and exactly one verdict:

```text
READY FOR /verify
NOT READY FOR /verify
BLOCKED BY USER DECISION
```
