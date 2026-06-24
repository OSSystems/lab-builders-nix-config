{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "normalise_nix";
  runtimeInputs = with pkgs; [
    nixfmt
    statix
  ];
  text = ''
    set -o xtrace
    nixfmt "$@"
    statix fix "$@"
  '';
}
