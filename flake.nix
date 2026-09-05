{
  description = "Homelab flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        validation = with pkgs; [
          actionlint
          ansible
          ansible-lint
          butane
          docker-client
          shellcheck
          tflint
        ];

        security = with pkgs; [
          conftest
          grype
          syft
          trivy
          zizmor
        ];

        formatters = with pkgs; [
          nixfmt
          opentofu
          prettier
          shfmt
          treefmt
          yamlfmt
        ];

        utilities = with pkgs; [
          go-task
          jq
          yq-go
        ];
      in
      {
        devShells = {
          ci = pkgs.mkShell {
            packages = validation ++ security ++ formatters ++ utilities;
          };

          default = pkgs.mkShell {
            packages =
              validation
              ++ security
              ++ formatters
              ++ utilities
              ++ (with pkgs; [
                ansible-language-server
                bash-language-server
                nil
                pre-commit
                sops
                tofu-ls
                yaml-language-server
              ]);
          };
        };
      }
    );
}
