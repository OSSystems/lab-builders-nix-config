{ inputs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-pc-ssd
  ] ++ [
    ../features/required

    ../features/optional/desktop.nix
    ../features/optional/network-manager.nix
    ../features/optional/no-mitigations.nix
    ../features/optional/pipewire.nix
    ../features/optional/quietboot.nix
    ../features/optional/x11.nix
    ../features/optional/tmux.nix
    ../features/optional/zerotier.nix

    ./hardware-configuration.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };
}
