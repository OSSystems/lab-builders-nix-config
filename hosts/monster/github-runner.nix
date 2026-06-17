{ config, inputs, pkgs, ... }:

let
  runners = builtins.genList
    (x: "${config.roles.github-actions-runner.name}-${toString (x + 1)}")
    config.roles.github-actions-runner.count;
in
{
  imports = [
    inputs.srvos.nixosModules.roles-github-actions-runner
    inputs.sops-nix.nixosModules.default
  ];

  roles.github-actions-runner = {
    url = "https://github.com/OSSystems";
    count = 4;
    name = "monster-runner";
    githubApp = {
      id = "2203207";
      login = "OSSystems";
      privateKeyFile = config.sops.secrets.github-app-runner-private-key.path;
    };
    extraPackages = with pkgs; [
      gh
      openssl
      nodejs_24
      file
      coreutils
    ];
    nodeRuntimes = [ "node24" ];
  };

  sops = {
    defaultSopsFile = ../../secrets/monster.yaml;
    secrets.github-app-runner-private-key = { };
  };

  nix.settings = {
    trusted-users = runners;
    allowed-users = runners;
  };
}
