{
  description = "Homelab flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in
    {
      devShells = nixpkgs.lib.genAttrs systems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        secretspec-python = pkgs.python3Packages.buildPythonPackage {
          pname = "secretspec";
          version = "0.21.1";
          format = "wheel";
          src = pkgs.fetchurl {
            url = "https://files.pythonhosted.org/packages/a2/5b/5cbaceaf5028568fe359897d069b0dcb583442d70ea0b7d53b62c0f06b47/secretspec-0.21.1-cp39-abi3-manylinux_2_28_x86_64.whl";
            hash = "sha256-lGr0t8CMz124BarE8Vk3lIdLCmbhKFToQlOfiuitLoE=";
          };
        };

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
          grype
          syft
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
              yaml-language-server
            ]);
        };
      }
      );
    };
}
