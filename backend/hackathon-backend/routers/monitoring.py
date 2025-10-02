"""
Monitoring router for health checks, performance metrics, and system observability
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Dict, Any, List
import time

from database import get_db
from models import User, Deliverable, Sprint, Signoff, AuditLog
from services.analytics_service import analytics_service
from services.logging_service import logging_service

router = APIRouter()


@router.get("/health")
async def health_check(db: Session = Depends(get_db)):
    """Health check endpoint"""
    try:
        # Test database connection
        db.execute("SELECT 1")
        return {
            "status": "healthy",
            "database": "connected",
            "timestamp": time.time()
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Database connection failed: {str(e)}")


@router.get("/metrics/system")
async def get_system_metrics():
    """Get system performance metrics"""
    try:
        metrics = await analytics_service.get_metrics("performance")
        return {
            "status": "success",
            "metrics": metrics,
            "timestamp": time.time()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get system metrics: {str(e)}")


@router.get("/metrics/application")
async def get_application_metrics():
    """Get application performance metrics"""
    try:
        # Get response time statistics
        response_times = analytics_service.performance_metrics.get('response_times', [])
        error_rates = analytics_service.performance_metrics.get('error_rates', [])
        
        if response_times:
            avg_response_time = sum(response_times) / len(response_times)
            max_response_time = max(response_times)
            min_response_time = min(response_times)
        else:
            avg_response_time = max_response_time = min_response_time = 0
        
        if error_rates:
            error_count = sum(error_rates)
            error_rate = error_count / len(error_rates) * 100
        else:
            error_count = error_rate = 0
        
        return {
            "status": "success",
            "metrics": {
                "response_times": {
                    "count": len(response_times),
                    "average_ms": avg_response_time * 1000,
                    "max_ms": max_response_time * 1000,
                    "min_ms": min_response_time * 1000,
                    "p95_ms": sorted(response_times)[int(len(response_times) * 0.95)] * 1000 if response_times else 0
                },
                "error_rates": {
                    "total_requests": len(error_rates),
                    "error_count": error_count,
                    "error_rate_percent": error_rate
                },
                "throughput": {
                    "requests_per_minute": len(error_rates) / (analytics_service.cache_ttl / 60) if error_rates else 0
                }
            },
            "timestamp": time.time()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get application metrics: {str(e)}")


@router.get("/metrics/database")
async def get_database_metrics(db: Session = Depends(get_db)):
    """Get database metrics and entity counts"""
    try:
        user_count = db.query(User).count()
        deliverable_count = db.query(Deliverable).count()
        sprint_count = db.query(Sprint).count()
        signoff_count = db.query(Signoff).count()
        audit_log_count = db.query(AuditLog).count()
        
        return {
            "status": "success",
            "metrics": {
                "users": user_count,
                "deliverables": deliverable_count,
                "sprints": sprint_count,
                "signoffs": signoff_count,
                "audit_logs": audit_log_count,
                "total_entities": user_count + deliverable_count + sprint_count + signoff_count + audit_log_count
            },
            "timestamp": time.time()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get database metrics: {str(e)}")


@router.get("/logs/recent")
async def get_recent_logs(limit: int = 50):
    """Get recent application logs"""
    try:
        logs = logging_service.get_recent_logs(limit)
        return {
            "status": "success",
            "logs": logs,
            "count": len(logs),
            "timestamp": time.time()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get logs: {str(e)}")


@router.get("/status/comprehensive")
async def get_comprehensive_status(db: Session = Depends(get_db)):
    """Get comprehensive system status including all metrics"""
    try:
        # Get all metrics concurrently
        system_metrics = await analytics_service.get_metrics("performance")
        
        # Get database metrics
        user_count = db.query(User).count()
        deliverable_count = db.query(Deliverable).count()
        sprint_count = db.query(Sprint).count()
        
        # Get application metrics
        response_times = analytics_service.performance_metrics.get('response_times', [])
        error_rates = analytics_service.performance_metrics.get('error_rates', [])
        
        if response_times:
            avg_response_time = sum(response_times) / len(response_times)
        else:
            avg_response_time = 0
        
        if error_rates:
            error_count = sum(error_rates)
            error_rate = error_count / len(error_rates) * 100
        else:
            error_count = error_rate = 0
        
        return {
            "status": "success",
            "system": system_metrics,
            "database": {
                "users": user_count,
                "deliverables": deliverable_count,
                "sprints": sprint_count,
                "total_entities": user_count + deliverable_count + sprint_count
            },
            "application": {
                "response_time_avg_ms": avg_response_time * 1000,
                "error_rate_percent": error_rate,
                "total_requests": len(error_rates),
                "error_count": error_count
            },
            "services": {
                "analytics_service": analytics_service._is_running,
                "logging_service": logging_service._is_running,
                "uptime_seconds": time.time() - analytics_service.start_time
            },
            "timestamp": time.time()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get comprehensive status: {str(e)}")


@router.get("/alerts")
async def get_system_alerts():
    """Get system alerts and warnings"""
    try:
        system_metrics = await analytics_service.get_metrics("performance")
        alerts = []
        
        # Check for high CPU usage
        if system_metrics.get('cpu_percent', 0) > 80:
            alerts.append({
                "level": "warning",
                "message": f"High CPU usage: {system_metrics['cpu_percent']}%",
                "metric": "cpu_percent"
            })
        
        # Check for high memory usage
        if system_metrics.get('memory_percent', 0) > 85:
            alerts.append({
                "level": "warning",
                "message": f"High memory usage: {system_metrics['memory_percent']}%",
                "metric": "memory_percent"
            })
        
        # Check for high disk usage
        if system_metrics.get('disk_percent', 0) > 90:
            alerts.append({
                "level": "warning",
                "message": f"High disk usage: {system_metrics['disk_percent']}%",
                "metric": "disk_percent"
            })
        
        return {
            "status": "success",
            "alerts": alerts,
            "count": len(alerts),
            "timestamp": time.time()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get alerts: {str(e)}")