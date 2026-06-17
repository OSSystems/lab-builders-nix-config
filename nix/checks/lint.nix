{ pkgs, flake, ... }:

pkgs.runCommand "lint-code"
{ nativeBuildInputs = with pkgs; [ nixpkgs-fmt deadnix statix ]; } ''
  deadnix --fail ${flake}
  #statix check ${flake} # https://github.com/nerdypepper/statix/issues/75
  nixpkgs-fmt --check ${flake}
  touch $out
''
