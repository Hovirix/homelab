
---
description: Generate and publish a structured GitHub release
agent: build
---

$ARGUMENTS

Create the next GitHub release autonomously.

## Preparation
- Verify clean main, synchronized remote, and passing CI/security.
- Inspect previous releases, commits, and merged PRs.
- Determine the appropriate SemVer version.
- For v1.0.0, review the complete repository architecture.

## Release notes

Title: `vX.Y.Z — Short descriptive title`

Opening: One concise paragraph explaining the release.

Use these sections in order:

1. **Highlights** — Significant features and improvements.
2. **Changes** — Group relevant changes by domain:
   Infrastructure, Platform, Operations, Security.
3. **Fixes** — Important corrections, when applicable.
4. **Breaking Changes** — Only when applicable.
5. **Upgrade Notes** — Only when manual actions are required.

Rules:
- Initial releases should describe the full platform.
- Minor releases should focus on meaningful new capabilities.
- Patch releases should be brief and focus on fixes.
- Omit empty or irrelevant sections.
- Avoid repeating information between sections.
- Summarize changes rather than listing individual commits.
- Reference relevant PRs when useful.
- Never invent features or verification results.

## Publishing
- Create and push an annotated SemVer tag.
- Publish the GitHub Release with the generated notes.
- Return the release URL.

## Constraints
- Running /release authorizes publication.
- Never modify source files or create release commits.
- Never create CHANGELOG.md.
- Never deploy.
- Never overwrite tags or releases.
- Stop if validation fails.
