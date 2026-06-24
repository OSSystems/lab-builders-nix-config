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

    attic = {
      url = "github:zhaofengli/attic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, red-tape, ... }:
    red-tape.mkFlake {
      inherit inputs self;
      src = ./.;
      prefix = "nix";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem = { system, ... }: {
        packages = builtins.listToAttrs (
          builtins.concatMap (
            hostName:
            let
              host = self.nixosConfigurations.${hostName};
            in
            if host.config.nixpkgs.hostPlatform.system == system then
              [
                {
                  name = "${hostName}-install-iso";
                  value = import ./nix/installer/iso.nix {
                    inherit inputs hostName;
                    flake = self;
                  };
                }
              ]
            else
              [ ]
          ) (builtins.attrNames self.nixosConfigurations)
        );
      };

      flake = {
        overlays = import ./nix/overlays {
          inherit inputs;
          outputs = self;
        };
      };
    };
}
