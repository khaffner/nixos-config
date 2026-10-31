# Built-in osquery queries.

{ config, lib, ... }:

{
  config = lib.mkIf config.services.prost.enable {
    # Built-in queries. Each is mkDefault so a host can override or null them
    # per name through services.prost.queries.
    services.prost.queries = lib.mapAttrs (_: lib.mkDefault) {
      osquery = "SELECT version FROM osquery_info;";
      system_info = "SELECT hostname, uuid, hardware_vendor, hardware_model, cpu_brand, cpu_physical_cores, cpu_logical_cores, physical_memory FROM system_info;";
      os_version = "SELECT name, version, platform, arch FROM os_version;";
      kernel = "SELECT version FROM kernel_info;";
      uptime = "SELECT days, hours, minutes, total_seconds FROM uptime;";
      load_average = "SELECT period, average FROM load_average;";
      memory = "SELECT memory_total, memory_free, memory_available, swap_total, swap_free FROM memory_info;";
      disks = "SELECT path, device, type, blocks * blocks_size AS size_bytes, blocks_available * blocks_size AS available_bytes FROM mounts WHERE blocks > 0 AND (device LIKE '/dev/%' OR type IN ('zfs', 'btrfs')) ORDER BY path;";
      interfaces = "SELECT interface, address, mask FROM interface_addresses WHERE interface != 'lo' ORDER BY interface;";
      listening_ports = "SELECT p.port, CASE p.protocol WHEN 6 THEN 'tcp' WHEN 17 THEN 'udp' ELSE p.protocol END AS protocol, p.address, pr.name AS process FROM listening_ports p LEFT JOIN processes pr ON p.pid = pr.pid WHERE p.port > 0 AND p.address NOT IN ('127.0.0.1', '::1') ORDER BY p.port;";
      battery = "SELECT percent_remaining, state, cycle_count, health FROM battery;";
    };
  };
}
