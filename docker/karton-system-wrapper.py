#!/usr/bin/env python3
"""Wrapper for karton-system that patches S3 bucket check to skip it on Railway."""
import sys
import os
import time
import logging
import threading
from datetime import datetime

# Configure logging to stdout for Railway
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s][%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Patch karton.system.system.SystemService.ensure_bucket_exists before importing
# This allows karton-system to start without checking S3 bucket
def patch_karton_system():
    """Patch karton-system to skip S3 bucket check."""
    try:
        # Import karton modules
        import karton.system.system
        
        # Save original method
        original_ensure_bucket = karton.system.system.SystemService.ensure_bucket_exists
        
        # Create patched method that always returns True (bucket exists)
        def patched_ensure_bucket(self, create=False):
            """Patched version that skips S3 bucket check."""
            logger.info("Skipping S3 bucket check (not available on Railway)")
            return True
        
        # Replace method
        karton.system.system.SystemService.ensure_bucket_exists = patched_ensure_bucket
        logger.info("Patched karton-system to skip S3 bucket check")
    except Exception as e:
        logger.warning(f"Could not patch karton-system: {e}", exc_info=True)
        # Continue anyway - karton-system will try to check S3 and may fail

def start_heartbeat_monitor():
    """Start a background thread to monitor karton-system and log heartbeats."""
    def heartbeat_loop():
        """Background thread that logs heartbeats every 5 minutes."""
        time.sleep(60)  # Wait 1 minute before first heartbeat
        last_heartbeat = time.time()
        heartbeat_interval = 300  # Log heartbeat every 5 minutes
        
        while True:
            try:
                time.sleep(60)  # Check every minute
                current_time = time.time()
                
                if current_time - last_heartbeat >= heartbeat_interval:
                    # Check Redis queue status
                    try:
                        from karton.core.backend import KartonBackend
                        from karton.core.config import Config as KartonConfig
                        
                        backend = KartonBackend(config=KartonConfig())
                        unrouted_count = backend.redis.llen("karton.tasks")
                        logger.info(f"[HEARTBEAT] karton-system is alive. Unrouted tasks in queue: {unrouted_count}")
                        last_heartbeat = current_time
                    except Exception as e:
                        logger.warning(f"[HEARTBEAT] Error checking queue status: {e}")
            except Exception as e:
                logger.warning(f"[HEARTBEAT] Error in heartbeat loop: {e}")
                time.sleep(60)  # Wait before retrying
    
    # Start heartbeat thread as daemon (will stop when main thread stops)
    heartbeat_thread = threading.Thread(target=heartbeat_loop, daemon=True)
    heartbeat_thread.start()
    logger.info("Started heartbeat monitor thread")

if __name__ == "__main__":
    logger.info("=" * 60)
    logger.info("Starting karton-system wrapper")
    logger.info(f"Timestamp: {datetime.now().isoformat()}")
    logger.info("=" * 60)
    
    # Patch before importing karton-system main
    patch_karton_system()
    
    # Start heartbeat monitor in background
    start_heartbeat_monitor()
    
    # Now import and run karton-system
    try:
        from karton.system.system import SystemService
        logger.info("Starting karton-system SystemService.main()")
        SystemService.main()
    except KeyboardInterrupt:
        logger.info("Received KeyboardInterrupt, shutting down")
        sys.exit(0)
    except Exception as e:
        logger.error(f"[FATAL] karton-system crashed: {e}", exc_info=True)
        sys.exit(1)
