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

    versions = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          package = mkPackageOption pkgs [ "bitbakePackages" name ] { };

          hashServPort = mkOption {
            type = types.int;
            default = 8686;
          };

          prServPort = mkOption {
            type = types.int;
            default = 8685;
          };

          logLevel = mkOption {
            type = types.enum [ "error" "warning" "info" "debug" ];
            default = "info";
          };
        };
      }));
      default = { };
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

    networking.firewall.allowedTCPPorts = mkMerge (mapAttrsToList
      (_: settings: [ settings.hashServPort settings.prServPort ])
      cfg.versions);

    systemd.services = mkMerge (mapAttrsToList
      (name: settings: {
        "bitbake-hashserv-${name}" = {
          description = "Bitbake Hash Server (${name})";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            User = "bitbake";
            Group = "bitbake";
            WorkingDirectory = "/var/lib/bitbake/${name}";
            Type = "simple";
            ExecStart = "${settings.package}/bin/bitbake-hashserv --bind 0.0.0.0:${toString settings.hashServPort} -l ${settings.logLevel}";
            StateDirectory = "bitbake/${name}";
            StateDirectoryMode = 750;
          };
        };

        "bitbake-prserv-${name}" = {
          description = "Bitbake PR Server (${name})";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            User = "bitbake";
            Group = "bitbake";
            WorkingDirectory = "/var/lib/bitbake/${name}";
            Type = "simple";
            RemainAfterExit = "yes";
            ExecStart = "${settings.package}/bin/bitbake-prserv --host 0.0.0.0 --port ${toString settings.prServPort} --start -l ${settings.logLevel}";
            ExecStop = "${settings.package}/bin/bitbake-prserv --host 0.0.0.0 --port ${toString settings.prServPort} --stop -l ${settings.logLevel}";
            StateDirectory = "bitbake/${name}";
            StateDirectoryMode = 750;
          };
        };
      })
      cfg.versions);
  };
}
