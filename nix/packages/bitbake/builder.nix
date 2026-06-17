{ lib
, nix-update-script
, python3
, fetchFromGitHub
, version
, hash
}:

python3.pkgs.buildPythonApplication {
  pname = "bitbake";
  inherit version;
  pyproject = false;

  src = fetchFromGitHub {
    owner = "openembedded";
    repo = "bitbake";
    rev = version;
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
}
