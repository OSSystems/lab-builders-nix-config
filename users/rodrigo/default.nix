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

    programs.fzf = {
      enable = true;
      enableBashIntegration = true;

      tmux.enableShellIntegration = true;
    };

    # Configure the nvim plugins
    programs.neovim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        auto-pairs
        bitbake-vim
        fzf-vim
        gruvbox
        nerdtree
        toggleterm-nvim
        vim-airline
        vim-airline-themes
        vim-devicons
        vim-fugitive
      ];
      extraConfig = ''
        set number
        set background=dark

        " Airline
        let g:airline_powerline_fonts = 1

        "Gruvbox
        let g:gruvbox_italic=1
        let g:gruvbox_contrast_dark = 'hard'
        autocmd vimenter * ++nested colorscheme gruvbox

        " Always show the signcolumn, otherwise it would shift the text each time
        " diagnostics appear/become resolved.
        if has("nvim-0.5.0") || has("patch-8.1.1564")
          " Recently vim can merge signcolumn and number column into one
          set signcolumn=number
        else
          set signcolumn=yes
        endif

        " NERDTreeToggle
        nnoremap <silent><C-t> :NERDTreeToggle<CR>

        " ToggleTerm
        lua require("toggleterm").setup()
        nnoremap <silent><M-t> :ToggleTerm<CR>

        " FZF open command
        nnoremap <silent><C-f> :FZF<CR>

        " Identation configs
        set expandtab
        set tabstop=4
        set shiftwidth=4
      '';
    };

    programs.git = {
      enable = true;

      userName = "Rodrigo M. Duarte";
      userEmail = "rodrigo.duarte@ossystems.com.br";

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
            User mdrodrigo
        
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
