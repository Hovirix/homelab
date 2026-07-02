{ pkgs }:
{
  default = pkgs.mkShell {
    packages = with pkgs; [
      # Infrastructure
      ansible
      opentofu

      # Kubernetes & GitOps
      fluxcd
      helmfile
      k9s
      kubectl
      kustomize
      kubernetes-helm
      talosctl

      # Secrets
      openssl
      sops

      # Security
      trivy

      # Automation
      go-task
      pre-commit

      # Validation & Linting
      ansible-lint
      kubeconform
      shfmt
      shellcheck
      yamllint

      # General Utilities
      jq
      yq-go

      # Language Servers
      bash-language-server
      helm-ls
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
