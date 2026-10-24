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

  runnersOf = org: builtins.genList (x: "${prefix}-${org}-${toString (x + 1)}") organizations.${org};
  runners = lib.concatMap runnersOf (builtins.attrNames organizations);
  shellhubRunners = runnersOf "shellhub-io";
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
    # hashFiles() always runs the runner's node20 external, so that slot is
    # filled with node24 instead of the end-of-life Node 20.
    package = pkgs.github-runner.override { nodejs_20 = pkgs.nodejs_24; };
    nodeRuntimes = [
      "node20"
      "node24"
    ];
    extraLabels = [ "nix" ];
    extraPackages = with pkgs; [
      bats
      cachix
      config.nix.package
      config.virtualisation.docker.package
      coreutils
      curl
      diffutils
      file
      gawk
      gcc
      gh
      glibc.bin
      gnumake
      gnupatch
      gnupg
      inetutils
      jq
      nix-eval-jobs
      nodejs_24
      openssh
      openssl
      procps
      python3
      rsync
      shellcheck
      unzip
      util-linux
      which
      xz
      zip
    ];
    serviceOverrides = {
      DeviceAllow = [ "/dev/kvm" ];
      PrivateDevices = false;
    };
  };
  programs.nix-ld = {
    enable = true;
    # Playwright's downloaded Chromium.
    libraries = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libdrm
      libgbm
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      mesa
      nspr
      nss
      pango
    ];
  };
  virtualisation.docker.autoPrune.enable = true;
  systemd = {
    # tonistiigi/binfmt registers QEMU from a privileged container, which only
    # outlives the container when the host has binfmt_misc mounted.
    mounts = [
      {
        what = "binfmt_misc";
        where = "/proc/sys/fs/binfmt_misc";
        type = "binfmt_misc";
        wantedBy = [ "sysinit.target" ];
      }
    ];
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
          (lib.mkIf (lib.elem runner shellhubRunners) {
            # The docker group must stay mapped for the socket to be reachable.
            serviceConfig = {
              SupplementaryGroups = [ "docker" ];
              PrivateUsers = false;
            };
            path = with pkgs; [
              wineWowPackages.stable
              yarn
            ];
          })
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
