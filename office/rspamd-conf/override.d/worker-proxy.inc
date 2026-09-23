# Bind proxy/milter (11332) to loopback only — do not expose on the public interface.
bind_socket = "127.0.0.1:11332";
# bindinbox uses HTTP on 11333; milter proxy is unused — save a full process.
enabled = false;
count = 1;
