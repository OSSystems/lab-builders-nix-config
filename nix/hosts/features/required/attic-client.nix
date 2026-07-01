{
  config,
  inputs,
  pkgs,
  ...
}:

let
  atticClient = inputs.attic.packages.${pkgs.stdenv.hostPlatform.system}.attic-client;

  endpoint = "https://cache.freedom.ind.br";
  cache = "ossystems";
  pushHome = "/var/lib/attic-push";
in
{
  imports = [ inputs.sops-nix.nixosModules.default ];

  nix.settings.post-build-hook = pkgs.writeShellScript "attic-push" ''
    set -eu -f
    export IFS=' '
    export HOME=${pushHome}
    ${atticClient}/bin/attic push ${cache} $OUT_PATHS || true
  '';

  nix.settings.extra-substituters = [ "${endpoint}/${cache}" ];
  nix.settings.extra-trusted-public-keys = [
    "ossystems:RHt7+L/R1IMrs4NvgUISD49ieL0OvyXZHYdDzRUSHps="
  ];

  systemd.services.attic-push-login = {
    wantedBy = [ "multi-user.target" ];
    path = [ atticClient ];
    environment.HOME = pushHome;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -m700 ${pushHome}
      attic login local ${endpoint} "$(cat ${config.sops.secrets.attic-push-token.path})"
    '';
  };

  sops.secrets.attic-push-token.sopsFile = ../../../../secrets/common.yaml;
}
