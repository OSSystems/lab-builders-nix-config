# A shellhub-io runner VM: runs one job with the just-in-time config the host
# minted for this boot, then powers off.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.octocat.microvm;
in
{
  options.octocat.microvm =
    lib.genAttrs [
      "name"
      "address"
      "hostAddress"
      "mac"
      "tap"
    ] (_: lib.mkOption { type = lib.types.str; })
    // {
      mirrorPort = lib.mkOption { type = lib.types.port; };
    };

  config = {
    system.stateVersion = "26.05";
    networking = {
      hostName = cfg.name;
      useDHCP = false;
    };
    microvm = {
      hypervisor = "qemu";
      vcpu = 8;
      mem = 16384;
      interfaces = [
        {
          type = "tap";
          id = cfg.tap;
          inherit (cfg) mac;
        }
      ];
      shares = [
        {
          proto = "virtiofs";
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          readOnly = true;
        }
        {
          proto = "virtiofs";
          tag = "jit";
          source = "/run/microvm-jit/${cfg.name}";
          mountPoint = "/run/jit";
          readOnly = true;
        }
      ];
      # Docker data, the runner workspace and home all live here, and the image
      # is deleted before every boot.
      volumes = [
        {
          image = "var.img";
          mountPoint = "/var";
          size = 100 * 1024;
        }
      ];
      preStart = "rm -f var.img";
    };
    systemd = {
      network = {
        enable = true;
        networks."10-uplink" = {
          matchConfig.MACAddress = cfg.mac;
          address = [ "${cfg.address}/24" ];
          gateway = [ cfg.hostAddress ];
          dns = [
            "1.1.1.1"
            "8.8.8.8"
          ];
        };
      };
      services.github-runner = {
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "docker.service"
        ];
        path =
          config.octocat.jobPackages
          ++ (with pkgs; [
            bash
            findutils
            git
            gnugrep
            gnused
            gnutar
            gzip
            sudo
            wineWowPackages.stable
            yarn
          ]);
        environment = {
          RUNNER_ROOT = "/var/lib/github-runner";
          FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 = "true";
        };
        unitConfig = {
          SuccessAction = "poweroff";
          FailureAction = "poweroff";
        };
        serviceConfig = {
          User = "runner";
          StateDirectory = "github-runner";
          WorkingDirectory = "/var/lib/github-runner";
          LoadCredential = "jitconfig:/run/jit/jitconfig";
          ExecStart = pkgs.writeShellScript "github-runner-jit" ''
            exec ${config.octocat.runnerPackage}/bin/Runner.Listener run \
              --jitconfig "$(<"$CREDENTIALS_DIRECTORY/jitconfig")"
          '';
          KillSignal = "SIGINT";
        };
      };
    };
    virtualisation.docker.daemon.settings = {
      registry-mirrors = [ "http://${cfg.hostAddress}:${toString cfg.mirrorPort}" ];
      insecure-registries = [ "${cfg.hostAddress}:${toString cfg.mirrorPort}" ];
    };
    users.users.runner = {
      isNormalUser = true;
      home = "/var/lib/runner";
      extraGroups = [
        "docker"
        "wheel"
      ];
    };
    security.sudo.wheelNeedsPassword = false;
  };
}
