#!/bin/sh
# Wait for Redis to be ready before starting the application

REDIS_CONN_STR="${REDIS_CONN_STR:-redis://redis:6379/0}"

# Parse Redis URL to extract host and port
HOST=$(echo "$REDIS_CONN_STR" | sed -n 's|.*@\([^:]*\):.*|\1|p')
PORT=$(echo "$REDIS_CONN_STR" | sed -n 's|.*:\([0-9]*\)/.*|\1|p' || echo "6379")

if [ -z "$HOST" ]; then
    # Fallback: try to extract from URL format
    HOST=$(echo "$REDIS_CONN_STR" | sed -n 's|.*://\([^:]*\):.*|\1|p' || echo "redis.railway.internal")
fi

echo "Waiting for Redis at $HOST:$PORT to be ready..."
timeout=60
elapsed=0

while [ $elapsed -lt $timeout ]; do
    if nc -z "$HOST" "$PORT" 2>/dev/null || (command -v redis-cli >/dev/null 2>&1 && redis-cli -h "$HOST" -p "$PORT" ping >/dev/null 2>&1); then
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
