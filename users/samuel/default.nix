{ pkgs, ... }:

{
  users.users.samuel = {
    description = "Samuel Silva";

    isNormalUser = true;
    extraGroups = [ "docker" "wheel" ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbJhk5H0h7Oi79LSHLWfuffv6uFcuXtm77kewxrwQsD znaniye@golf"
    ];

    # Default - used for bootstrapping.
    password = "pw";
  };

  home-manager.users.samuel = {
    home = {
      packages = with pkgs; [
        tree
        btop
        wget
      ];

      stateVersion = "26.05";
    };

    programs.bash.enable = true;
  };
}
