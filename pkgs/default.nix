{ pkgs, ... }:

{
  host-scripts = pkgs.stdenv.mkDerivation {
    name = "host-scripts";
    src = ../scripts;
    installPhase = ''
      mkdir -p $out/bin
      cp -r * $out/bin
    '';
  };

  ossystems-tools = pkgs.callPackage ./ossystems-tools { };
  bitbake =pkgs.callPackage ./bitbake { };
}
