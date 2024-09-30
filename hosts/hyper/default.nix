{ inputs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-pc-ssd
  ] ++ [
    ../features/required
    ../features/zram-swap.nix
    ./partitioning.nix
  ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.efi.efiSysMountPoint = "/boot";

    initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" ];
    initrd.kernelModules = [ ];

    kernelModules = [ "kvm-intel" ];
  };
}
