{ pkgs, ... }:

{
  imports = [
    ./auto-upgrade.nix
    ./console.nix
    ./disable-desktop-features.nix
    ./disable-global-dhcp.nix
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

    ../../../users/abner
    ../../../users/aquino
    ../../../users/otavio
    ../../../users/rodrigo
  ];

  environment.systemPackages = with pkgs; [
    host-scripts
    ossystems-tools
  ];

  system.stateVersion = "23.05";
}
