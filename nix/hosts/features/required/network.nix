_:

{
  # use TCP BBR has significantly increased throughput and reduced latency for connections
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # Make sure firewall is enabled
  networking.firewall.enable = true;

  networking.domain = "lab.ossystems";

  networking.networkmanager.enable = true;
}
