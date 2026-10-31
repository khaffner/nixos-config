def cell: "<td>\(tostring | @html)</td>";
def pct_cell:
  if . == "-" then "<td>-</td>"
  else "<td class=\"\(if . >= 90 then "bad" elif . >= 75 then "warn" else "" end)\">\(.)%</td>" end;
def list_cell: "<td class=\"list\">\(map(@html) | join("<br>"))</td>";
def row:
  "<tr class=\"\(if .age > 120 then "stale" else "" end)\">"
  + (.name | cell) + (.host | cell) + (.age | cell) + (.os | cell) + (.kernel | cell)
  + (.up | cell) + (.load | cell) + (.mem | pct_cell) + (.disk | pct_cell) + (.battery | cell)
  + (.ipv4 | list_cell) + (.ports | list_cell)
  + "</tr>";
"<!doctype html>
<html lang=\"en\"><head><meta charset=\"utf-8\"><title>Prost</title>
<style>
  body { background: #1e1e1e; color: #d4d4d4; font-family: system-ui, sans-serif; margin: 2em; }
  h1 { font-weight: 600; } p { color: #9a9a9a; }
  table { border-collapse: collapse; background: #252526; }
  th, td { border: 1px solid #3e3e42; padding: 6px 10px; text-align: left; vertical-align: top; white-space: nowrap; }
  th { background: #2d2d30; color: #cccccc; font-weight: 600; }
  tr:hover { background: #2a2d2e; }
  tr.stale td:first-child { color: #f48771; }
  td.warn { color: #e5c07b; } td.bad { color: #f48771; font-weight: 600; }
  td.list { font-family: monospace; font-size: 0.9em; }
  details { margin-top: 1em; } summary { cursor: pointer; }
  pre { background: #252526; padding: 1em; overflow-x: auto; }
</style></head><body>
<h1>&#127867; Prost</h1>
<p>Generated \($generated) on \($host | @html). \(length) device(s). Name shown in red: report older than two hours.</p>
<table><thead><tr>
<th>Name</th><th>Host</th><th>Age (min)</th><th>OS</th><th>Kernel</th><th>Up (days)</th><th>Load</th><th>Mem</th><th>Root</th><th>Battery</th><th>IPv4</th><th>Listening ports</th>
</tr></thead><tbody>
\(sort_by(.name) | map(row) | join("\n"))
</tbody></table>
<h2>Raw reports</h2>"
