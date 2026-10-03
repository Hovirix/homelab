---
description: Commit the intended current changes without pushing
agent: build
---

$ARGUMENTS

Create one coherent commit from the current working tree.

Inspect the diff, exclude unrelated or sensitive changes, run the smallest relevant local validation, and use the repository Conventional Commit format.

Do not push, amend, bypass hooks, or perform remote operations unless explicitly requested.

After committing, verify the committed diff and report the commit hash plus any remaining changes.
