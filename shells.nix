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
      kubeconform
      kustomize

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
      syft

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

    shellHook = ''
      export TALOSCONFIG="$PWD/.talos/talosconfig"
      export KUBECONFIG="$PWD/.talos/kubeconfig"
    '';
  };

  docs = pkgs.mkShell {
    packages = with pkgs; [
      nodejs
      pnpm
    ];
  };
}
