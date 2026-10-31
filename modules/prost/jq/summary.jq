def row0(q): (q // [])[0] // {};
def num: tonumber? // 0;
def pct(used; total): if total > 0 then ((used / total * 100) | round) else "-" end;
{
  name: .name,
  host: .hostname,
  generatedAt: .generatedAt,
  age: (((now - (.generatedAt | fromdateiso8601)) / 60) | floor),
  os: ((row0(.queries.os_version) | "\(.name // "?") \(.version // "")") | gsub("\\s+$"; "")),
  kernel: (row0(.queries.kernel).version // "-"),
  up: (row0(.queries.uptime).days // "-"),
  load: (([.queries.load_average // [] | .[] | select(.period == "1m") | .average][0]) // "-"),
  mem: (row0(.queries.memory) | pct((.memory_total | num) - (.memory_available | num); (.memory_total | num))),
  disk: (([.queries.disks // [] | .[] | select(.path == "/")][0] // {}) | pct((.size_bytes | num) - (.available_bytes | num); (.size_bytes | num))),
  ipv4: [.queries.interfaces // [] | .[] | select(.address | test("^[0-9.]+$")) | .address],
  ports: [.queries.listening_ports // [] | .[] | "\(.port)/\(.protocol) \(.process // "?")"] | unique,
  battery: (row0(.queries.battery).percent_remaining // "-")
}
