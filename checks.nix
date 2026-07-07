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
