"""
Logging service for structured logging, monitoring, and observability
"""

import logging
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from contextvars import ContextVar
import uuid
from dataclasses import dataclass
from enum import Enum

from sqlalchemy.orm import Session
from database import get_db
from models import AuditLog
from schemas import AuditLogCreate

# Context variables for request tracking
request_id_var: ContextVar[str] = ContextVar('request_id', default='')
user_id_var: ContextVar[str] = ContextVar('user_id', default='')

class LogLevel(str, Enum):
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"

class LogCategory(str, Enum):
    AUDIT = "AUDIT"
    PERFORMANCE = "PERFORMANCE"
    SECURITY = "SECURITY"
    BUSINESS = "BUSINESS"
    SYSTEM = "SYSTEM"
    DATABASE = "DATABASE"
    API = "API"
    WEBSOCKET = "WEBSOCKET"

@dataclass
class LogEntry:
    timestamp: datetime
    level: LogLevel
    category: LogCategory
    message: str
    request_id: str
    user_id: Optional[str]
    duration_ms: Optional[float] = None
    metadata: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    stack_trace: Optional[str] = None

class LoggingService:
    def __init__(self):
        self._logger = logging.getLogger(__name__)
        self._setup_logging()
        self._metrics: Dict[str, Any] = {
            'request_count': 0,
            'error_count': 0,
            'avg_response_time': 0.0,
            'active_requests': 0,
            'last_cleanup': datetime.now()
        }
        self._request_times: Dict[str, float] = {}
        
    def _setup_logging(self):
        """Configure structured logging"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.StreamHandler(),
                logging.FileHandler('app.log', encoding='utf-8')
            ]
        )
        
        # Add JSON formatter for structured logs
        json_handler = logging.FileHandler('structured.log', encoding='utf-8')
        json_handler.setFormatter(self._json_formatter())
        self._logger.addHandler(json_handler)
    
    def _json_formatter(self):
        """Create JSON formatter for structured logging"""
        class JSONFormatter(logging.Formatter):
            def format(self, record):
                log_data = {
                    'timestamp': datetime.fromtimestamp(record.created).isoformat(),
                    'level': record.levelname,
                    'logger': record.name,
                    'message': record.getMessage(),
                    'request_id': request_id_var.get(),
                    'user_id': user_id_var.get(),
                    'module': record.module,
                    'function': record.funcName,
                    'line': record.lineno
                }
                
                if hasattr(record, 'category'):
                    log_data['category'] = record.category
                if hasattr(record, 'duration_ms'):
                    log_data['duration_ms'] = record.duration_ms
                if hasattr(record, 'metadata'):
                    log_data['metadata'] = record.metadata
                if record.exc_info:
                    log_data['error'] = self.formatException(record.exc_info)
                
                return json.dumps(log_data)
        
        return JSONFormatter()
    
    async def start(self):
        """Start logging service background tasks"""
        self._logger.info("Logging service started")
    
    async def stop(self):
        """Stop logging service"""
        self._logger.info("Logging service stopped")
    
    def log(self, level: LogLevel, category: LogCategory, message: str, 
           duration_ms: Optional[float] = None, metadata: Optional[Dict] = None,
           error: Optional[str] = None, stack_trace: Optional[str] = None):
        """Log a structured message"""
        log_entry = LogEntry(
            timestamp=datetime.now(),
            level=level,
            category=category,
            message=message,
            request_id=request_id_var.get(),
            user_id=user_id_var.get(),
            duration_ms=duration_ms,
            metadata=metadata,
            error=error,
            stack_trace=stack_trace
        )
        
        self._write_log(log_entry)
        
        # Also create audit log for certain categories
        if category in [LogCategory.AUDIT, LogCategory.SECURITY, LogCategory.BUSINESS]:
            self._create_audit_log(log_entry)
    
    def _write_log(self, log_entry: LogEntry):
        """Write log entry using appropriate logging level"""
        extra = {
            'category': log_entry.category.value,
            'request_id': log_entry.request_id,
            'user_id': log_entry.user_id
        }
        
        if log_entry.duration_ms:
            extra['duration_ms'] = log_entry.duration_ms
        if log_entry.metadata:
            extra['metadata'] = log_entry.metadata
        
        log_method = getattr(self._logger, log_entry.level.value.lower())
        log_method(log_entry.message, extra=extra)
    
    def _create_audit_log(self, log_entry: LogEntry):
        """Create audit log entry in database"""
        try:
            db = next(get_db())
            audit_log = AuditLogCreate(
                entity_type="system",
                entity_id=0,
                action=f"{log_entry.category.value}_{log_entry.level.value}",
                user=log_entry.user_id,
                details=json.dumps({
                    'message': log_entry.message,
                    'request_id': log_entry.request_id,
                    'metadata': log_entry.metadata or {}
                })
            )
            
            from crud import create_audit_log
            create_audit_log(db, audit_log)
        except Exception as e:
            self._logger.error(f"Failed to create audit log: {e}")
    
    def start_request(self, request_id: str, user_id: Optional[str] = None):
        """Track request start"""
        request_id_var.set(request_id)
        if user_id:
            user_id_var.set(user_id)
        
        self._request_times[request_id] = time.time()
        self._metrics['active_requests'] += 1
        self._metrics['request_count'] += 1
    
    def end_request(self, request_id: str, status_code: int):
        """Track request completion"""
        if request_id in self._request_times:
            duration = (time.time() - self._request_times[request_id]) * 1000
            
            # Update metrics
            self._metrics['active_requests'] -= 1
            
            if status_code >= 400:
                self._metrics['error_count'] += 1
            
            # Log request completion
            self.log(
                LogLevel.INFO if status_code < 400 else LogLevel.ERROR,
                LogCategory.API,
                f"Request completed: {status_code}",
                duration_ms=duration,
                metadata={'status_code': status_code}
            )
            
            del self._request_times[request_id]
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get current logging metrics"""
        return self._metrics.copy()
    
    def get_recent_logs(self, limit: int = 100) -> List[Dict[str, Any]]:
        """Get recent logs from database"""
        try:
            db = next(get_db())
            logs = db.query(AuditLog).order_by(AuditLog.timestamp.desc()).limit(limit).all()
            return [
                {
                    'timestamp': log.timestamp,
                    'action': log.action,
                    'user': log.user,
                    'details': json.loads(log.details) if log.details else {}
                }
                for log in logs
            ]
        except Exception as e:
            self._logger.error(f"Failed to get recent logs: {e}")
            return []

# Global logging service instance
logging_service = LoggingService()