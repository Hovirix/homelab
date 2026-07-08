{
  self,
  pkgs,
  treefmtEval,
}:

let
  trivy-secrets =
    pkgs.runCommand "trivy-secrets"
      {
        nativeBuildInputs = [ pkgs.trivy ];
      }
      ''
        export HOME="$TMPDIR"
        export TRIVY_CACHE_DIR="$TMPDIR/trivy"

        trivy --config ${self}/security/trivy.yaml fs --scanners secret ${self}

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
        cd ${self}/infrastructure/opentofu/stacks

        for stack in */; do
          tflint --chdir="$stack"
        done

        touch $out
      '';
in
{
  formatting = treefmtEval.config.build.check self;

  inherit
    trivy-secrets
    shellcheck
    ansible-lint
    ansible-syntax
    tflint
    ;
}
