# shellhub-io runners as one throwaway microVM per job. Each boot gets a fresh
# disk and a just-in-time runner config minted here, so the GitHub App key
# never enters a VM and nothing outlives the job.
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
  mirrorPort = 5000;
  org = "shellhub-io";

  vms = {
    octocat-microvm-1 = {
      index = 1;
      labels = [ "octocat-microvm" ];
    };
  };

  appToken = "${inputs.nixpkgs-github-runners}/nixos/modules/services/continuous-integration/github-runner/app-token.sh";

  mintJitConfig = pkgs.writeShellApplication {
    name = "mint-jit-config";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      curl
      jq
      openssl
    ];
    text = ''
      name=$1
      labels=$2
      out=$3

      token=$(APP_ID=4080784 APP_LOGIN=${org} \
        APP_PRIVATE_KEY=$(<${config.sops.secrets.github-app-runner-private-key.path}) \
        bash ${appToken})

      jq -n --arg name "$name-$(date +%s)" --argjson labels "$labels" \
        '{name: $name, runner_group_id: 1, labels: $labels, work_folder: "_work"}' |
        curl -fsS -X POST \
          -H "Authorization: Bearer $token" \
          -H "Accept: application/vnd.github+json" \
          -H "X-GitHub-Api-Version: 2022-11-28" \
          --data @- \
          https://api.github.com/orgs/${org}/actions/runners/generate-jitconfig |
        jq -er .encoded_jit_config >"$out.tmp"
      chmod 0400 "$out.tmp"
      mv "$out.tmp" "$out"
    '';
  };
in
{
  imports = [ inputs.microvm.nixosModules.host ];

  microvm.vms = lib.mapAttrs (name: vm: {
    restartIfChanged = true;
    specialArgs = { inherit inputs; };
    config = {
      imports = [
        ./job-environment.nix
        ./microvm-runner-guest.nix
      ];
      octocat.microvm = {
        inherit hostAddress mirrorPort name;
        address = "${subnet}.${toString (10 + vm.index)}";
        mac = "02:00:0a:e7:00:${lib.fixedWidthString 2 "0" (lib.toHexString vm.index)}";
        tap = "vm-shrun${toString vm.index}";
      };
    };
  }) vms;

  systemd = {
    services = lib.mapAttrs' (
      name: vm:
      lib.nameValuePair "microvm@${name}" {
        serviceConfig.ExecStartPre = [
          "+${lib.getExe mintJitConfig} ${name} ${
            lib.escapeShellArg (
              builtins.toJSON (
                [
                  "self-hosted"
                  "Linux"
                  "X64"
                ]
                ++ vm.labels
              )
            )
          } /run/microvm-jit/${name}/jitconfig"
        ];
      }
    ) vms;
    tmpfiles.rules = lib.mapAttrsToList (name: _: "d /run/microvm-jit/${name} 0700 root root -") vms;

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
    firewall = {
      interfaces.${bridge}.allowedTCPPorts = [ mirrorPort ];
      # Guests reach the internet and the registry mirror, nothing else on the
      # host or the lab network.
      extraCommands = ''
        iptables -N microvm-in 2>/dev/null || iptables -F microvm-in
        iptables -A microvm-in -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
        iptables -A microvm-in -p tcp --dport ${toString mirrorPort} -j RETURN
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

  # Docker Hub pull-through cache. Pushes are rejected in proxy mode, so guests
  # can only read from it.
  services.dockerRegistry = {
    enable = true;
    listenAddress = "0.0.0.0";
    port = mirrorPort;
    extraConfig.proxy.remoteurl = "https://registry-1.docker.io";
  };
}
