{ config, pkgs, ... }:
{
  languages.typst = {
    enable = true;
    fontPaths = [
      "${pkgs.cascadia-code}"
      "${pkgs.corefonts}"
    ];
  };

  # env.TYPST_ROOT = "${config.env.DEVENV_ROOT}/thesis/src";
  scripts.compile_thesis.exec = "typst compile --creation-timestamp=$(date +%s) $DEVENV_ROOT/thesis/src/main.typ out.pdf";
  scripts.compile.exec = "compile_thesis && pdftk out.pdf $DEVENV_ROOT/thesis/src/content/scientific_integrity.pdf cat output $DEVENV_ROOT/thesis/bsc_thesis_siegfried.pdf && rm out.pdf
";

  packages = with pkgs; [
    cascadia-code
    corefonts
    pdftk
  ];
}
