# shellhub-io runners as one throwaway microVM per job. octocat-scaleset boots
# VMs from the pool while the host has room, each with a fresh disk and a
# just-in-time runner config, so the GitHub App key never enters a VM and
# nothing outlives the job.
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  bridge = "microbr";
  subnet = "10.231.0";
  hostAddress = "${subnet}.1";
  nixDaemonPort = 5000;
  poolSize = 8;
  vmMemGiB = 10;
  octocat-scaleset = import ../../packages/octocat-scaleset { inherit pkgs; };

  slots = builtins.genList (i: {
    name = "octocat-microvm-${toString (i + 1)}";
    index = i + 1;
  }) poolSize;
  slotNames = map (s: s.name) slots;
in
{
  imports = [ inputs.microvm.nixosModules.host ];

  microvm.vms = lib.listToAttrs (
    map (slot: {
      inherit (slot) name;
      value = {
        # octocat-scaleset starts VMs on demand; a deploy must not kill a
        # running job, the next boot picks up the new system.
        autostart = false;
        restartIfChanged = false;
        specialArgs = { inherit inputs; };
        config = {
          imports = [
            ./job-environment.nix
            ./microvm-runner-guest.nix
          ];
          octocat.microvm = {
            inherit (slot) name;
            inherit hostAddress nixDaemonPort;
            address = "${subnet}.${toString (10 + slot.index)}";
            mac = "02:00:0a:e7:00:${lib.fixedWidthString 2 "0" (lib.toHexString slot.index)}";
            tap = "vm-shrun${toString slot.index}";
            cid = 2 + slot.index;
            mem = vmMemGiB * 1024;
          };
        };
      };
    }) slots
  );

  users = {
    users.microvm-nix = {
      isSystemUser = true;
      group = "microvm-nix";
    };
    groups.microvm-nix = { };
  };
  # Guests build through the host daemon as this untrusted user, so builds and
  # their cache land in the host store while guests only see it read-only.
  nix.settings.allowed-users = [ "microvm-nix" ];

  systemd = {
    services = {
      octocat-scaleset = {
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = [ config.systemd.package ];
        serviceConfig = {
          ExecStart = lib.escapeShellArgs [
            (lib.getExe octocat-scaleset)
            "--url=https://github.com/shellhub-io"
            "--name=octocat-microvm"
            "--labels=octocat-microvm"
            "--app-id=4080784"
            "--private-key-file=${config.sops.secrets.github-app-runner-private-key.path}"
            "--slots=${lib.concatStringsSep "," slotNames}"
            "--vm-mem=${toString vmMemGiB}"
          ];
          Restart = "always";
          RestartSec = "10s";
        };
      };

      microvm-nix-daemon = {
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.socat} VSOCK-LISTEN:${toString nixDaemonPort},fork,reuseaddr UNIX-CONNECT:/nix/var/nix/daemon-socket/socket";
          User = "microvm-nix";
          Group = "microvm-nix";
          Restart = "always";
        };
      };
    }
    // lib.genAttrs (map (n: "microvm@${n}") slotNames) (_: {
      # A VM powers off after its one job and waits for octocat-scaleset.
      serviceConfig.Restart = lib.mkForce "no";
    });

    tmpfiles.rules = map (n: "d /run/microvm-jit/${n} 0750 root kvm -") slotNames;

    network = {
      enable = true;
      wait-online.enable = false;
      # NetworkManager owns the uplink; networkd only runs the VM bridge.
      config.networkConfig = {
        ManageForeignRoutes = false;
        ManageForeignRoutingPolicyRules = false;
      };
      netdevs."20-${bridge}".netdevConfig = {
        Kind = "bridge";
        Name = bridge;
      };
      networks = {
        "20-${bridge}" = {
          matchConfig.Name = bridge;
          address = [ "${hostAddress}/24" ];
          networkConfig.ConfigureWithoutCarrier = true;
          linkConfig.RequiredForOnline = "no";
        };
        "21-microvm-taps" = {
          matchConfig.Name = "vm-shrun*";
          networkConfig.Bridge = bridge;
          linkConfig.RequiredForOnline = "no";
        };
      };
    };
  };

  networking = {
    networkmanager.unmanaged = [
      "interface-name:${bridge}"
      "interface-name:vm-shrun*"
    ];
    nat = {
      enable = true;
      internalInterfaces = [ bridge ];
      externalInterface = "enp6s0";
    };
    # Guests reach the internet, nothing on the host or the lab network.
    firewall = {
      extraCommands = ''
        iptables -N microvm-in 2>/dev/null || iptables -F microvm-in
        iptables -A microvm-in -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
        iptables -A microvm-in -j DROP
        iptables -D INPUT -i ${bridge} -j microvm-in 2>/dev/null || true
        iptables -I INPUT -i ${bridge} -j microvm-in

        iptables -N microvm-fwd 2>/dev/null || iptables -F microvm-fwd
        for net in 10.0.0.0/8 100.64.0.0/10 169.254.0.0/16 172.16.0.0/12 192.168.0.0/16; do
          iptables -A microvm-fwd -d "$net" -j DROP
        done
        iptables -D FORWARD -i ${bridge} -j microvm-fwd 2>/dev/null || true
        iptables -I FORWARD -i ${bridge} -j microvm-fwd
      '';
      extraStopCommands = ''
        iptables -D INPUT -i ${bridge} -j microvm-in 2>/dev/null || true
        iptables -D FORWARD -i ${bridge} -j microvm-fwd 2>/dev/null || true
      '';
    };
  };
}
