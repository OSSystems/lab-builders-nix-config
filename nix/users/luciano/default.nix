{ pkgs, ... }:

{
  users.users.luciano = {
    description = "Luciano Gomes";

    isNormalUser = true;
    extraGroups = [ "docker" "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7/YBWZFreiTQDgb++49H6087Uy6iSJ/VFJRrXUc+O7DfsV7K35aWQE10K7lAurL0m8c//mMADxoUsGLef/cF2jO/UOcQD4lnsmU2uQXubJ0QLDKykMDwp+wgXTdfWFQwM4wpqJSvRnobMbgpep1xmaZetng62XMg4BKj8Le62oE+owtLVj7Vkn010HVnkbThBzyhTYLCtq8HNrFz5BGpDCO8LGGCzyTIXoX+ilepiMy64UhdX+kzZ0zcWl5tjOWyjV+4wP2U6xCIZys4q6IohPq9bqRnRzpPNqLdgrCaLPDAuCAO3ye9P9XONF7ZVFdaba+n39Y10FE8lu2Y4tZgGzVTkugrd6t01w76FnJx6hPHhkhW7fIe6SM2WQLQ8ViHh9sblFmRYSCTpEZYyiU8+FJqSrL6k+c/hBohg5yh8knUih932N+cpQUnVfgVW1JteC9GKwoKFFmAeAKTxzbbHtxiQ1SKw4Ya0VpAxIHP3nszvkKKO708SQsbo7sFDzwBesAntLqhIMcLtDZAQ34PbqDm6WY0SZA/EmTfQeRA8fpMUb2IS8KSzXnYfR37v4ZO7FynBKFwIYv/J/gj/HLFEED62+b4wQioU4xsJ/Ud9oc/QYrg0dMtf4wFTu6XPWjsK58lJDRYzfzPxo2ntUWHQlsPtXX06vfckgl5b3oHxIw== luciano@archlinux"
    ];

    # Default - used for bootstrapping.
    password = "pw";
  };

  home-manager.users.luciano = {
    home = {
      packages = with pkgs; [
        bintools
        gitRepo
        htop
        kas
        nmap
        oelint-adv
        openfortivpn
        tmux
        tmuxp
        tree
        unzip
        wget
      ];
      file = {
        ".yocto/site.conf".source = ./yocto/site.conf;
      };

      stateVersion = "23.05";
    };

    # set the bash configurations
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

    programs.emacs = {
      enable = true;
    };

    programs.fzf = {
      enable = true;
      enableBashIntegration = true;

      tmux.enableShellIntegration = true;
    };

    programs.git = {
      enable = true;

      userName = "Luciano Gomes";
      userEmail = "luciano@ossystems.com.br";

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
