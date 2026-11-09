{
  description = "Homelab flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          secretspec-python = pkgs.python3Packages.buildPythonPackage (finalAttrs: {
            pname = "secretspec";
            inherit (pkgs.secretspec) version;
            format = "wheel";
            src = pkgs.fetchPypi (
              {
                inherit (finalAttrs) pname version;
                format = "wheel";
                dist = "cp39";
                python = "cp39";
                abi = "abi3";
              }
              // {
                x86_64-linux = {
                  platform = "manylinux_2_28_x86_64";
                  hash = "sha256-lGr0t8CMz124BarE8Vk3lIdLCmbhKFToQlOfiuitLoE=";
                };
                aarch64-darwin = {
                  platform = "macosx_11_0_arm64";
                  hash = "sha256-9nFs/fTLbs8sPgTmEy7G5e6sT6tMEkoBq8IPXX67Rv8=";
                };
              }
              .${system}
            );
            pythonImportsCheck = [ "secretspec" ];
          });

          validation = with pkgs; [
            actionlint
            ansible
            ansible-lint
            butane
            docker-client
            secretspec
            (python3.withPackages (_: [ secretspec-python ]))
            shellcheck
            tflint
          ];

          security = with pkgs; [
            conftest
            trivy
            zizmor
          ];

          formatters = with pkgs; [
            nixfmt
            opentofu
            prettier
            ruff
            shfmt
            taplo
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
                openssl
                pre-commit
                pyright
                sops
                tofu-ls
                uv
                yaml-language-server
              ]);
            # Small Fix for rootless docker
            shellHook = "unset DOCKER_HOST";
          };
        }
      );
    };
}
