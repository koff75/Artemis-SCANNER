#!/usr/bin/env python3
"""Wrapper for karton-system that patches S3 bucket check to skip it on Railway."""
import sys
import os

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
            print("Skipping S3 bucket check (not available on Railway)")
            return True
        
        # Replace method
        karton.system.system.SystemService.ensure_bucket_exists = patched_ensure_bucket
        print("Patched karton-system to skip S3 bucket check")
    except Exception as e:
        print(f"Warning: Could not patch karton-system: {e}", file=sys.stderr)
        # Continue anyway - karton-system will try to check S3 and may fail

if __name__ == "__main__":
    # Patch before importing karton-system main
    patch_karton_system()
    
    # Now import and run karton-system
    from karton.system.system import SystemService
    SystemService.main()
