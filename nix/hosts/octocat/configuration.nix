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

  # Keeps usage history for `sar`. CI jobs come in bursts of minutes, so
  # sample each minute.
  services.sysstat = {
    enable = true;
    collect-frequency = "*:*:00";
  };
  # Above 28 days, sa2 moves the data files into monthly directories.
  environment.etc."sysconfig/sysstat".text = ''
    HISTORY=28
  '';
}
