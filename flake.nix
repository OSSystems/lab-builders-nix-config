{
  description = "Otavio Salvador's NixOS/Home Manager config";
  inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # users
    users-otavio.url = "github:otavio/nix-config/2ffea343a5bf4cba0191064900545072149500e0";
  };

  outputs = { self, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (import ./lib { inherit inputs outputs; }) mkSystem;
      systems = [ "x86_64-linux" ];
      forEachSystem = f: inputs.nixpkgs.lib.genAttrs systems (sys: f pkgsFor.${sys});
      pkgsFor = inputs.nixpkgs.legacyPackages;
    in
    {
      overlays = import ./overlays { inherit inputs outputs; };

      nixosConfigurations = {
        pikachu = mkSystem {
          hostname = "pikachu";
          system = "x86_64-linux";
        };
      };

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
