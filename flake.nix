{
  description = "Homelab dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system} = {
        default = pkgs.mkShell {
          packages = with pkgs; [
            sops
            butane
            opentofu
            tofu-ls
            ansible
            yaml-language-server
          ];
        };

        docs = pkgs.mkShell {
          packages = with pkgs; [
            nodejs
            pnpm
          ];
        };

        openwrt = pkgs.mkShell {
          packages = with pkgs; [
            bash-language-server
            go-task
            sops
            shfmt
            wget
            gnumake
            gomplate
            gzip
            unzip
            python3
            python3Packages.distutils
          ];
        };
      };
    };
}
