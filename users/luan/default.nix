{ pkgs, ... }:

{
  users.users.luan = {
    description = "Luan Rafael Carneiro";

    isNormalUser = true;
    extraGroups = [ "docker" "wheel" "audio" "sound" "vboxusers" ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmnGmiCI8Izo/oIV1AXNcI/9sytYJEPcuc1u4dXNmLqKTvN76UTstp7HlNHu5wWEZaOrKKiB14U8aY+z1hPlW9VwMZWPyrJKpvBe433Tc1RWPg60iT1Hyoor6y9ja/YmeUDzc5GN+4LylOboE3YkI/AI+uhwIha0Hw7KAxQBsg6syiFPAraCgtO3VCosBzpNVxHDD9Ls6+Tk8E2ZRtdE6Wvx/0yc5+LkKdvTbTnBOpFr7dc1IVTtCtu/n3yHnpmoMMUe4qpI2nAYypX2u8KvywtTsvGXBK96HPfDgCqaqFAXtesZBhPBlY4l+qLiqFHjiQB0YVPgaPD0PIrq9XvUgN6gYBEQR+1GtDBiqzVxlrPvgSmIP0uxCiWVCr26KgETG4V3FICjOWPdKPt0Byc2JOo9fYvVOae8qM2Auc91YNFyHOXbd5tQF0tF3HCn/sY7VZBJTrYp6lQl0BEKvgxZVL5Pq+dE9jyR74Lwh3ETxEiy4nYmdvFsGcYzo/82LkmhE= luan@arch"
    ];

    # Default - used for bootstrapping.
    password = "pw";
  };

  home-manager.users.luan = {
    home = {
      packages = with pkgs; [
        alacritty
        bmap-tools
        bitbake-language-server
        brave
        delta
        discord
        gitlab-runner
        flameshot
        gcc-arm-embedded
        gcc
        ripgrep
        gitRepo
        google-chrome
        gnumake
        helix
        htop
        minicom
        nerdfonts
        nmap
        nodePackages.bash-language-server
        nxpmicro-mfgtools
        ossystems-tools
        obsidian
        parcellite
        python3
        slack
        spotify
        tmux
        tmuxp
        tree
        usbutils
        unzip
        wget
      ];

      stateVersion = "23.05";
    };

    programs.bash = {
      enable = true;
      bashrcExtra = ''
        parse_git_branch() {
            git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
        }
        export PS1="\[\033[01;32m\]\u@\[\033[00m\]\[\033[01;35m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\e[91m\]\$(parse_git_branch)\[\e[00m\]$ "
      '';
      shellAliases = {
        # Insecure SSH and SCP aliases. I use this to connect to temporary devices
        # such as embedded devices under test or development so we don't need to
        # delete the fingerprint every time we reinstall them.
        issh = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
        iscp = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
      };
    };

    programs.fzf = {
      enable = true;
      enableBashIntegration = true;

      tmux.enableShellIntegration = true;
    };

    programs.neovim = {
      enable = true;
    };

    programs.git = {
      enable = true;

      userName = "Luan Rafael Carneiro";
      userEmail = "luan.rafael@ossystems.com.br";

      extraConfig = {
        core.sshCommand = "${pkgs.openssh}/bin/ssh -F ~/.ssh/config";
        core.editor = "nvim";
      };
    };

    programs.ssh = {
      enable = true;

      extraConfig = ''
        Host code.ossystems.com.br
            HostName code.ossystems.io
            User raflian

        Host code.ossystems.io
            User raflian

        Host *.ossystems.com.br
            HostkeyAlgorithms +ssh-rsa
            PubkeyAcceptedAlgorithms +ssh-rsa

        Host *.lab.ossystems
            ForwardAgent yes
            ForwardX11 yes
            ForwardX11Trusted yes
      '';
    };
  };
}
