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
  };

  docs = pkgs.mkShell {
    packages = with pkgs; [
      nodejs
      pnpm
    ];
  };
}
