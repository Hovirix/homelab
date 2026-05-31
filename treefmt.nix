{ pkgs, ... }:

{
  programs = {
    nixfmt.enable = true;
    prettier.enable = true;
    yamlfmt = {
      enable = true;
      settings.formatter = {
        type = "basic";
        retain_line_breaks_single = true;
      };
    };
  };

  settings.formatter.opentofu = {
    command = "${pkgs.opentofu}/bin/tofu";
    options = [ "fmt" ];
    includes = [
      "*.tf"
      "*.tfvars"
    ];
  };
}
