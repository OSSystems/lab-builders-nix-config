# A T3 Code server for otavio. T3 Code desktop reaches it as an SSH
# environment: over SSH, it finds the server that runs on ~/.t3 and tunnels to
# its loopback port. Thus nginx serves no one: the firewall keeps port 80 closed
# and the virtual host has no TLS.
{
  inputs,
  config,
  pkgs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  imports = [ inputs.t3code-nix.nixosModules.t3code-os ];

  services.t3code-os = {
    enable = true;
    package = inputs.t3code-nix.packages.${system}.t3code-server;
    inherit (config.networking) domain;
    publicScheme = "http";
    virtualHost = { };
    extraPackages = [
      inputs.claude-code-overlay.packages.${system}.default
      pkgs.direnv
    ];
    users.otavio.port = 40001;
  };
}
