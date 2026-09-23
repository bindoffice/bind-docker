# Bind normal worker (11333) to loopback only — do not expose on the public interface.
bind_socket = "127.0.0.1:11333";
# One scanner is enough for self-hosted / low-volume mail; default is ~nCPU and multiplies RAM.
count = 1;
# Cap concurrent scans per worker to avoid memory spikes under bursts.
max_tasks = 20;
