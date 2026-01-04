#!/bin/sh
# Wait for Redis to be ready before starting the application

REDIS_CONN_STR="${REDIS_CONN_STR:-redis://redis:6379/0}"

# Parse Redis URL to extract host and port
# Handle formats like: redis://user:pass@host:port/db or redis://host:port/db
HOST=$(echo "$REDIS_CONN_STR" | sed -n 's|.*@\([^:]*\):.*|\1|p')
if [ -z "$HOST" ]; then
    HOST=$(echo "$REDIS_CONN_STR" | sed -n 's|.*://\([^:]*\):.*|\1|p' || echo "redis.railway.internal")
fi

PORT=$(echo "$REDIS_CONN_STR" | sed -n 's|.*:\([0-9]*\)/.*|\1|p' || echo "6379")

echo "Waiting for Redis at $HOST:$PORT to be ready..."
timeout=60
elapsed=0

# Use Python to check Redis connection (Python is already in the image)
while [ $elapsed -lt $timeout ]; do
    if python3 -c "
import socket
import sys
try:
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(2)
    result = sock.connect_ex(('$HOST', $PORT))
    sock.close()
    sys.exit(0 if result == 0 else 1)
except:
    sys.exit(1)
" 2>/dev/null; then
        echo "Redis is ready!"
        exec "$@"
        exit 0
    fi
    echo "Redis not ready yet, waiting... ($elapsed/$timeout seconds)"
    sleep 2
    elapsed=$((elapsed + 2))
done

echo "Timeout waiting for Redis. Starting anyway..."
exec "$@"
