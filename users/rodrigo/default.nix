{ pkgs, ... }:

{
  users.users.rodrigo = {
    description = "Rodrigo Medeiros";

    isNormalUser = true;
    extraGroups = [ "docker" "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCeyGNL/IH6IZ8Qrtm7JpC/+1zyURSSFYeqfqK9ANsEtqOsUWkR9Ir7P+S89nmBIYCj2RHjdMj5VWKvJJJpzR3eXAFPk1eFNWUbS91XO4DPjCGGHZkfAAyU6MzaO6CUVHSjratTmzYl37I8HVKxnqVp+QfY9Z3xWkjmhFXT0ZZNbVMksMYgNxGesyjxs3R75tvibU2F0TAF2IkHKWFWR3+Ioqy7bz7p53oWTk/cVDQssjsH7riVHlKgvg6xVVUAZMQbGtP4moLiG6+Q++m3PoeVbM3fjPWVC1b/nP02+YrHnzZD45ClpdiQJOUmEg2ZEOR0ivdcMYRNu+baUR4gosr7RnlCG5A/iwWgDzU0F39QjhDEKcZY7/IVJsgC4o4BxnVuRSPo/vOZAxXdjVhP2NLNkN0BrfbeLQeAaVcNE2Ca4LRqzJyTvm3JjpC5Ut0sZA6oQbWpfBzprL8ESCIm23OW9Ay9DwakLwH3kiGZVbBJwE92vgkGGAUtRW67Q6KTWQk= rodrigo@centrium"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbJgOm2xW6++Vsbef6SH5YI7XV7RUCSTB/otasHwbXs3dvyJo43tyaXEP8ZPEilzCCFa553ds3dWXyng11VNoKxe2r3/vGYrkTAsowTZTeHm4Kazh7nK+yal3BWae2ZBNjaotCj8Z7TkYnJDiVEFzmJCIZUbS/SCIQhcZe5c3QuHnH7tx3l7Iau6l0zcqyKV4h1Ht1gyAUVkEkX+vfHvQtOHdbgSRfe8ADlmw8nd+1P1CNJVndWp1n4VJejDx8PCAAbAMlAgBzJmjKzKCz/6gp0M6pmknlRs1rpPwubq7vPXkWVBIfdOSvimGG2vfR0gY/KDxX4zTAAlLkuY58VrBtFd/AeAZ4o3h+By6afJfDIx2GC8b3mevnzm+e9hXEsF/CAFS2Z9POQWhy5mNCBWt8wEKiUCCZTnPjehyY/t0ZhweJWzJF4BbJayWfkxsXHsImrPPF6DnN8ZsJnCeIUVREcBLfGBrZU5XnByxa7GhaxgoecKOQJWGijnaV0JcR2+U= rodrigo@lenovo1"
    ];

    # Default - used for bootstrapping.
    password = "pw";
  };

  home-manager.users.rodrigo = {
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

      delta = {
        enable = true;
        options.syntax-theme = "base16-256";
      };

      extraConfig = {
        core.sshCommand = "${pkgs.openssh}/bin/ssh -F ~/.ssh/config";
      };
    };

    programs.ssh = {
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
