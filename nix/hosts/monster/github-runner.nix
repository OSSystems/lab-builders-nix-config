{ config, inputs, pkgs, ... }:

let
  inherit (config.roles.github-actions-runner) name count;
  runners = builtins.genList (x: "${name}-${toString (x + 1)}") count;
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
      id = "4080784";
      login = "OSSystems";
      privateKeyFile = config.sops.secrets.github-app-runner-private-key.path;
    };
    extraPackages = with pkgs; [
      gh
      openssl
      nodejs_24
      file
      coreutils
      which
      python3
    ];
    nodeRuntimes = [ "node24" ];
  };

  nix.settings = {
    allowed-users = runners;
    trusted-users = runners;
  };

  systemd.tmpfiles.rules = [ "d /var/lib/github-runner-work 0750 root root -" ];

  systemd.mounts = [
    {
      what = "/var/lib/github-runner-work";
      where = "/run/github-runner";
      type = "none";
      options = "bind";
      requires = [ "systemd-tmpfiles-setup.service" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      before = map (r: "github-runner-${r}.service") runners;
      wantedBy = map (r: "github-runner-${r}.service") runners;
    }
  ];

  systemd.services = builtins.listToAttrs (
    builtins.map
      (n: {
        name = "github-runner-${name}-${toString n}";
        value.environment.GIT_SSH_COMMAND = "ssh -i $HOME/.ssh/id_rsa";
      })
      (builtins.genList (x: x + 1) count)
  );

  sops = {
    defaultSopsFile = ../../../secrets/monster.yaml;
    secrets.github-app-runner-private-key = { };
    secrets.ossystems-tools-deploy-key.mode = "0400";
  };

  programs.ssh.extraConfig = ''
    Match host github.com user root
      IdentityFile ${config.sops.secrets.ossystems-tools-deploy-key.path}
      IdentitiesOnly yes
  '';
}
