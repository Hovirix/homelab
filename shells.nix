{ pkgs }:
{
  ci = pkgs.mkShell {
    packages = with pkgs; [
      # Automation
      go-task

      # Security
      syft
      trivy

      # Security validation
      actionlint
      ansible
      ansible-lint
      butane
      docker-client
      shellcheck
      tflint

      # Utilities used by task entrypoints
      jq
      yq-go
    ];
  };

  default = pkgs.mkShell {
    packages = with pkgs; [
      # Documentation
      nodejs
      pnpm

      # Infrastructure
      ansible
      ansible-lint
      butane
      docker-client
      opentofu
      shellcheck
      tflint

      # Secrets
      openssl
      sops

      # Security
      trivy
      syft

      # Automation
      go-task
      pre-commit

      # Validation & Linting
      actionlint
      shfmt
      yamllint

      # General Utilities
      jq
      yq-go

      # Language Servers
      ansible-language-server
      bash-language-server
      nil
      tofu-ls
      yaml-language-server
    ];

    shellHook = ''
      if [[ -z ''${DOCKER_HOST:-} && -x "$PWD/operations/scripts/swarm-host.sh" ]]; then
        eval "$("$PWD/operations/scripts/swarm-host.sh" --export)"
      fi
    '';
  };

  docs = pkgs.mkShell {
    packages = with pkgs; [
      nodejs
      pnpm
    ];
  };
}
