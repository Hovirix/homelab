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
      shfmt
      yamllint

      # General Utilities
      jq
      yq-go

      # Language Servers
      bash-language-server
      nil
      tofu-ls
      yaml-language-server
    ];

    shellHook = ''
      export DOCKER_HOST=''${DOCKER_HOST:-ssh://deploy@swarm-01.home.hovirix.dev}
    '';
  };

  docs = pkgs.mkShell {
    packages = with pkgs; [
      nodejs
      pnpm
    ];
  };
}
