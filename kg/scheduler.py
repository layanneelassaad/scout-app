#!/usr/bin/env python3
"""
Knowledge Graph Indexing Scheduler

This module provides a simple scheduler for running periodic indexing
of watched directories. It can be run as a standalone script or imported
and used programmatically.

Usage:
    python -m mr_kg.scheduler

Or as a service:
    from mr_kg.scheduler import start_scheduler
    start_scheduler()
"""

import asyncio
import logging
import time
from datetime import datetime, timedelta
from typing import Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class KGScheduler:
    """Simple scheduler for knowledge graph indexing."""
    _instance = None
    
    def __init__(self, check_interval: int = 3600):
        """
        Initialize the scheduler.
        
        Args:
            check_interval: How often to check for scheduled tasks (seconds)
        """
        self.check_interval = check_interval
        self.running = False
        self._task: Optional[asyncio.Task] = None
        
        # Prevent multiple scheduler instances
        if KGScheduler._instance is not None:
            raise RuntimeError("Only one KGScheduler instance is allowed. Use get_scheduler() to get the existing instance.")
        
        KGScheduler._instance = self
    
    async def run_scheduled_indexing(self):
        """Run the scheduled indexing process."""
        try:
            # Import here to avoid circular imports
            from .mod import kg_run_scheduled_indexing
            
            logger.info("Running scheduled indexing...")
            result = await kg_run_scheduled_indexing()
            
            if result.get('success'):
                processed = result.get('processed', [])
                errors = result.get('errors', [])
                logger.info(f"Scheduled indexing completed: {len(processed)} directories processed, {len(errors)} errors")
                
                # Log details
                for proc in processed:
                    logger.info(f"  Processed: {proc.get('path')} - {proc.get('files_processed', 0)} files")
                
                for error in errors[:5]:  # Log first 5 errors
                    logger.warning(f"  Error: {error}")
                    
                if len(errors) > 5:
                    logger.warning(f"  ... and {len(errors) - 5} more errors")
            else:
                logger.error(f"Scheduled indexing failed: {result.get('error')}")
                
        except Exception as e:
            logger.error(f"Error during scheduled indexing: {e}")
    
    async def _scheduler_loop(self):
        """Main scheduler loop."""
        logger.info(f"Knowledge Graph scheduler started (check interval: {self.check_interval}s)")
        
        while self.running:
            try:
                await self.run_scheduled_indexing()
            except Exception as e:
                logger.error(f"Error in scheduler loop: {e}")
            
            # Wait for next check
            await asyncio.sleep(self.check_interval)
        
        logger.info("Knowledge Graph scheduler stopped")
    
    def start(self):
        """Start the scheduler."""
        if self.running:
            logger.warning("Scheduler is already running")
            return
        
        self.running = True
        self._task = asyncio.create_task(self._scheduler_loop())
        logger.info("Scheduler started")
    
    async def stop(self):
        """Stop the scheduler."""
        if not self.running:
            return
        
        self.running = False
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        
        logger.info("Scheduler stopped")
        KGScheduler._instance = None

# Global scheduler instance
_scheduler: Optional[KGScheduler] = None

def start_scheduler(check_interval: int = 3600):
    """Start the global scheduler instance."""
    global _scheduler
    
    # Check if scheduler is already running
    if _scheduler is not None and _scheduler.running:
        logger.warning("Scheduler is already running")
        return _scheduler
    
    if _scheduler is None:
        _scheduler = KGScheduler(check_interval)
    
    _scheduler.start()
    return _scheduler

async def stop_scheduler():
    """Stop the global scheduler instance."""
    global _scheduler
    
    if _scheduler:
        logger.info("Stopping scheduler...")
        await _scheduler.stop()
        _scheduler = None

def get_scheduler() -> Optional[KGScheduler]:
    """Get the global scheduler instance."""
    return _scheduler

async def main():
    """Main function for running as a standalone script."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Knowledge Graph Indexing Scheduler')
    parser.add_argument(
        '--interval', 
        type=int, 
        default=3600, 
        help='Check interval in seconds (default: 3600 = 1 hour)'
    )
    parser.add_argument(
        '--run-once', 
        action='store_true', 
        help='Run indexing once and exit'
    )
    
    args = parser.parse_args()
    
    if args.run_once:
        # Run once and exit
        scheduler = KGScheduler()
        await scheduler.run_scheduled_indexing()
        logger.info("One-time indexing completed")
    else:
        # Run continuously
        scheduler = start_scheduler(args.interval)
        
        try:
            # Keep running until interrupted
            while True:
                await asyncio.sleep(1)
        except KeyboardInterrupt:
            logger.info("Received interrupt signal")
        finally:
            await stop_scheduler()

if __name__ == '__main__':
    asyncio.run(main())
