{
  boot.supportedFilesystems = [ "nfs" ];
  boot.kernelParams = [ "nfs.nfs4_disable_idmapping=0" "nfsd.nfs4_disable_idmapping=0" ];

  users.groups.builder = { };

  users.users.rodrigo.extraGroups = [ "builder" ];
  users.users.otavio.extraGroups = [ "builder" ];

  system.activationScripts.srv =
    ''
      mkdir -p /srv/yocto/download-cache
      mkdir -p /srv/yocto/sstate-cache
    '';

  fileSystems."/srv/yocto/sstate-cache" = {
    device = "10.5.3.187:/srv/nfs/yocto/sstate-cache";
    fsType = "nfs";
    options = [ "auto" "rw" "defaults" "_netdev" "x-systemd.automount" ];
  };

  fileSystems."/srv/yocto/download-cache" = {
    device = "10.5.3.187:/srv/nfs/yocto/download-cache";
    fsType = "nfs";
    options = [ "auto" "rw" "defaults" "_netdev" "x-systemd.automount" ];
  };
}
