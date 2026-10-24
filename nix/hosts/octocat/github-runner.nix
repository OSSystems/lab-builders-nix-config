{
  inputs,
  config,
  lib,
  ...
}:

let
  prefix = "octocat-runner";
  organizations = {
    OSSystems = 3;
    GarniHQ = 9;
  };

  githubRunnerModules = "${inputs.nixpkgs-github-runners}/nixos/modules/services/continuous-integration/github-runner";

  runnersOf = org: builtins.genList (x: "${prefix}-${org}-${toString (x + 1)}") organizations.${org};
  runners = lib.concatMap runnersOf (builtins.attrNames organizations);
in
{
  imports = [
    inputs.sops-nix.nixosModules.default
    "${githubRunnerModules}/options.nix"
    "${githubRunnerModules}/service.nix"
    ./job-environment.nix
  ];
  disabledModules = [ "services/continuous-integration/github-runners.nix" ];
  services.github-runners.${prefix} = {
    enable = true;
    orgs = lib.mapAttrs (_: count: { inherit count; }) organizations;
    ephemeral = true;
    githubApp = {
      id = 4080784;
      privateKeyFile = config.sops.secrets.github-app-runner-private-key.path;
    };
    package = config.octocat.runnerPackage;
    nodeRuntimes = [
      "node20"
      "node24"
    ];
    extraLabels = [ "nix" ];
    extraPackages = config.octocat.jobPackages;
    serviceOverrides = {
      DeviceAllow = [ "/dev/kvm" ];
      PrivateDevices = false;
    };
  };
  virtualisation.docker.autoPrune.enable = true;
  systemd = {
    services = builtins.listToAttrs (
      builtins.map (runner: {
        name = "github-runner-${runner}";
        value = lib.mkMerge [
          {
            serviceConfig.User = runner;
            environment = {
              GIT_SSH_COMMAND = "ssh -i $HOME/.ssh/id_rsa";
              FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 = "true";
            };
          }
        ];
      }) runners
    );
  };
  nix.settings = {
    allowed-users = runners;
    trusted-users = runners;
  };
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
