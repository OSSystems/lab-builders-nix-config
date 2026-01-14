{ lib
, nix-update-script
, python3
, fetchFromGitHub
}:

let
  mkBitbake = { version, hash, ... }@attrs:
    let
      attrs' = builtins.removeAttrs attrs [ "version" "hash" ];
    in
    python3.pkgs.buildPythonApplication
      (rec{
        pname = "bitbake";
        inherit version;
        pyproject = false;

        src = fetchFromGitHub {
          owner = "openembedded";
          repo = pname;
          rev = "${version}";
          inherit hash;
        };

        passthru.updateScript = nix-update-script { };

        installPhase = ''
          mkdir -p $out/lib
          cp -r $src/lib $out
          cp -r $src/bin $out
        '';

        meta = {
          description = "Bitbake";
          mainProgram = "bitbake";
          homepage = "https://github.com/openembedded/bitbake";
          license = lib.licenses.gpl2;
          maintainers = [ lib.maintainers.otavio ];
        };
      } // attrs');
in
rec {
  bitbake_2_8_0 = mkBitbake {
    version = "2.8.0";
    hash = "sha256-wrI+SaS3g15i8EyR76CN8ZNKtVm9+TefUMP1/8Avx64=";
  };

  bitbake_2_10_2 = mkBitbake {
    version = "2.10.2";
    hash = "sha256-cLlJkGva00m4L67AoHQQi3k2SSLSTbtF34WMDz8AKK4=";
  };
}
