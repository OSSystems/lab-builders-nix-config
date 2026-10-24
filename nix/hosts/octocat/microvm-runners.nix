# shellhub-io jobs run in throwaway microVMs; see
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
    url = "https://github.com/shellhub-io";
    name = "octocat-microvm";
    githubApp = {
      id = "4080784";
      privateKeyFile = config.sops.secrets.github-app-runner-private-key.path;
    };
    network.externalInterface = "enp6s0";
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
