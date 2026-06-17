{ pkgs, ... }:

pkgs.callPackage ./bitbake/builder.nix {
  version = "2.10.0";
  hash = "sha256-FyC9tJTToY42526WUtjxY5DTLO19PkuJjtlwdhIvNEA=";
}
