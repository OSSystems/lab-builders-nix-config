{ lib, ... }:

{
  # Notice this also disables --help for some commands such es nixos-rebuild
  documentation.enable = lib.mkDefault false;
  documentation.info.enable = lib.mkDefault false;
  documentation.man.enable = lib.mkDefault false;
  documentation.nixos.enable = lib.mkDefault false;

  # No need for fonts on a server
  fonts.fontconfig.enable = lib.mkDefault false;
}
