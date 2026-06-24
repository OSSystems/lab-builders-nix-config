{ pkgs, flake, ... }:

pkgs.runCommand "lint-code"
  {
    nativeBuildInputs = with pkgs; [
      nixfmt
      deadnix
      statix
    ];
  }
  ''
    deadnix --fail ${flake}
    #statix check ${flake} # https://github.com/nerdypepper/statix/issues/75
    nixfmt --check ${flake}
    touch $out
  ''
