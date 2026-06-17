{ inputs, flake, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs = {
    overlays = builtins.attrValues flake.overlays;
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  home-manager = {
    useUserPackages = true;
  };
}
