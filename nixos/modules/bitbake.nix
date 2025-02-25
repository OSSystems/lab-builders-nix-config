{ lib
, pkgs
, config
, ...
}:

with lib;

let
  cfg = config.services.bitbake;
in
{
  options.services.bitbake = {
    enable = mkEnableOption "Bitbake service";

    package = mkPackageOption pkgs "bitbake" {  };

    hashServPort = mkOption {
      type = types.int;
      default = 8686;
    };

    prServPort = mkOption {
      type = types.int;
      default = 8685;
    };

    logLevel = mkOption {
      type = types.enum [
        "error"
        "warning"
        "info"
        "debug"
      ];
      default = "debug";
    };
  };

  config = mkIf cfg.enable {
    users = {
      groups.bitbake = { };
      users.bitbake = {
        group = "bitbake";
        isSystemUser = true;
      };
    };

    systemd.services.bitbake-hashserv = {
      description = "Bitbake Hash Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        User = "bitbake";
        Group = "bitbake";
        WorkingDirectory = "/var/lib/bitbake";
        Type = "simple";
        ExecStart = "${cfg.package}/bin/bitbake-hashserv --bind 0.0.0.0:${toString cfg.hashServPort} -l ${cfg.logLevel}";
        StateDirectory = "bitbake";
        StateDirectoryMode = 750;
      };
    };

    systemd.services.bitbake-prserv = {
      description = "Bitbake PR Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        User = "bitbake";
        Group = "bitbake";
        WorkingDirectory = "/var/lib/bitbake";
        Type = "simple";
        RemainAfterExit = "yes";
        ExecStart = "${cfg.package}/bin/bitbake-prserv --host 0.0.0.0 --port ${toString cfg.prServPort} --start -l ${cfg.logLevel}";
        ExecStop = "${cfg.package}/bin/bitbake-prserv --host 0.0.0.0 --port ${toString cfg.prServPort} --stop -l ${cfg.logLevel}";
        StateDirectory = "bitbake";
        StateDirectoryMode = 750;
      };
    };
  };
}
