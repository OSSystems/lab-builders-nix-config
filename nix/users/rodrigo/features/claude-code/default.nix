{ inputs, pkgs, ... }:
let
  claudeWrapped = pkgs.writeShellScriptBin "claude" ''
    # Workaround for https://github.com/anthropics/claude-code/issues/25418
    # Agent teams install an unpatched Linux binary to ~/.local/share/claude
    # that is incompatible with NixOS. Clean up the installation directory
    # so it doesn't get used as an update source.
    rm -rf "$HOME/.local/share/claude"

    exec ${pkgs.claude-code}/bin/claude --dangerously-skip-permissions "$@"
  '';
in
{
  home.packages = with pkgs; [ jq ];

  # Place the wrapper at ~/.local/bin/claude so it takes precedence over
  # the Nix profile entry, preventing agent-teams-installed binaries from
  # shadowing the Nix-managed wrapper.
  home.file.".local/bin/claude".source = "${claudeWrapped}/bin/claude";

  nixpkgs = {
    overlays = [ inputs.claude-code-overlay.overlays.default ];
    config.allowUnfreePredicate = pkg: builtins.elem (inputs.nixpkgs.lib.getName pkg) [ "claude" ];
  };

  programs.claude-code = {
    enable = true;
    package = claudeWrapped;
  };
}

