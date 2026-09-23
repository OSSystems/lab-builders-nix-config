{
  config,
  inputs,
  pkgs,
  ...
}:

let
  count = 4;
  prefix = "monster-runner";

  githubRunnerModules = "${inputs.nixpkgs-github-runners}/nixos/modules/services/continuous-integration/github-runner";

  runners = builtins.genList (x: "${prefix}-${toString (x + 1)}") count;
in
{
  imports = [
    inputs.sops-nix.nixosModules.default
    "${githubRunnerModules}/options.nix"
    "${githubRunnerModules}/service.nix"
  ];

  disabledModules = [ "services/continuous-integration/github-runners.nix" ];

  services.github-runners = builtins.listToAttrs (
    builtins.map (runner: {
      name = runner;
      value = {
        enable = true;
        name = runner;
        url = "https://github.com/OSSystems";
        ephemeral = true;
        githubApp = {
          id = 4080784;
          login = "OSSystems";
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
          User = runner;
          DeviceAllow = [ "/dev/kvm" ];
          PrivateDevices = false;
        };
      };
    }) runners
  );

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
      value.environment.GIT_SSH_COMMAND = "ssh -i $HOME/.ssh/id_rsa";
    }) runners
  );

  sops = {
    defaultSopsFile = ../../../secrets/monster.yaml;
    secrets.github-app-runner-private-key = { };
  };
}
