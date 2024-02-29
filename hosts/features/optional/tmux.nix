{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shortcut = "a";
    escapeTime = 0;
    historyLimit = 10000;
    terminal = "screen-256color";
    aggressiveResize = true;
    baseIndex = 1;
    clock24 = true;

    plugins = with pkgs; [
      tmuxPlugins.tmux-fzf
      tmuxPlugins.prefix-highlight
      tmuxPlugins.copycat
      tmuxPlugins.fzf-tmux-url
    ];

    extraConfig = ''
      set -sg terminal-overrides ",*:RGB"

      # Repeat key press automatically
      set-option -g repeat-time 1000

      # Keep environment variables synced
      set -g update-environment -r

      # Easier and faster switching between next/prev window
      bind C-p previous-window
      bind C-n next-window

      # Key bindings for horizontal and vertical panes
      unbind %
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Open new window and new panel at current directory
      bind C new-window -c "#{pane_current_path}"

      # Swap Window
      bind-key -r "<" swap-window -t -1
      bind-key -r ">" swap-window -t +1
    '';
  };
}
