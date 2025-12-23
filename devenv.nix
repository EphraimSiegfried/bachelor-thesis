{ config, pkgs, ... }:
{
  languages.typst = {
    enable = true;
    fontPaths = [
      "${pkgs.cascadia-code}"
      "${pkgs.corefonts}"
    ];
  };

  env.TYPST_ROOT = "${config.env.DEVENV_ROOT}/src";
  scripts.compile_typst.exec = "typst compile --creation-timestamp=$(date +%s) $DEVENV_ROOT/src/main.typ out.pdf";
  scripts.compile.exec = "compile_typst;pdftk out.pdf src/content/scientific_integrity.pdf cat output bsc_thesis_siegfried.pdf; rm out.pdf
";

  packages = with pkgs; [
    cascadia-code
    corefonts
    pdftk
  ];
}
