#!/usr/bin/env python3
"""Generate karton.ini from REDIS_CONN_STR environment variable for karton-system on Railway.
This version does NOT include S3 configuration since S3 is not available on Railway."""
import os
import urllib.parse

REDIS_CONN_STR = os.environ.get("REDIS_CONN_STR")
KARTON_CONFIG_PATH = "/etc/karton/karton.ini"
KARTON_CONFIG_DIR = "/etc/karton"

# Create directory if it doesn't exist
os.makedirs(KARTON_CONFIG_DIR, exist_ok=True)

if REDIS_CONN_STR:
    # Parse Redis URL
    url = urllib.parse.urlparse(REDIS_CONN_STR)
    host = url.hostname or "localhost"
    port = url.port or 6379
    db = (url.path or "/0").lstrip("/") or "0"
    password = url.password or ""
    username = url.username or ""

    # Generate karton.ini content with S3 section (required by karton-system)
    # We use a dummy S3 config that won't cause connection errors
    # karton-system requires S3 config even with --disable-gc
    config_lines = [
        "[dashboard]",
        "base_path=/karton-dashboard/",
        "",
        "[s3]",
        "# S3 configuration is required by karton-system but not used on Railway",
        "# Using a dummy endpoint that won't cause immediate connection errors",
        "address=http://127.0.0.1:65535/",
        "access_key=dummy",
        "secret_key=dummy",
        "bucket=dummy",
        "",
        "[redis]",
        f"host={host}",
        f"port={port}",
        f"db={db}",
    ]

    if password:
        config_lines.append(f"password={password}")
    if username:
        config_lines.append(f"username={username}")

    # Write config file
    config_content = "\n".join(config_lines) + "\n"
    with open(KARTON_CONFIG_PATH, "w") as f:
        f.write(config_content)

    print(f"Generated {KARTON_CONFIG_PATH} from REDIS_CONN_STR (without S3 section)")
    print(f"Config content:\n{config_content}")
else:
    print(f"REDIS_CONN_STR not set, using default {KARTON_CONFIG_PATH}")
