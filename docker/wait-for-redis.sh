#!/bin/sh
# Wait for Redis to be ready before starting the application

REDIS_CONN_STR="${REDIS_CONN_STR:-redis://redis:6379/0}"

# Use Python to parse Redis URL and check connection (more reliable than sed)
python3 << 'PYTHON_SCRIPT'
import os
import socket
import sys
import time
import urllib.parse

redis_conn_str = os.environ.get("REDIS_CONN_STR", "redis://redis:6379/0")

# Parse Redis URL
url = urllib.parse.urlparse(redis_conn_str)
host = url.hostname or "redis.railway.internal"
port = url.port or 6379

print(f"Waiting for Redis at {host}:{port} to be ready...")
timeout = 60
elapsed = 0

while elapsed < timeout:
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        result = sock.connect_ex((host, port))
        sock.close()
        if result == 0:
            print(f"Redis is ready!")
            sys.exit(0)
    except Exception:
        pass
    
    print(f"Redis not ready yet, waiting... ({elapsed}/{timeout} seconds)")
    time.sleep(2)
    elapsed += 2

print("Timeout waiting for Redis. Starting anyway...")
sys.exit(0)
PYTHON_SCRIPT

# Execute the command passed as arguments
exec "$@"
