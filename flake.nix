{
  description = "Otavio Salvador's NixOS/Home Manager config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nixos-hardware.url = "nixos-hardware";
    disko.url = "github:nix-community/disko";

    # users
    users-otavio.url = "github:otavio/nix-config/2ffea343a5bf4cba0191064900545072149500e0";
  };

  outputs = { self, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (import ./lib { inherit inputs outputs; }) mkSystem mkInstallerForSystem;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forEachSystem = f: inputs.nixpkgs.lib.genAttrs systems (sys: f pkgsFor.${sys});
      pkgsFor = inputs.nixpkgs.legacyPackages;
    in
    {
      overlays = import ./overlays { inherit inputs outputs; };

      nixosConfigurations = {
        centrium = mkSystem {
          hostname = "centrium";
          system = "x86_64-linux";
        };

        hyper = mkSystem {
          hostname = "hyper";
          system = "x86_64-linux";
        };

        pikachu = mkSystem {
          hostname = "pikachu";
          system = "x86_64-linux";
        };
      };

      packages = builtins.foldl'
        (packages: hostname:
          let
            inherit (self.nixosConfigurations.${hostname}.config.nixpkgs) system;
            targetConfiguration = self.nixosConfigurations.${hostname};
          in
          packages // {
            ${system} = (packages.${system} or { }) // {
              "${hostname}-install-iso" = mkInstallerForSystem { inherit hostname targetConfiguration system; };
            };
          })
        (forEachSystem (pkgs: import ./pkgs { inherit pkgs; }))
        (builtins.attrNames self.nixosConfigurations);

      formatter = forEachSystem (pkgs: pkgs.writeShellApplication {
        name = "normalise_nix";
        runtimeInputs = with pkgs; [ nixpkgs-fmt statix ];
        text = ''
          set -o xtrace
          nixpkgs-fmt "$@"
          statix fix "$@"
        '';
      });

      checks = forEachSystem (pkgs: {
        lint = pkgs.runCommand "lint-code" { nativeBuildInputs = with pkgs; [ nixpkgs-fmt deadnix statix ]; } ''
          deadnix --fail ${./.}
          #statix check ${./.} # https://github.com/nerdypepper/statix/issues/75
          nixpkgs-fmt --check ${./.}
          touch $out
        '';
      });
    };
}
