{ config, ... }:
{
  languages.typst.enable = true;
  env.TYPST_ROOT = "${config.env.DEVENV_ROOT}/src";
  scripts.compile.exec = "typst compile $DEVENV_ROOT/src/main.typ bsc_thesis_siegfried.pdf";
}
