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
          coreos-installer = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
            pname = "coreos-installer";
            version = "0.27.0";
            src = pkgs.fetchFromGitHub {
              owner = "coreos";
              repo = "coreos-installer";
              rev = "v0.27.0";
              hash = "sha256-tIcBZikmV9y2PBAGhtul5SoBMHDzibTz2q3M+qa6uCQ=";
            };
            cargoDeps = pkgs.runCommand "coreos-installer-vendor" { } ''
              cp -r ${
                pkgs.fetchzip {
                  url = "https://github.com/coreos/coreos-installer/releases/download/v0.27.0/coreos-installer-0.27.0-vendor.tar.gz";
                  hash = "sha256-piZpkABMmkSe7DRoMZVDv7mK90x/tf+9KJReWxcoVP8=";
                }
              } $out
              chmod u+w $out
              cp ${finalAttrs.src}/Cargo.lock $out/Cargo.lock
            '';
            nativeBuildInputs = [
              pkgs.pkg-config
              pkgs.makeWrapper
            ];
            buildInputs = [
              pkgs.openssl
              pkgs.xz
              pkgs.zstd
            ];
            nativeCheckInputs = [ pkgs.gnupg ];
            postInstall = ''
              wrapProgram $out/bin/coreos-installer \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.gnupg ]}
            '';
          });
          incusos-flasher = pkgs.buildGo127Module {
            pname = "incusos-flasher";
            version = "0-unstable-2026-11-20";
            src = pkgs.fetchFromGitHub {
              owner = "lxc";
              repo = "incus-os";
              rev = "95d29ace0fd42d0e42e69919ed44cc1eb3dd8191";
              hash = "sha256-vzxhKdlXIVMW01ixn2rSCZn4lryQ7QO+R/jLXsIxcwg=";
            };
            modRoot = "incus-osd";
            subPackages = [ "cmd/flasher-tool" ];
            vendorHash = "sha256-dX/N+jac1y++XiDKZ/okqsAebn3a+NV0t/y1ApSXJfs=";
            doCheck = false;
          };
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
            curl
            go-task
            jq
            xz
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
              ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                coreos-installer
                incusos-flasher
                pkgs.incus.client
              ]
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
