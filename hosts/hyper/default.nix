{ inputs, pkgs, ... }:

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

    kernelParams = [ "nfs.nfs4_disable_idmapping=0" "nfsd.nfs4_disable_idmapping=0" ];
  };

  users.groups.builder = { };

  networking.firewall.allowedTCPPorts = [ 2049 ];

  system.activationScripts.srv =
    ''
      mkdir -p /srv/nfs/yocto/download-cache
      mkdir -p /srv/nfs/yocto/sstate-cache

      chown nobody:nogroup /srv/nfs/yocto/download-cache
      chown nobody:nogroup /srv/nfs/yocto/sstate-cache

      chmod -R g+s /srv/nfs/yocto/*

      chown -R root:builder /srv/nfs/yocto/*
      chmod -R 775 /srv/nfs/yocto/*
      ${pkgs.acl}/bin/setfacl -m d:u::rwX,d:g::rwX,d:o::rX /srv/nfs/yocto/*
    '';

  services.nfs.server = {
    enable = true;
    createMountPoints = true;
    exports = ''
      /srv/nfs/yocto/download-cache 10.5.0.0/16(rw,sync,nohide,insecure,no_subtree_check,all_squash,anonuid=0,anongid=1001)
      /srv/nfs/yocto/sstate-cache 10.5.0.0/16(rw,sync,nohide,insecure,no_subtree_check,all_squash,anonuid=0,anongid=1001)
    '';
  };

  services.bitbake = {
    enable = true;
    versions = {
      "scarthgap" = {
        package = pkgs.bitbakePackages.bitbake_2_8_0;
        hashServPort = 8686;
        prServPort = 8685;
      };
      "styhead" = {
        package = pkgs.bitbakePackages.bitbake_2_10_2;
        hashServPort = 8786;
        prServPort = 8785;
      };
    };
  };
}
