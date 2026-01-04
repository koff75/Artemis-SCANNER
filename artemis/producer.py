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
        task = Task({"type": TaskType.NEW})
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
        except Exception as e:
            logger.error(f"Failed to send task {task.uid} to Redis: {e}", exc_info=True)
            raise
