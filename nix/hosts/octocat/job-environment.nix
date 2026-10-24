# What CI jobs find on octocat, shared by the host runners and the microVM
# runners.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.octocat = {
    jobPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      readOnly = true;
    };
    runnerPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
    };
  };

  config = {
    octocat = {
      jobPackages = with pkgs; [
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
      # hashFiles() always runs the runner's node20 external, so that slot is
      # filled with node24 instead of the end-of-life Node 20.
      runnerPackage = pkgs.github-runner.override {
        nodejs_20 = pkgs.nodejs_24;
        nodeRuntimes = [
          "node20"
          "node24"
        ];
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

    virtualisation.docker.enable = true;

    systemd = {
      # Compose driven as a Go library (testcontainers) only finds the CLI
      # plugins in the standard directories, not through the docker wrapper.
      tmpfiles.rules = [
        "L+ /usr/libexec/docker/cli-plugins/docker-buildx - - - - ${pkgs.docker-buildx}/libexec/docker/cli-plugins/docker-buildx"
        "L+ /usr/libexec/docker/cli-plugins/docker-compose - - - - ${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose"
      ];
      # tonistiigi/binfmt registers QEMU from a privileged container, which only
      # outlives the container when binfmt_misc is mounted.
      mounts = [
        {
          what = "binfmt_misc";
          where = "/proc/sys/fs/binfmt_misc";
          type = "binfmt_misc";
          wantedBy = [ "sysinit.target" ];
        }
      ];
    };
  };
}
