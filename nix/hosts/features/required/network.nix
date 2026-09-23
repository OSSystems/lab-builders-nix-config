_:

{
  # use TCP BBR has significantly increased throughput and reduced latency for connections
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
  networking = {
    # Make sure firewall is enabled
    firewall.enable = true;
    domain = "lab.ossystems";
    networkmanager.enable = true;
  };
}
