#!/usr/bin/env bash
# shellcheck disable=SC2016 # yq variables and Markdown backticks are literal.
set -euo pipefail
export LC_ALL=C

mode="${SECURITY_MODE:-gate}"
case "$mode" in
pr) : "${SECURITY_BASE_REF:?PR scans require a base commit}" ;;
full | gate) ;;
*)
	echo "Unknown security mode: $mode" >&2
	exit 1
	;;
esac

dir=".artifacts/security"
mkdir -p "$dir/json/images" "$dir/sarif/images"
rm -f "$dir/sarif/images/"*.sarif

base=""
if [[ -n ${SECURITY_BASE_REF:-} ]]; then
	base="$(git merge-base HEAD "$SECURITY_BASE_REF")"
elif git rev-parse --verify HEAD^ >/dev/null 2>&1; then
	base="$(git rev-parse HEAD^)"
fi

inventory() {
	local stack
	while IFS= read -r stack; do
		[[ $stack == */stack.yml ]] || continue
		if [[ -n $1 ]]; then
			git show "$1:$stack"
		else
			cat "$stack"
		fi | STACK="$stack" yq -N -r '
          (.services // {}) | to_entries[] | select(.value.image != null) |
          [strenv(STACK), .key, .value.image] | @tsv'
	done
}

find platform -type f -name stack.yml | sort | inventory "" >"$dir/current.tsv"
: >"$dir/base.tsv"
if [[ -n $base ]]; then
	git ls-tree -r --name-only "$base" -- platform |
		inventory "$base" >"$dir/base.tsv"
fi

[[ -s "$dir/current.tsv" ]] || {
	echo "No images found" >&2
	exit 1
}

# One report per digest, even when several services use the same image.
declare -A reports=()
scan() {
	local image="$1" name
	name="$(printf '%s' "$image" | sha256sum | cut -d ' ' -f 1)"
	if [[ ! -v reports[$image] ]]; then
		if ((${#reports[@]} == 0)); then
			trivy image --download-db-only
		fi
		trivy image --skip-db-update --scanners vuln --ignorefile /dev/null --exit-code 0 \
			--format json --output "$dir/json/images/$name.json" "$image"
		yq -e '.SchemaVersion == 2 and (.ArtifactName // "") != ""' "$dir/json/images/$name.json" >/dev/null
		reports[$image]="$dir/json/images/$name.json"
	fi
	report="${reports[$image]}"
}

findings() {
	# OS targets contain image versions; package targets must survive upgrades.
	yq -r '[.Results[]? |
      (select(.Class == "os-pkgs") | .Target) = "os" |
      . as $result | .Vulnerabilities[]? |
      [.VulnerabilityID, .PkgName, $result.Target, .Severity] | @tsv] | .[]' "$1" | sort -u
}

fixable() {
	yq '[.Results[]?.Vulnerabilities[]? |
      select((.Severity == "HIGH" or .Severity == "CRITICAL") and (.FixedVersion // "") != "")] |
      length' "$1"
}

summary="$dir/summary.md"
printf '# Image security\n\n' >"$summary"
# Preserve partial summaries when a scanner fails.
trap 'if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then cat "$summary" >>"$GITHUB_STEP_SUMMARY"; fi' EXIT
failed=0
selected=0

while IFS=$'\t' read -r stack service image; do
	target="${stack%/stack.yml}/$service"
	name="$(printf '%s' "$target" | sha256sum | cut -d ' ' -f 1)"
	# Native Trivy YAML exceptions are scoped to one deployment, with expiry dates.
	ignore="security/ignore/$target.yaml"
	old="$(awk -F '\t' -v stack="$stack" -v service="$service" \
		'$1 == stack && $2 == service { print $3 }' "$dir/base.tsv")"
	if [[ $mode == pr && $old == "$image" ]] &&
		git diff --quiet "$base" -- "$ignore"; then
		continue
	fi
	selected=$((selected + 1))
	scan "$image"
	current="$report"
	old_fixable=0
	findings "$current" >"$dir/$name.new.tsv"
	: >"$dir/$name.old.tsv"
	if [[ $mode == pr && -n $old ]]; then
		scan "$old"
		findings "$report" >"$dir/$name.old.tsv"
		old_fixable="$(fixable "$report")"
	fi
	awk -F '\t' 'FILENAME == ARGV[1] { seen[$1 FS $2 FS $3]=1; next }
      !(($1 FS $2 FS $3) in seen)' "$dir/$name.old.tsv" "$dir/$name.new.tsv" >"$dir/$name.introduced.tsv"
	awk -F '\t' 'FILENAME == ARGV[1] { seen[$1 FS $2 FS $3]=1; next }
      !(($1 FS $2 FS $3) in seen)' "$dir/$name.new.tsv" "$dir/$name.old.tsv" >"$dir/$name.resolved.tsv"
	{
		printf '## `%s`\n\nProposed: `%s`\n\n' "$target" "$image"
		if [[ $mode == pr ]]; then
			printf 'Current: `%s`\n\n' "${old:-new service}"
			printf '| Severity | Current | Proposed | Introduced | Resolved |\n|---|---:|---:|---:|---:|\n'
		else
			printf '| Severity | Current |\n|---|---:|\n'
		fi
		for severity in CRITICAL HIGH MEDIUM LOW UNKNOWN; do
			printf '| %s ' "$severity"
			if [[ $mode == pr ]]; then
				files=(old new introduced resolved)
			else
				files=(new)
			fi
			for suffix in "${files[@]}"; do
				printf '| %s ' "$(awk -F '\t' -v severity="$severity" '$4 == severity { n++ } END { print n+0 }' "$dir/$name.$suffix.tsv")"
			done
			printf '|\n'
		done
		printf '\n'
		if [[ $mode == pr ]]; then
			printf 'Fixable HIGH/CRITICAL (before exceptions): **%s → %s**.\n\n' "$old_fixable" "$(fixable "$current")"
		else
			printf 'Fixable HIGH/CRITICAL (before exceptions): **%s**.\n\n' "$(fixable "$current")"
		fi
		if [[ $mode == pr ]]; then
			for suffix in introduced resolved; do
				printf '<details><summary>%s findings</summary>\n\n```text\n' "$suffix"
				cat "$dir/$name.$suffix.tsv"
				printf '```\n\n</details>\n\n'
			done
		fi
	} >>"$summary"

	sarif="$dir/sarif/images/$name.sarif"
	trivy convert --ignorefile /dev/null --format sarif --output "$sarif" "$current"
	# Stable deployment/package locations prevent a new analysis on every digest update.
	TARGET="$target" yq -i -o=json '
      .runs[0].automationDetails.id = ("images/" + strenv(TARGET) + "/") |
      .runs[0].results[]? |= (. as $result | .locations[]?.physicalLocation |= (
        .artifactLocation.uri = ("images/" + strenv(TARGET) + "/" +
          (.artifactLocation.uri | @uri) + "/" +
          ($result.message.text | split("\n")[0] | sub("^Package: ", "") | @uri)) |
        .region = {"startLine": 1, "startColumn": 1}))' "$sarif"
	if [[ -f $ignore ]]; then
		yq -e '[.vulnerabilities[]? | select(.id == null or .expired_at == null or (.statement // "") == "")] |
              length == 0' "$ignore" >/dev/null
	else
		ignore=/dev/null
	fi
	status=0
	trivy image --scanners vuln --skip-db-update --skip-java-db-update \
		--ignorefile "$ignore" --severity HIGH,CRITICAL --ignore-unfixed \
		--exit-code 10 --format json --output "$dir/json/images/$name.gate.json" \
		"$image" || status=$?
	if ((status != 0 && status != 10)); then
		exit "$status"
	fi
	yq -e '.SchemaVersion == 2 and (.ArtifactName // "") != ""' "$dir/json/images/$name.gate.json" >/dev/null
	if ((status == 10)); then
		printf '**Gate: failed — unexcepted, fixable HIGH/CRITICAL findings.**\n\n' >>"$summary"
		failed=1
	else
		printf '**Gate: passed.**\n\n' >>"$summary"
	fi
done <"$dir/current.tsv"

# Empty analyses close findings for deployments removed since the base commit.
while IFS=$'\t' read -r stack service image; do
	if awk -F '\t' -v stack="$stack" -v service="$service" \
		'$1 == stack && $2 == service { found=1 } END { exit !found }' "$dir/current.tsv"; then
		continue
	fi
	target="${stack%/stack.yml}/$service"
	name="$(printf '%s' "$target" | sha256sum | cut -d ' ' -f 1)"
	sarif="$dir/sarif/images/$name.sarif"
	printf '{"SchemaVersion":2,"ArtifactName":"removed","ArtifactType":"container_image","Results":[]}' >"$dir/json/images/$name.removed.json"
	trivy convert --ignorefile /dev/null --format sarif --output "$sarif" "$dir/json/images/$name.removed.json"
	TARGET="$target" yq -i -o=json '.runs[0].automationDetails.id = ("images/" + strenv(TARGET) + "/")' "$sarif"
done <"$dir/base.tsv"

if ((selected == 0)); then
	printf 'No changed images or image exceptions.\n' >>"$summary"
fi
cat "$summary"
exit "$failed"
