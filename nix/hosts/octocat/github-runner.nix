{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

let
  prefix = "octocat-runner";
  organizations = {
    OSSystems = 3;
    shellhub-io = 9;
    GarniHQ = 9;
  };

  githubRunnerModules = "${inputs.nixpkgs-github-runners}/nixos/modules/services/continuous-integration/github-runner";

  runners = lib.concatLists (
    lib.mapAttrsToList (
      org: count: builtins.genList (x: "${prefix}-${org}-${toString (x + 1)}") count
    ) organizations
  );
in
{
  imports = [
    inputs.sops-nix.nixosModules.default
    "${githubRunnerModules}/options.nix"
    "${githubRunnerModules}/service.nix"
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
    nodeRuntimes = [ "node24" ];
    extraLabels = [ "nix" ];
    extraPackages = with pkgs; [
      cachix
      config.nix.package
      coreutils
      file
      gh
      glibc.bin
      jq
      nix-eval-jobs
      nodejs_24
      openssh
      openssl
      python3
      which
    ];
    serviceOverrides = {
      DeviceAllow = [ "/dev/kvm" ];
      PrivateDevices = false;
    };
  };

  programs.nix-ld.enable = true;

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

  systemd.services = builtins.listToAttrs (
    builtins.map (runner: {
      name = "github-runner-${runner}";
      value = {
        serviceConfig.User = runner;
        environment.GIT_SSH_COMMAND = "ssh -i $HOME/.ssh/id_rsa";
      };
    }) runners
  );

  sops = {
    defaultSopsFile = ../../../secrets/octocat.yaml;
    secrets.github-app-runner-private-key = { };
  };
}
