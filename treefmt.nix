{ pkgs, ... }:
{
  programs = {
    nixfmt.enable = true;
    prettier.enable = true;
    shfmt = {
      enable = true;
      includes = [ "operations/scripts/*.sh" ];
    };
    yamlfmt = {
      enable = true;
      settings.formatter = {
        type = "basic";
        retain_line_breaks_single = true;
      };
    };
  };

  settings = {
    global.excludes = [
      "platform/gitops/**"
      "platform/flux-system/**"
      "secrets/**"
    ];
    formatter.opentofu = {
      command = "${pkgs.opentofu}/bin/tofu";
      options = [ "fmt" ];
      includes = [
        "*.tf"
        "*.tfvars"
      ];
    };
  };
}
