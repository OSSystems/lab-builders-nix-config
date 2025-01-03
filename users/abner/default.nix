{ pkgs, ... }:

{
  users.users.abner = {
    description = "Abner Cordeiro";

    isNormalUser = true;
    extraGroups = [ "docker" "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDDi3dFYewBu4sCdk2onVG7muvbF1rn3D7u0ZGsO/yYQuthvzhiQuZbktsm64VB8AC+MWmKEsFn9HYLXffQqFpcrVkQzLM5vT9kC/h+7afcpkjptu0NQ8HEIXX5ZUC+5ME1KsMUMSCibE9KpVx44AdTQHQHoh0pFySs4a6uP9uxV05xCrrpkynlneJhesL0arJe0elpwJOEKgTKJmXbrS/J9xwpWi2nIe/upyHrJZmMxbzN3rnt1RuwOMfUdKllvlfyBa7Tdl36V35ItCXqyVP87JsGDBuuLWrRtv7LVdK0WaDqSVDt2gJMKsxqXN7wvodBSzHpDmZn8oQ6K70rUaWGRPyVclFyj4PI5pq8NMe/o+DZYLLmT1BEH062phtYPRbAu1PaV/4PoSsGaGynP7SC+XhyxMYI5jMtxu8Wqh/TXpv4ZiKKKnvWXbO/mG2KBPbZ7PA+CLLvvKFn+P36Lp1DUN3ecusZncGoX/nswMALV5xm/pHV3baAn20Tl+fjak8= ab@abc"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCrBtBsUBOvPXct0OpjvrlECXhzrxt9QEHjxPNQTtbnrR+6kv6DDUwnMB+WOAppCl1cykHT8VMPk/1xfq8d7QHq4zxRAF2Hf65cB4cYzf47nKYiB4j5OvhCr6qiVc+WZ7nOBc4MNokLAdtWBiQExyYNfMj61S54hHndStCvd+CxDPFfNjTv2W7XwcK+vYivhLa9Oi/64KfJKG6v8qXFvWBFgWPTrWHEoV5O4Qwj74GdBbGSORN/wh3tWuLmiOsDrGEHtK5pJw1rcJ1qQc3fxgWJp+LMHHNEG3dAc68BD+Aumv10g/hc32z839jSirRE9qsI/FfcJHOtVMxzBKF2h+t0F4jf2+ih84DLZtvDjyRBSC+/EkEiAjbl+KMEQ2+YrWcaThppnvN+3I9DComwSfPGMrCbmf3SqTDhuizm+y5+cMoKuNWwvBg7sCcq0lNJM0ttP8UJfl6D/rv8OOuyTJgFdxJ4EEtTM5WLZXpYc+HYA88DbPI0vJmDB2CccrtYEIU= abner@centrium"
    ];

    # Default - used for bootstrapping.
    password = "pw";
  };

  home-manager.users.abner = {
    home = {
      packages = with pkgs; [
        bintools
        gitRepo
        htop
        kas
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
    programs.neovim =
      let
        bitbake-vim = pkgs.vimUtils.buildVimPlugin {
          pname = "bitbake-vim";
          version = "unstable-2022-04-08";
          src = pkgs.fetchFromGitHub {
            owner = "kergoth";
            repo = "vim-bitbake";
            rev = "0a229746e4a8e9c5b3b4666e9452dec2cbe69c9b";
            hash = "sha256-9WRRpOZ/Qs2nckAzV1UqM3O7DXVhiyuVo1kFotiWqcc=";
          };
        };
      in
      {
        enable = true;
        coc.enable = true;
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

          " Coc Key configs
          inoremap <silent><expr> <C-n> coc#pum#visible() ? coc#pum#next(1) : "\<C-n>"
          inoremap <silent><expr> <C-p> coc#pum#visible() ? coc#pum#prev(1) : "\<C-p>"
          inoremap <silent><expr> <down> coc#pum#visible() ? coc#pum#next(0) : "\<down>"
          inoremap <silent><expr> <up> coc#pum#visible() ? coc#pum#prev(0) : "\<up>"

          inoremap <silent><expr> <C-e> coc#pum#visible() ? coc#pum#cancel() : "\<C-e>"
          inoremap <silent><expr> <C-y> coc#pum#visible() ? coc#pum#confirm() : "\<C-y>"
          inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
        '';
      };

    programs.git = {
      enable = true;

      userName = "Abner C. Paula";
      userEmail = "abner.cordeiro@ossystems.com.br";

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
