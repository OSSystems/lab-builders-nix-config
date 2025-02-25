{
  lib,
  nix-update-script,
  python3,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication rec {
  pname = "bitbake";
  version = "2.8";
  pyproject = false;

  src = fetchFromGitHub {
    owner = "openembedded";
    repo = pname;
    rev = version;
    hash = "sha256-IKUBQtMzP1YgXN+hgcm1hOboeZTe47kHJVq7oH1oyYQ=";
  };

  passthru.updateScript = nix-update-script { };

  installPhase = ''
    mkdir -p $out/lib
    cp -r $src/lib $out
    cp -r $src/bin $out
  '';

  meta = with lib; {
    description = "Bitbake";
    mainProgram = "bitbake";
    homepage = "https://github.com/openembedded/bitbake";
    changelog = "https://github.com/Freed-Wu/bitbake-language-server/releases/tag/${version}";
    license = lib.licenses.gpl3;
    maintainers = [ lib.maintainers.otavio ];
  };
}
