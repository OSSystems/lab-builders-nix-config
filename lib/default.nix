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
        {
          networking.hostName = hostname;
        }
      ];
    }).config.system.build.isoImage;
}
