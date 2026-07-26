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
      kubeconform
      kustomize
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
      kubeconform
      shfmt
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
      export TALOSCONFIG="$PWD/infrastructure/opentofu/stacks/talos/talosconfig"
      export KUBECONFIG="$PWD/infrastructure/opentofu/stacks/talos/kubeconfig"
    '';
  };

  docs = pkgs.mkShell {
    packages = with pkgs; [
      nodejs
      pnpm
    ];
  };
}
