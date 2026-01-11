#!/usr/bin/env python3
"""Wrapper for karton-system that patches S3 bucket check to skip it on Railway."""
import sys
import os
import time
import logging
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

def add_diagnostic_logging():
    """Add diagnostic logging to karton-system to track task processing."""
    try:
        from karton.system.system import SystemService
        from karton.core.backend import KartonBackend
        from karton.core.config import Config as KartonConfig
        
        # Patch the main loop to add heartbeat logging
        original_run = SystemService.run
        
        def patched_run(self):
            """Patched run method with heartbeat logging."""
            logger.info("karton-system run() method started")
            last_heartbeat = time.time()
            heartbeat_interval = 300  # Log heartbeat every 5 minutes
            
            try:
                # Start the original run in a way we can monitor
                import threading
                import queue
                
                exception_queue = queue.Queue()
                
                def run_with_exception_capture():
                    try:
                        original_run(self)
                    except Exception as e:
                        exception_queue.put(e)
                        raise
                
                thread = threading.Thread(target=run_with_exception_capture, daemon=False)
                thread.start()
                
                # Monitor the thread and log heartbeats
                while thread.is_alive():
                    time.sleep(60)  # Check every minute
                    current_time = time.time()
                    
                    if current_time - last_heartbeat >= heartbeat_interval:
                        # Check Redis queue status
                        try:
                            backend = KartonBackend(config=KartonConfig())
                            unrouted_count = backend.redis.llen("karton.tasks")
                            logger.info(f"[HEARTBEAT] karton-system is alive. Unrouted tasks in queue: {unrouted_count}")
                            last_heartbeat = current_time
                        except Exception as e:
                            logger.warning(f"[HEARTBEAT] Error checking queue status: {e}")
                    
                    # Check for exceptions
                    try:
                        exc = exception_queue.get_nowait()
                        logger.error(f"[ERROR] karton-system run() raised exception: {exc}", exc_info=exc)
                        break
                    except queue.Empty:
                        pass
                
                thread.join()
                logger.info("karton-system run() method completed")
                
            except Exception as e:
                logger.error(f"[ERROR] Exception in patched run(): {e}", exc_info=True)
                raise
        
        SystemService.run = patched_run
        logger.info("Added diagnostic logging to karton-system")
        
    except Exception as e:
        logger.warning(f"Could not add diagnostic logging: {e}", exc_info=True)
        # Continue anyway

if __name__ == "__main__":
    logger.info("=" * 60)
    logger.info("Starting karton-system wrapper")
    logger.info(f"Timestamp: {datetime.now().isoformat()}")
    logger.info("=" * 60)
    
    # Patch before importing karton-system main
    patch_karton_system()
    
    # Add diagnostic logging
    add_diagnostic_logging()
    
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
