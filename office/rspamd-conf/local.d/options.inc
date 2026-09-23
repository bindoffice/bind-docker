# Low-resource profile for self-hosted / low-volume mail.

# Hyperscan keeps a large compiled DB in RSS (~100MB+); turn off on small hosts.
disable_hyperscan = true;
# Skip periodic RBL probe traffic (still checks mail against RBLs when scanning).
disable_monitoring = true;

# Drop fuzzy_check (external fuzzy + extra I/O). Keep chartable/dkim/regexp.
filters = "chartable,dkim,regexp";

history_rows = 50;
dns_max_requests = 8;
full_gc_iters = 5;
# Scan fewer maps / reload less often → less disk and network wakeups.
map_watch_interval = 1h;
max_message = 10M;
max_lua_urls = 256;
max_urls = 1024;
task_timeout = 4s;
