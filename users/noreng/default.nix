{ pkgs, ... }:

{
  users.users.noreng = {
    description = "Vagner Nornberg";

    isNormalUser = true;
    extraGroups = [ "docker" "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCq6NT2ArJLFKL6rTI1yXP45PDaHLCPTpPw8jcAH1/AKJoOzYOj7KN6Z0gk6R2yuX9FMXsQ89i00QB7w0fKCBajblXejTvwW9XLPY1SrhEQXoCQrEN/271v/QxoW8cAL6jUPUr+tX4LWF77G71663DN+MxjrmbRrU3AdzDEJjwg/ntig6fSnvmA4AmGupcl+KuACmgFHFItsNMuGxJyFNStOv9GZbaWbmVkGPsjv/mRBsa8QRtIRXqUB1/KBxT9t9/34dqY/mCcfVo4zApAAkN0DKNvDKyDD0FyZ9EZm3/cW6iDwz8on+TNcf0squcr/C2GVVSBspp5ItOJQmXvbwcT0SQmX9D0+46oSy5o+YwckT74p3yI8rsa0adkDzukcLVXQbRYcZqvssfYETUo/cgjhg1z4a+RnZwik/2zLZrRCoV+eBIiXL4OZfFKZt1ZzpjDcPhNMPv6thshsgCpoYgWt///cC7iPH9JyhtNfZGlnq2weIBjnMhqfQkMJXp8ams= noreng@noreng"
    ];

    # Default - used for bootstrapping.
    password = "pw";
  };

  home-manager.users.noreng = {
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

      userName = "noreng-br";
      userEmail = "contato@nor.eng.br";

      delta = {
        enable = true;
        options.syntax-theme = "base16-256";
      };

      extraConfig = {
        core.sshCommand = "${pkgs.openssh}/bin/ssh -F ~/.ssh/config";
        core.editor = "nvim";
      };
    };

  };
}
