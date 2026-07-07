{
  self,
  pkgs,
  treefmtEval,
}:

let
  gitleaks =
    pkgs.runCommand "gitleaks"
      {
        nativeBuildInputs = [
          pkgs.gitleaks
          pkgs.git
        ];
      }
      ''
        export HOME="$TMPDIR"

        cd ${self}

        gitleaks detect --no-banner --redact --source . --report-format json --report-path "$TMPDIR/gitleaks.json"

        touch $out
      '';

  sbom-infrastructure =
    pkgs.runCommand "sbom-infrastructure"
      {
        nativeBuildInputs = [ pkgs.syft ];
      }
      ''
        export HOME="$TMPDIR"
        export SYFT_CACHE_DIR="$TMPDIR/syft"

        syft --config ${self}/security/syft.yaml dir:${self}/infrastructure -o cyclonedx-json="$out"
      '';

  sbom-operations =
    pkgs.runCommand "sbom-operations"
      {
        nativeBuildInputs = [ pkgs.syft ];
      }
      ''
        export HOME="$TMPDIR"
        export SYFT_CACHE_DIR="$TMPDIR/syft"

        syft --config ${self}/security/syft.yaml dir:${self}/operations -o cyclonedx-json="$out"
      '';

  sbom-platform =
    pkgs.runCommand "sbom-platform"
      {
        nativeBuildInputs = [ pkgs.syft ];
      }
      ''
        export HOME="$TMPDIR"
        export SYFT_CACHE_DIR="$TMPDIR/syft"

        syft --config ${self}/security/syft.yaml dir:${self}/platform -o cyclonedx-json="$out"
      '';

  sbom-docs =
    pkgs.runCommand "sbom-docs"
      {
        nativeBuildInputs = [ pkgs.syft ];
      }
      ''
        export HOME="$TMPDIR"
        export SYFT_CACHE_DIR="$TMPDIR/syft"

        syft --config ${self}/security/syft.yaml dir:${self}/docs -o cyclonedx-json="$out"
      '';

  trivy-sbom-infrastructure =
    pkgs.runCommand "trivy-sbom-infrastructure"
      {
        nativeBuildInputs = [ pkgs.trivy ];
      }
      ''
        export HOME="$TMPDIR"
        export TRIVY_CACHE_DIR="$TMPDIR/trivy"

        trivy --config ${self}/security/trivy.yaml sbom --scanners vuln ${sbom-infrastructure}

        touch $out
      '';

  trivy-sbom-operations =
    pkgs.runCommand "trivy-sbom-operations"
      {
        nativeBuildInputs = [ pkgs.trivy ];
      }
      ''
        export HOME="$TMPDIR"
        export TRIVY_CACHE_DIR="$TMPDIR/trivy"

        trivy --config ${self}/security/trivy.yaml sbom --scanners vuln ${sbom-operations}

        touch $out
      '';

  trivy-sbom-platform =
    pkgs.runCommand "trivy-sbom-platform"
      {
        nativeBuildInputs = [ pkgs.trivy ];
      }
      ''
        export HOME="$TMPDIR"
        export TRIVY_CACHE_DIR="$TMPDIR/trivy"

        trivy --config ${self}/security/trivy.yaml sbom --scanners vuln ${sbom-platform}

        touch $out
      '';

  trivy-sbom-docs =
    pkgs.runCommand "trivy-sbom-docs"
      {
        nativeBuildInputs = [ pkgs.trivy ];
      }
      ''
        export HOME="$TMPDIR"
        export TRIVY_CACHE_DIR="$TMPDIR/trivy"

        trivy --config ${self}/security/trivy.yaml sbom --scanners vuln ${sbom-docs}

        touch $out
      '';

  shellcheck =
    pkgs.runCommand "shellcheck"
      {
        nativeBuildInputs = [ pkgs.shellcheck ];
      }
      ''
        find ${self}/operations/scripts -type f -exec shellcheck {} +

        touch $out
      '';

  ansible-lint =
    pkgs.runCommand "ansible-lint"
      {
        nativeBuildInputs = [
          pkgs.ansible
          pkgs.ansible-lint
        ];
      }
      ''
        export HOME="$TMPDIR"

        cd ${self}/infrastructure/ansible

        ansible-lint

        touch $out
      '';

  ansible-syntax =
    pkgs.runCommand "ansible-syntax"
      {
        nativeBuildInputs = [ pkgs.ansible ];
      }
      ''
        export HOME="$TMPDIR"

        cd ${self}/infrastructure/ansible

        for playbook in playbooks/*.yml; do
          ansible-playbook "$playbook" --syntax-check
        done

        touch $out
      '';

  tflint =
    pkgs.runCommand "tflint"
      {
        nativeBuildInputs = [ pkgs.tflint ];
      }
      ''
        cd ${self}/infrastructure/opentofu/stacks/prod

        for stack in */; do
          tflint --chdir="$stack"
        done

        touch $out
      '';
in
{
  formatting = treefmtEval.config.build.check self;

  inherit
    gitleaks
    shellcheck
    ansible-lint
    ansible-syntax
    tflint
    ;
}
