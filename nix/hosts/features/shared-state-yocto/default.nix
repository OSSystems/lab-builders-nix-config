{
  boot = {
    supportedFilesystems = [ "nfs" ];
    kernelParams = [
      "nfs.nfs4_disable_idmapping=0"
      "nfsd.nfs4_disable_idmapping=0"
    ];
  };
  users = {
    groups.builder = { };
    users = {
      rodrigo.extraGroups = [ "builder" ];
      otavio.extraGroups = [ "builder" ];
      luciano.extraGroups = [ "builder" ];
    };
  };
  system.activationScripts.srv = ''
    mkdir -p /srv/yocto/download-cache
    mkdir -p /srv/yocto/sstate-cache
  '';
  fileSystems = {
    # Pin NFSv4.1 on both shares. NFSv4.2's READ_PLUS corrupts large-file reads,
    # so multi-GB BitBake git pack mirrors come back mangled and do_unpack /
    # devtool modify fail with zlib "inflate: data stream error". The hyper server
    # also disables 4.2, but pinning here keeps clients on 4.1 regardless.
    "/srv/yocto/sstate-cache" = {
      device = "10.5.3.187:/srv/nfs/yocto/sstate-cache";
      fsType = "nfs";
      options = [
        "auto"
        "rw"
        "defaults"
        "nfsvers=4.1"
        "_netdev"
        "x-systemd.automount"
      ];
    };
    "/srv/yocto/download-cache" = {
      device = "10.5.3.187:/srv/nfs/yocto/download-cache";
      fsType = "nfs";
      options = [
        "auto"
        "rw"
        "defaults"
        "nfsvers=4.1"
        "_netdev"
        "x-systemd.automount"
      ];
    };
  };
}
