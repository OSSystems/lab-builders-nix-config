{ pkgs, ... }:

pkgs.callPackage (
  { stdenv }:
  stdenv.mkDerivation {
    name = "host-scripts";
    src = ../../scripts;
    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/bin
    '';
  }
) { }
