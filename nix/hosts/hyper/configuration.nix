{
  inputs,
  pkgs,
  flake,
  ...
}:

let
  inherit (flake.packages.${pkgs.stdenv.hostPlatform.system}) bitbake_2_10_0 bitbake_2_8_0;
in
{
  imports =
    with inputs.nixos-hardware.nixosModules;
    [
      common-cpu-intel
      common-pc-ssd
    ]
    ++ [
      ../features/required
      ../features/zram-swap.nix
      ./partitioning.nix
    ];
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "nfs.nfs4_disable_idmapping=0"
      "nfsd.nfs4_disable_idmapping=0"
    ];
  };
  users.groups.builder = { };
  networking.firewall.allowedTCPPorts = [ 2049 ];
  system.activationScripts.srv = ''
    mkdir -p /srv/nfs/yocto/download-cache
    mkdir -p /srv/nfs/yocto/sstate-cache

    chown nobody:nogroup /srv/nfs/yocto/download-cache
    chown nobody:nogroup /srv/nfs/yocto/sstate-cache

    chmod -R g+s /srv/nfs/yocto/*

    chown -R root:builder /srv/nfs/yocto/*
    chmod -R 775 /srv/nfs/yocto/*
    ${pkgs.acl}/bin/setfacl -m d:u::rwX,d:g::rwX,d:o::rX /srv/nfs/yocto/*
  '';
  services = {
    nfs = {
      server = {
        enable = true;
        createMountPoints = true;
        exports = ''
          /srv/nfs/yocto/download-cache 10.5.0.0/16(rw,sync,nohide,insecure,no_subtree_check,all_squash,anonuid=0,anongid=1001)
          /srv/nfs/yocto/sstate-cache 10.5.0.0/16(rw,sync,nohide,insecure,no_subtree_check,all_squash,anonuid=0,anongid=1001)
        '';
      };
      # Cap the server at NFSv4.1. NFSv4.2's READ_PLUS (sparse-aware reads) corrupts
      # large multi-GB files read back over this share: BitBake's git pack mirrors
      # (linux/u-boot, >4GB) come back with mangled bytes, so do_unpack / devtool
      # modify fail with zlib "inflate: data stream error / pack checksum mismatch"
      # at varying offsets, while a clone of the same repo to local disk is
      # bit-perfect. Disabling 4.2 makes clients negotiate down to 4.1 (no
      # READ_PLUS), which the shared Yocto cache doesn't otherwise need.
      settings.nfsd."vers4.2" = false;
    };
    bitbake = {
      enable = true;
      versions = {
        scarthgap = {
          package = bitbake_2_8_0;
          hashServPort = 8686;
          prServPort = 8685;
        };
        styhead = {
          package = bitbake_2_10_0;
          hashServPort = 8786;
          prServPort = 8785;
        };
      };
    };
  };
}
