# Jobs run in throwaway microVMs from one pool shared by all organizations,
# so one that is idle leaves its VMs to the others; see
# https://github.com/OSSystems/microvm-github-runners.
{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    inputs.microvm-github-runners.nixosModules.default
    inputs.sops-nix.nixosModules.default
    ./job-environment.nix
  ];

  services.microvm-github-runners = {
    enable = true;
    urls = [
      "https://github.com/shellhub-io"
      "https://github.com/OSSystems"
      "https://github.com/GarniHQ"
      "https://github.com/archon-trading"
    ];
    name = "octocat-microvm";
    labels = [
      "octocat-microvm"
      "self-hosted"
      "Linux"
      "X64"
      "nix"
    ];
    githubApp = {
      id = "4080784";
      privateKeyFile = config.sops.secrets.github-app-runner-private-key.path;
    };
    network.externalInterface = "enp6s0";
    # CPU weights share busy processors.
    maxLoadPerCpu = 4.0;
    guestModules = [
      ./job-environment.nix
      (
        { config, ... }:
        {
          microvm-github-runner = {
            package = config.octocat.runnerPackage;
            packages =
              config.octocat.jobPackages
              ++ (with pkgs; [
                wineWowPackages.stable
                yarn
              ]);
            environment.FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 = "true";
          };
          # Actions written for other runners use a #!/bin/bash shebang.
          systemd.tmpfiles.rules = [ "L+ /bin/bash - - - - ${pkgs.bashInteractive}/bin/bash" ];
          # Absorb allocation spikes while the host hotplugs more guest memory.
          zramSwap = {
            enable = true;
            memoryPercent = 100;
          };
        }
      )
    ];
  };

  # CI builds use the host daemon and must compete fairly with VM workloads.
  nix.daemonCPUSchedPolicy = lib.mkForce "other";
  virtualisation.docker.autoPrune.enable = true;
  boot.runSize = "75%";
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16384;
    }
  ];
  sops = {
    defaultSopsFile = ../../../secrets/octocat.yaml;
    secrets.github-app-runner-private-key = { };
  };
}
