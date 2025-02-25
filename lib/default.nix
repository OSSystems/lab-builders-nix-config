{ inputs, outputs }:

{
  mkSystem =
    { hostname
    , system
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs outputs;
      };

      modules = [
        inputs.disko.nixosModules.disko

        ../nixos/modules/bitbake.nix

        ../hosts/${hostname}
        {
          networking.hostName = hostname;
        }
      ];
    };

  mkInstallerForSystem =
    { hostname
    , targetConfiguration
    , system
    }:
    (inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs outputs targetConfiguration;
      };

      modules = [
        inputs.disko.nixosModules.disko

        ../hosts/installer

        {
          networking.hostName = hostname;
        }
      ];
    }).config.system.build.isoImage;
}
