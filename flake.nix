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
              ansible
              ansible-lint
              helm-ls
              helmfile
              kubectl
              kubernetes-helm
              minikube
              opentofu
              sops
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
