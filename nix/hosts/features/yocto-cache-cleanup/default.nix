{ pkgs, ... }:

let
  cleanup = pkgs.writeShellScript "yocto-cache-cleanup" ''
    set -euo pipefail

    find=${pkgs.findutils}/bin/find
    sstate=/srv/nfs/yocto/sstate-cache
    downloads=/srv/nfs/yocto/download-cache

    # Shared-state objects not read in over 30 days. The share is mounted
    # relatime, so a file's atime is a reliable "last used by a build" marker:
    # anything a running build reads gets its atime refreshed and is therefore
    # never pruned here, even if this job fires mid-build.
    if [ -d "$sstate" ]; then
      echo "Pruning sstate objects unused >30 days under $sstate"
      "$find" "$sstate" -type f -atime +30 -delete
      "$find" "$sstate" -mindepth 1 -type d -empty -mtime +1 -delete
    fi

    # BitBake's interrupted-download leftovers and stale fetch locks. The +1 day
    # guard leaves any download currently in flight untouched.
    if [ -d "$downloads" ]; then
      echo "Removing stale .tmp/.lock leftovers under $downloads"
      "$find" "$downloads" -maxdepth 1 \( -name '*.tmp' -o -name '*.lock' \) -mtime +1 -delete
    fi
  '';
in
{
  systemd.services.yocto-cache-cleanup = {
    description = "Prune unused Yocto sstate objects and stale download leftovers";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = cleanup;
    };
  };

  systemd.timers.yocto-cache-cleanup = {
    description = "Weekly Yocto shared-cache cleanup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
