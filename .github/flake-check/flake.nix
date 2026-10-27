{
  description = "Validate one lab-builder output in a fresh evaluator";
  inputs.source.url = "path:../..";

  outputs =
    { source, ... }:
    let
      inherit (builtins.fromJSON (builtins.readFile ./selection.json)) name output system;
    in
    if output == "" then
      builtins.removeAttrs source.outputs [ "nixosConfigurations" ]
      // builtins.mapAttrs (_: systems: builtins.removeAttrs systems [ system ]) (
        builtins.intersectAttrs {
          packages = null;
          checks = null;
          devShells = null;
          apps = null;
          formatter = null;
        } source.outputs
      )
    else if output == "nixosConfigurations" then
      { nixosConfigurations.${name} = source.nixosConfigurations.${name}; }
    else if output == "formatter" then
      { formatter.${system} = source.formatter.${system}; }
    else
      { ${output}.${system}.${name} = source.${output}.${system}.${name}; };
}
