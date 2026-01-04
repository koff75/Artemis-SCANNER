import logging
from typing import Any, Dict, List, Optional

from karton.core import Producer, Task
from karton.core.task import TaskPriority

from artemis.binds import TaskType
from artemis.db import DB

# Lazy initialization of Producer to avoid Redis connection errors on import
_producer: Optional[Producer] = None
db = DB()
logger = logging.getLogger(__name__)


def get_producer() -> Producer:
    """Get or create the Producer instance (lazy initialization)."""
    global _producer
    if _producer is None:
        import os
        config_path = "/etc/karton/karton.ini"
        logger.info(f"Initializing Producer with identity='frontend', config_path={config_path}")
        if os.path.exists(config_path):
            logger.info(f"karton.ini exists at {config_path}")
            with open(config_path, 'r') as f:
                logger.info(f"karton.ini content:\n{f.read()}")
        else:
            logger.warning(f"karton.ini NOT found at {config_path}")
        _producer = Producer(identity="frontend")
        logger.info("Producer initialized successfully")
    return _producer


def create_tasks(
    uris: List[str],
    tag: Optional[str] = None,
    disabled_modules: List[str] = [],
    priority: Optional[TaskPriority] = None,
    requests_per_second_override: Optional[float] = None,
    module_runtime_configurations: Optional[Dict[str, Dict[str, Any]]] = None,
) -> None:
    for uri in uris:
        # Use .value to ensure we pass a string, not an enum, to Karton
        task = Task({"type": TaskType.NEW.value})
        task.add_payload("data", uri)
        if priority:
            task.priority = priority
        if tag:
            task.add_payload("tag", tag, persistent=True)
        if requests_per_second_override:
            task.add_payload("requests_per_second_override", requests_per_second_override, persistent=True)
        task.add_payload("disabled_modules", ",".join(disabled_modules), persistent=True)

        # Add module configurations to task payload and log
        if module_runtime_configurations:
            logger.info(f"Adding module configurations for task {uri}: {module_runtime_configurations}")
            task.add_payload("module_runtime_configurations", module_runtime_configurations, persistent=True)
        else:
            logger.debug(f"No module configurations provided for task {uri}")

        db.create_analysis(task)
        db.save_scheduled_task(task)
        db.save_tag(tag)
        logger.info(f"Sending task to Redis: {task.uid}, type={task.headers.get('type')}, data={task.payload.get('data')}")
        try:
            producer = get_producer()
            # Log task details before sending
            logger.info(f"Task headers: {task.headers}, payload keys: {list(task.payload.keys())}")
            # Check if we can see binds (for debugging)
            try:
                from karton.core.backend import KartonBackend
                from karton.core.config import Config as KartonConfig
                backend = KartonBackend(config=KartonConfig())
                binds = backend.get_binds()
                logger.info(f"Found {len(binds)} registered binds in Redis")
                # Log binds that match this task type
                # KartonBind objects have .filters (list of dict) and .identity attributes
                task_type = task.headers.get('type')
                if isinstance(task_type, TaskType):
                    task_type = task_type.value
                # filters is a list of filter dicts, check if any filter matches
                matching_binds = []
                for b in binds:
                    for filter_dict in b.filters:
                        if filter_dict.get('type') == task_type:
                            matching_binds.append(b)
                            break
                logger.info(f"Found {len(matching_binds)} binds matching type={task_type}: {[b.identity for b in matching_binds]}")
            except Exception as bind_error:
                logger.warning(f"Could not check binds: {bind_error}", exc_info=True)
            
            producer.send_task(task)
            logger.info(f"Task {task.uid} successfully sent to Redis queue")
            # Check Redis queues after sending to see where the task went
            try:
                from karton.core.backend import KartonBackend
                from karton.core.config import Config as KartonConfig
                backend = KartonBackend(config=KartonConfig())
                # Check all queues that might contain the task
                classifier_queues = [
                    "classifier",
                    "karton.queue.high:classifier",
                    "karton.queue.normal:classifier",
                    "karton.queue.low:classifier"
                ]
                logger.info(f"Checking Redis queues for task {task.uid}...")
                found_queues = []
                for queue_name in classifier_queues:
                    queue_length = backend.redis.llen(queue_name)
                    if queue_length > 0:
                        found_queues.append(queue_name)
                        logger.info(f"Queue {queue_name} has {queue_length} task(s)")
                        # Show first few task UIDs in queue
                        first_tasks = backend.redis.lrange(queue_name, 0, 4)
                        task_uids = [t.decode() if isinstance(t, bytes) else str(t) for t in first_tasks[:3]]
                        logger.info(f"First tasks in {queue_name}: {task_uids}")
                if not found_queues:
                    logger.warning(f"No tasks found in any classifier queue after sending task {task.uid}")
                    # Check ALL queues in Redis to see where tasks might be
                    all_queue_keys = backend.redis.keys("karton.queue.*")
                    logger.info(f"Found {len(all_queue_keys)} total Karton queues in Redis")
                    non_empty_queues = []
                    for queue_key in all_queue_keys[:20]:  # Check first 20 queues
                        queue_name = queue_key.decode() if isinstance(queue_key, bytes) else queue_key
                        queue_length = backend.redis.llen(queue_name)
                        if queue_length > 0:
                            non_empty_queues.append((queue_name, queue_length))
                    if non_empty_queues:
                        logger.info(f"Non-empty queues found: {non_empty_queues}")
                    else:
                        logger.warning("No tasks found in ANY Karton queue - task routing may have failed")
            except Exception as queue_error:
                logger.error(f"Could not check queues: {queue_error}", exc_info=True)
        except Exception as e:
            logger.error(f"Failed to send task {task.uid} to Redis: {e}", exc_info=True)
            raise
