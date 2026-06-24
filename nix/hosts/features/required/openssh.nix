{ config, inputs, lib, hostName, ... }:

let
  sopsFile = ../../../secrets/${hostName}.yaml;
  hasSecrets = builtins.pathExists sopsFile;
in
{
  imports = [ inputs.sops-nix.nixosModules.default ];

  services.openssh = {
    enable = true;
    settings = {
      # Harden
      PasswordAuthentication = lib.mkDefault false;
      PermitRootLogin = lib.mkDefault "no";
      # Automatically remove stale sockets
      StreamLocalBindUnlink = "yes";
      # Allow forwarding ports to everywhere
      GatewayPorts = "clientspecified";
    };

    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  sops.secrets.ossystems-tools-deploy-key = lib.mkIf hasSecrets {
    inherit sopsFile;
    mode = "0400";
  };

  programs.ssh.extraConfig = lib.mkIf hasSecrets ''
    Match host github.com user root
      IdentityFile ${config.sops.secrets.ossystems-tools-deploy-key.path}
      IdentitiesOnly yes
  '';

  # Passwordless sudo when SSH'ing with keys
  security.pam.sshAgentAuth.enable = true;
}
