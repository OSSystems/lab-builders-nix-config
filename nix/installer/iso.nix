{ inputs, flake, hostName }:

let
  inherit (inputs.nixpkgs) lib;

  targetConfiguration = flake.nixosConfigurations.${hostName};
  inherit (targetConfiguration.config.nixpkgs.hostPlatform) system;

  iso = (lib.nixosSystem {
    specialArgs = {
      inherit flake inputs targetConfiguration hostName;
    };
    modules = [ ./configuration.nix ];
  }).config.system.build.isoImage;
in
lib.addMetaAttrs { platforms = [ system ]; } iso
