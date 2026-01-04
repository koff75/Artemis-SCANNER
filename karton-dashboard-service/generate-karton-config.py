#!/usr/bin/env python3
"""Generate karton.ini from REDIS_CONN_STR environment variable for Railway deployment."""
import os
import urllib.parse

REDIS_CONN_STR = os.environ.get("REDIS_CONN_STR")
KARTON_CONFIG_PATH = "/etc/karton/karton.ini"

if REDIS_CONN_STR:
    # Parse Redis URL
    url = urllib.parse.urlparse(REDIS_CONN_STR)
    host = url.hostname or "localhost"
    port = url.port or 6379
    db = (url.path or "/0").lstrip("/") or "0"
    password = url.password or ""
    username = url.username or ""

    # Generate karton.ini content
    config_lines = [
        "[dashboard]",
        "base_path=/karton-dashboard/",
        "",
        "[s3]",
        "# These need to be provided, so let's provide a mock - but we don't want to have a proper",
        "# s3-compatible storage instance, as we don't use this feature.",
        "address=http://s3mock:9090/",
        "access_key=mock_access_key",
        "secret_key=mock_secret_key",
        "bucket=bucket",
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

    print(f"Generated {KARTON_CONFIG_PATH} from REDIS_CONN_STR")
    print(f"Config content:\n{config_content}")
else:
    print(f"REDIS_CONN_STR not set, using default {KARTON_CONFIG_PATH}")
