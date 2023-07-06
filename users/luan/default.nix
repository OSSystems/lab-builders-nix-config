{ pkgs, ... }:

{
  users.users.luan = {
    description = "Luan Rafael Carneiro";

    isNormalUser = true;
    extraGroups = [ "docker" "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmnGmiCI8Izo/oIV1AXNcI/9sytYJEPcuc1u4dXNmLqKTvN76UTstp7HlNHu5wWEZaOrKKiB14U8aY+z1hPlW9VwMZWPyrJKpvBe433Tc1RWPg60iT1Hyoor6y9ja/YmeUDzc5GN+4LylOboE3YkI/AI+uhwIha0Hw7KAxQBsg6syiFPAraCgtO3VCosBzpNVxHDD9Ls6+Tk8E2ZRtdE6Wvx/0yc5+LkKdvTbTnBOpFr7dc1IVTtCtu/n3yHnpmoMMUe4qpI2nAYypX2u8KvywtTsvGXBK96HPfDgCqaqFAXtesZBhPBlY4l+qLiqFHjiQB0YVPgaPD0PIrq9XvUgN6gYBEQR+1GtDBiqzVxlrPvgSmIP0uxCiWVCr26KgETG4V3FICjOWPdKPt0Byc2JOo9fYvVOae8qM2Auc91YNFyHOXbd5tQF0tF3HCn/sY7VZBJTrYp6lQl0BEKvgxZVL5Pq+dE9jyR74Lwh3ETxEiy4nYmdvFsGcYzo/82LkmhE= luan@arch"
    ];

    # Default - used for bootstrapping.
    password = "pw";
  };

  home-manager.users.luan = {
    home = {
      packages = with pkgs; [
        gitRepo
        htop
        nmap
        tmux
        tmuxp
        tree
        unzip
        wget
      ];

      stateVersion = "23.05";
    };

    programs.bash.enable = true;

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

      delta = {
        enable = true;
        options.syntax-theme = "base16-256";
      };

      extraConfig = {
        core.sshCommand = "${pkgs.openssh}/bin/ssh -F ~/.ssh/config";
        core.editor = "nvim";
      };
    };

    programs.ssh = {
      enable = true;

      extraConfig = ''
        Host code.ossystems.com.br
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
