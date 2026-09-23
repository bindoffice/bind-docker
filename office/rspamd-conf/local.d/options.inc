# Keep history small — each row is retained in memory / redis-backed storage.
history_rows = 100;
# Limit parallel DNS lookups (RBL/URIBL) to reduce CPU and resolver load.
dns_max_requests = 16;
# Periodically reclaim Lua heap after scanning (0 = disabled by default).
full_gc_iters = 10;
