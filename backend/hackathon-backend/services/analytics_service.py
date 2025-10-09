"""
Analytics service for collecting and reporting application metrics
"""

import asyncio
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

from sqlalchemy.orm import Session
from sqlalchemy import func, desc, and_
import time
import psutil

from database import get_db
from models import AuditLog, User, Deliverable, Sprint, Signoff, Notification


class AnalyticsService:
    """Service for analytics data collection and processing"""
    
    def __init__(self):
        self._is_running = False
        self._background_task = None
        self.metrics_cache = {}
        self.performance_metrics = {
            'response_times': [],
            'error_rates': [],
            'throughput': []
        }
        self.cache_ttl = 300
        self.start_time = time.time()
    
    async def start(self):
        """Start analytics service"""
        if self._is_running:
            return
        self._is_running = True
        self._background_task = asyncio.create_task(self._periodic_metrics_update())
    
    async def stop(self):
        """Stop analytics service"""
        self._is_running = False
        if self._background_task:
            self._background_task.cancel()
    
    async def _periodic_metrics_update(self):
        """Periodically update cached metrics"""
        while self._is_running:
            try:
                await self._update_all_metrics()
                await asyncio.sleep(self.cache_ttl)
            except Exception:
                await asyncio.sleep(60)
    
    async def _update_all_metrics(self):
        """Update all cached metrics"""
        from database import SessionLocal
        db = SessionLocal()
        try:
            self.metrics_cache = {
                "user_activity": await self._get_user_activity_metrics(db),
                "system_usage": await self._get_system_usage_metrics(db),
                "project_metrics": await self._get_project_metrics(db),
                "performance": await self._get_performance_metrics(),
                "timestamp": datetime.now().isoformat()
            }
        finally:
            db.close()
    
    async def get_metrics(self, metric_type: Optional[str] = None) -> Dict[str, Any]:
        """Get cached metrics"""
        if not self.metrics_cache:
            await self._update_all_metrics()
        
        if metric_type:
            return self.metrics_cache.get(metric_type, {})
        
        # Return flat structure for frontend compatibility
        metrics = self.metrics_cache
        user_activity = metrics.get("user_activity", {})
        project_metrics = metrics.get("project_metrics", {})
        
        # Convert to frontend-expected format
        flat_metrics = {
            # User metrics
            "total_users": user_activity.get("total_users", 0),
            "active_users_24h": user_activity.get("active_users_24h", 0),
            
            # Sprint metrics
            "total_sprints": project_metrics.get("total_sprints", 0),
            "active_sprints": project_metrics.get("sprint_status", {}).get("active", 0),
            "completed_sprints": project_metrics.get("sprint_status", {}).get("completed", 0),
            
            # Deliverable metrics
            "total_deliverables": project_metrics.get("total_deliverables", 0),
            "pending_deliverables": project_metrics.get("deliverable_status", {}).get("pending", 0),
            "completed_deliverables": project_metrics.get("deliverable_status", {}).get("completed", 0),
            "overdue_deliverables": project_metrics.get("deliverable_status", {}).get("overdue", 0),
            
            # System metrics
            "system_usage": metrics.get("system_usage", {}),
            "performance": metrics.get("performance", {}),
            "timestamp": metrics.get("timestamp", "")
        }
        
        return flat_metrics
    
    async def _get_user_activity_metrics(self, db: Session) -> Dict[str, Any]:
        """Get user activity metrics"""
        user_counts = db.query(User.role, func.count(User.id)).group_by(User.role).all()
        active_users = db.query(func.count(User.id)).filter(
            User.last_login >= datetime.now() - timedelta(hours=24)
        ).scalar() or 0
        
        return {
            "total_users": db.query(func.count(User.id)).scalar() or 0,
            "users_by_role": dict(user_counts),
            "active_users_24h": active_users
        }
    
    async def _get_system_usage_metrics(self, db: Session) -> Dict[str, Any]:
        """Get system usage metrics"""
        common_actions = db.query(
            AuditLog.action, func.count(AuditLog.id)
        ).group_by(AuditLog.action).order_by(desc(func.count(AuditLog.id))).limit(10).all()
        
        return {
            "total_actions": db.query(func.count(AuditLog.id)).scalar() or 0,
            "common_actions": [{"action": action, "count": count} for action, count in common_actions],
            "actions_last_24h": db.query(func.count(AuditLog.id)).filter(
                AuditLog.created_at >= datetime.now() - timedelta(hours=24)
            ).scalar() or 0
        }
    
    async def _get_project_metrics(self, db: Session) -> Dict[str, Any]:
        """Get project metrics"""
        deliverable_status = db.query(
            Deliverable.status, func.count(Deliverable.id)
        ).group_by(Deliverable.status).all()
        
        sprint_status = db.query(
            Sprint.status, func.count(Sprint.id)
        ).group_by(Sprint.status).all()
        
        return {
            "total_deliverables": db.query(func.count(Deliverable.id)).scalar() or 0,
            "total_sprints": db.query(func.count(Sprint.id)).scalar() or 0,
            "deliverable_status": dict(deliverable_status),
            "sprint_status": dict(sprint_status)
        }
    
    async def get_user_analytics(self, user_id: int) -> Dict[str, Any]:
        """Get user-specific analytics"""
        from database import SessionLocal
        db = SessionLocal()
        try:
            user_actions = db.query(func.count(AuditLog.id)).filter(
                AuditLog.user_id == user_id
            ).scalar() or 0
            
            user_actions_24h = db.query(func.count(AuditLog.id)).filter(
                and_(
                    AuditLog.user_id == user_id,
                    AuditLog.created_at >= datetime.now() - timedelta(hours=24)
                )
            ).scalar() or 0
            
            return {
                "total_actions": user_actions,
                "actions_24h": user_actions_24h
            }
        finally:
            db.close()

    async def _get_performance_metrics(self) -> Dict[str, Any]:
        """Get system performance metrics"""
        try:
            # System metrics
            cpu_percent = psutil.cpu_percent(interval=1)
            memory_info = psutil.virtual_memory()
            disk_usage = psutil.disk_usage('/')
            
            # Process metrics
            process = psutil.Process()
            process_memory = process.memory_info().rss / 1024 / 1024  # MB
            process_threads = process.num_threads()
            
            # Uptime
            uptime = time.time() - self.start_time
            
            return {
                "cpu_percent": cpu_percent,
                "memory_percent": memory_info.percent,
                "memory_used_mb": memory_info.used / 1024 / 1024,
                "memory_total_mb": memory_info.total / 1024 / 1024,
                "disk_percent": disk_usage.percent,
                "disk_used_gb": disk_usage.used / 1024 / 1024 / 1024,
                "disk_total_gb": disk_usage.total / 1024 / 1024 / 1024,
                "process_memory_mb": process_memory,
                "process_threads": process_threads,
                "uptime_seconds": uptime,
                "uptime_formatted": str(timedelta(seconds=int(uptime)))
            }
        except Exception:
            return {"error": "Unable to collect performance metrics"}

    def record_response_time(self, response_time: float):
        """Record API response time"""
        self.performance_metrics['response_times'].append(response_time)
        # Keep only last 1000 measurements
        if len(self.performance_metrics['response_times']) > 1000:
            self.performance_metrics['response_times'] = self.performance_metrics['response_times'][-1000:]

    def record_error(self):
        """Record error occurrence"""
        self.performance_metrics['error_rates'].append(1)
        if len(self.performance_metrics['error_rates']) > 1000:
            self.performance_metrics['error_rates'] = self.performance_metrics['error_rates'][-1000:]

    def record_success(self):
        """Record successful request"""
        self.performance_metrics['error_rates'].append(0)
        if len(self.performance_metrics['error_rates']) > 1000:
            self.performance_metrics['error_rates'] = self.performance_metrics['error_rates'][-1000:]


# Global analytics service instance
analytics_service = AnalyticsService()