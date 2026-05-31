{
  description = "Homelab dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        checks = {
          formatting = treefmtEval.config.build.check self;
        };

        devShells = {
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
        };
      }
    );
}
