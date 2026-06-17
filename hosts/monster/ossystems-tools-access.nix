{ config, ... }:

# The `ossystems-tools` package is fetched from a private repository over SSH
# (see pkgs/ossystems-tools/default.nix, `builtins.fetchGit`). This fetch runs
# at evaluation time as root during `nixos-rebuild`/auto-upgrade, so root needs
# a deploy key with read access to the repo. The github.com host key is trusted
# in hosts/features/required/openssh.nix.
#
# NOTE: on the very first deploy the secret is not on disk yet (it is only
# materialised during activation, which happens *after* evaluation). Bootstrap
# that first switch by providing the key to root manually (copy it to
# /root/.ssh/id_ed25519 or forward an agent). Every subsequent auto-upgrade
# then uses the path below.
{
  sops.secrets.ossystems-tools-deploy-key = {
    # Uses sops.defaultSopsFile (secrets/monster.yaml) set in github-runner.nix.
    mode = "0400";
  };

  programs.ssh.extraConfig = ''
    Match host github.com user root
      IdentityFile ${config.sops.secrets.ossystems-tools-deploy-key.path}
      IdentitiesOnly yes
  '';
}
