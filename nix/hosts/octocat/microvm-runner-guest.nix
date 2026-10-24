# A shellhub-io runner VM: runs one job with the just-in-time config the host
# handed it for this boot, then powers off.
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
    // lib.genAttrs [
      "cid"
      "mem"
      "nixDaemonPort"
    ] (_: lib.mkOption { type = lib.types.int; });

  config = {
    system.stateVersion = "26.05";
    # systemd picks up the JIT config from fw_cfg before the root is mounted.
    boot.initrd.kernelModules = [ "qemu_fw_cfg" ];
    networking = {
      hostName = cfg.name;
      useDHCP = false;
    };
    microvm = {
      hypervisor = "qemu";
      vcpu = 8;
      inherit (cfg) mem;
      vsock.cid = cfg.cid;
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
      ];
      credentialFiles.jitconfig = "/run/microvm-jit/${cfg.name}/jitconfig";
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
      sockets.nix-daemon-proxy = {
        wantedBy = [ "sockets.target" ];
        socketConfig = {
          ListenStream = "/nix/var/nix/daemon-socket/socket";
          Accept = true;
        };
      };
      services = {
        "nix-daemon-proxy@".serviceConfig = {
          ExecStart = "${lib.getExe pkgs.socat} STDIO VSOCK-CONNECT:2:${toString cfg.nixDaemonPort}";
          StandardInput = "socket";
        };
        github-runner = {
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
            inherit (config.environment.variables) NIX_CONFIG NIX_REMOTE;
          };
          unitConfig = {
            SuccessAction = "poweroff";
            FailureAction = "poweroff";
          };
          serviceConfig = {
            User = "runner";
            StateDirectory = "github-runner";
            WorkingDirectory = "/var/lib/github-runner";
            ImportCredential = "jitconfig";
            ExecStart = pkgs.writeShellScript "github-runner-jit" ''
              exec ${config.octocat.runnerPackage}/bin/Runner.Listener run \
                --jitconfig "$(<"$CREDENTIALS_DIRECTORY/jitconfig")"
            '';
            KillSignal = "SIGINT";
          };
        };
      };
    };
    # Nix talks to the host's daemon over vsock; the store itself is the
    # host's, read-only.
    nix.enable = false;
    environment.variables = {
      NIX_REMOTE = "daemon";
      NIX_CONFIG = "experimental-features = nix-command flakes";
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
