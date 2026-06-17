{ pkgs, ... }:

{
  host-scripts = pkgs.callPackage ./host-scripts { };

  ossystems-tools = pkgs.callPackage ./ossystems-tools { };
  bitbakePackages = pkgs.callPackages ./bitbake { };
}
