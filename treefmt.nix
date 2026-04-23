{
  programs = {
    nixfmt.enable = true;
    prettier.enable = true;
    terraform.enable = true;
    yamlfmt = {
      enable = true;
      settings.formatter = {
        type = "basic";
        retain_line_breaks_single = true;
      };
    };
  };
}
