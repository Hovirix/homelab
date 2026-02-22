{
  description = "homelab-docs dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bun
            nodejs
          ];

          shellHook = ''
            export PATH="$PWD/node_modules/.bin:$PATH"
            if [ -f bun.lockb ] && [ ! -d node_modules ]; then
              echo "node_modules not found — running bun install"
              bun install
            fi
          '';
        };
      }
    );
}

