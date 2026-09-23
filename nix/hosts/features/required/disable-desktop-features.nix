{ lib, ... }:

{
  documentation = {
    # Notice this also disables --help for some commands such es nixos-rebuild
    enable = lib.mkDefault false;
    info.enable = lib.mkDefault false;
    man.enable = lib.mkDefault false;
    nixos.enable = lib.mkDefault false;
  };
  # No need for fonts on a server
  fonts.fontconfig.enable = lib.mkDefault false;
}
