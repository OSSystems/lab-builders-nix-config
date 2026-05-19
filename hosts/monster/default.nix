{ inputs, ... }:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-intel
    common-pc-ssd
  ] ++ [
    ../features/required
    ../features/shared-state-yocto
    ../features/zram-swap.nix
    ./partitioning.nix
  ];

  boot = {
    loader.grub.enable = true;

    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "usbhid" ];
    };

    kernelModules = [ "kvm-intel" ];
  };
}
