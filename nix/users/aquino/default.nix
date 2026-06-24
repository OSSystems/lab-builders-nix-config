{ pkgs, ... }:

{
  users.users.aquino = {
    description = "Vinicius Aquino";

    isNormalUser = true;
    extraGroups = [
      "docker"
      "wheel"
    ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQChHMlcI8Z4YeHuvjgyCquuYHDUFjACcg+FLLJlPOEw9eigH0c770ReVzusGIICFfHv7uuGtqybJlpY3PmIKR0ne+kwcr/tye4Atbnf9ZqjzkvYkt/YN7l7pyGEGgS9U6uCE3+8uS4wfwcIsIh+bfscRrHtybOPDu18ItbcbLWokdHEOhii31Wy4ylLFQbG/7vpa4WJeg5I+56xECYtXfzzHUM6L9zwsSFHObktJCipqANlBiFXZMhBgWzAbiH+iHBxFH+MqCpayoH8vJ9ami8LO3WybEsGEd0wzZqbeQiIzpaIKhNLluYNWlRZqxaG75QPlTPQ7FPOJCeWqP5Tq9hsNZNRWgsvh1Xb3WV5nDsqEdDn7ON6KpKfEimLPsD8JxXdGwhCST7LEufhgPuM2MoINeivpSHDfxBeSPL29YG2XxPj5+tJjsOfmJwS3ZEOJak2ekxC3/6vqY9aOtso2xDXdOC/fsOAefy15K3xSrNyFOOyUVj8zb9DElfS8yV1Bzc= aquino@work"
    ];

    # Default - used for bootstrapping.
    password = "pw";
  };

  home-manager.users.aquino = {
    home = {
      packages = with pkgs; [
        tmux
        tmuxp
        tree
        htop
        wget
        unzip
        nmap
        gitRepo
      ];

      stateVersion = "26.05";
    };

    programs.bash.enable = true;

    programs.fzf = {
      enable = true;
      enableBashIntegration = true;

      tmux.enableShellIntegration = true;
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options.syntax-theme = "base16-256";
    };

    programs.git = {
      enable = true;

      settings = {
        core.sshCommand = "${pkgs.openssh}/bin/ssh -F ~/.ssh/config";
      };
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = {
        "*" = { };
        "code.ossystems.com.br" = {
          Hostname = "code.ossystems.io";
        };
        "*.lab.ossystems" = {
          ForwardAgent = true;
          ForwardX11 = true;
          ForwardX11Trusted = true;
        };
      };
    };
  };
}
