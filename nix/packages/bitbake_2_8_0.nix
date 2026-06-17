{ pkgs, ... }:

pkgs.callPackage ./bitbake/builder.nix {
  version = "2.8.0";
  hash = "sha256-wrI+SaS3g15i8EyR76CN8ZNKtVm9+TefUMP1/8Avx64=";
}
