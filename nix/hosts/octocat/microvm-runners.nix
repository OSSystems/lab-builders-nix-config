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
    # VMs hold only the memory their job uses, so they may be given 30% more
    # than octocat has; zram absorbs the rare moment all of them peak.
    memOvercommit = 0.3;
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
        }
      )
    ];
  };
}
