{ inputs, ... }:

{
  imports =
    with inputs.nixos-hardware.nixosModules;
    [
      common-cpu-amd
      common-pc-ssd
    ]
    ++ [
      ../features/required
      ../features/shared-state-yocto
      ../features/zram-swap.nix
      ./partitioning.nix
      ./microvm-runners.nix
    ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-amd" ];
  };
}
