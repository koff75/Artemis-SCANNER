#!/bin/bash
python3 /usr/local/bin/generate-karton-config.py
exec karton-dashboard run --host 0.0.0.0 --port ${PORT:-5000}
