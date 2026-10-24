{ pkgs, ... }:

pkgs.buildGoModule {
  pname = "octocat-scaleset";
  version = "0.1.0";
  src = ./.;
  vendorHash = "sha256-4Sy0Y/IXPhEwSlLX1CTECs9hISt+ao7wB8CddmJ5Qik=";
  env.CGO_ENABLED = 0;
  meta.mainProgram = "octocat-scaleset";
}
