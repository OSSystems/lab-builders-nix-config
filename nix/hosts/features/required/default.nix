{
  pkgs,
  inputs,
  hostName,
  flake,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    ../../../modules/nixos/bitbake.nix

    ./attic-client.nix
    ./auto-upgrade.nix
    ./console.nix
    ./disable-desktop-features.nix
    ./disk-scheduler.nix
    ./docker.nix
    ./firmware.nix
    ./home-manager.nix
    ./latest-linux-kernel.nix
    ./locale.nix
    ./network.nix
    ./nix.nix
    ./nixpkgs.nix
    ./no-mitigations.nix
    ./openssh.nix
    ./sudo.nix
    ./upgrade-diff.nix
    ./vscode-server.nix
    ./watchdog.nix

    ../../../users/aquino
    ../../../users/otavio
    ../../../users/rodrigo
    ../../../users/luciano
    ../../../users/samuel
  ];

  environment.systemPackages = [
    flake.packages.${pkgs.stdenv.hostPlatform.system}.host-scripts
    flake.packages.${pkgs.stdenv.hostPlatform.system}.ossystems-tools
  ];

  networking.hostName = hostName;

  system.stateVersion = "26.05";
}
