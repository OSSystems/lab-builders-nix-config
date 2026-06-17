{
  description = "Otavio Salvador's NixOS/Home Manager config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";

    red-tape = {
      url = "github:phaer/red-tape";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code-overlay = {
      url = "github:ryoppippi/claude-code-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nixos-hardware.url = "nixos-hardware";
    disko.url = "github:nix-community/disko";

    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, red-tape, ... }:
    let
      mkInstallerForSystem = { hostname, targetConfiguration }:
        (inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            flake = self;
            inherit inputs targetConfiguration;
            hostName = hostname;
          };
          modules = [ ./nix/installer/configuration.nix ];
        }).config.system.build.isoImage;

      installerPackages = builtins.foldl'
        (packages: hostname:
          let
            targetConfiguration = self.nixosConfigurations.${hostname};
            inherit (targetConfiguration.config.nixpkgs.hostPlatform) system;
          in
          packages // {
            ${system} = (packages.${system} or { }) // {
              "${hostname}-install-iso" = mkInstallerForSystem { inherit hostname targetConfiguration; };
            };
          })
        { }
        (builtins.attrNames self.nixosConfigurations);
    in
    red-tape.mkFlake {
      inherit inputs self;
      src = ./.;
      prefix = "nix";
      systems = [ "x86_64-linux" "aarch64-linux" ];

      flake = {
        overlays = import ./nix/overlays { inherit inputs; outputs = self; };
        packages = installerPackages;
      };
    };
}
