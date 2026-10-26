# Jobs run in throwaway microVMs from one pool shared by all organizations,
# so one that is idle leaves its VMs to the others; see
# https://github.com/OSSystems/microvm-github-runners.
{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [ inputs.microvm-github-runners.nixosModules.default ];

  services.microvm-github-runners = {
    enable = true;
    urls = [
      "https://github.com/shellhub-io"
      "https://github.com/OSSystems"
      "https://github.com/GarniHQ"
    ];
    name = "octocat-microvm";
    githubApp = {
      id = "4080784";
      privateKeyFile = config.sops.secrets.github-app-runner-private-key.path;
    };
    network.externalInterface = "enp6s0";
    # Keep 10 GiB for memory-heavy jobs. Allow up to ten VMs, with each boot
    # batch also limited by MemAvailable above the 8 GiB host reserve.
    vm.memGiB = 10;
    memReserveGiB = 8;
    memOvercommit = 1.0;
    poolSize = 16;
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
        }
      )
    ];
  };
}
