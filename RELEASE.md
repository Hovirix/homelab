# Release policy

Proposed policy for implementation in this draft PR. Release Please automation is not yet configured.

## Versioning

Use independent SemVer versions for homelab and netlab: `vMAJOR.MINOR.PATCH`.
The compatibility contract covers required configuration, supported Task interfaces,
persistent data formats, and the supported upgrade procedure.

- PATCH: backward-compatible bug or security fixes.
- MINOR: backward-compatible capabilities.
- MAJOR: incompatible contract changes, including required manual data migrations.
- Internal refactors, elapsed time, change volume, and upstream version numbers do not by themselves justify a major bump.
- Assess dependency upgrades by their impact on this contract, not the dependency's version alone.
- The highest-impact change since the previous release determines the bump.
- Breaking releases explain migration, expected downtime, and rollback limits.

## Commits

Use Conventional Commits with the existing repository types and scopes.
Squash PRs into conventional commits, preserving breaking-change footers.

- `fix(operations): correct archive selection` requests a patch.
- `feat(platform): add health probes` requests a minor.
- `feat(infrastructure)!: replace the storage layout` requests a major.
- A `BREAKING CHANGE:` footer on any type also requests a major.
- Ordinary `chore:` and `refactor:` changes need not trigger a release.

## Release flow

Release Please maintains a reviewable release PR with a version and changelog.
Merge that PR when a useful batch is ready; urgent fixes need not wait.
The release workflow then creates the tag and GitHub Release.
Do not publish from ordinary feature merges, create competing release publishers,
overwrite existing tags, or reset established release history.

Release publication and deployment are separate operations.
A release identifies code, not verified runtime state.
Record the deployed tag or commit and live verification separately.
No release workflow may deploy infrastructure, stacks, or router firmware.
