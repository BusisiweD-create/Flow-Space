"""
Analytics dashboard endpoints for reporting and insights
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Dict, Any, Optional, List
from sqlalchemy.orm import Session

from database import get_db
from services.analytics_service import analytics_service
from dependencies import get_current_user
from models import User

router = APIRouter()


@router.get("/dashboard", response_model=Dict[str, Any])
async def get_dashboard_metrics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get comprehensive dashboard metrics
    Includes user activity, system usage, and project metrics
    """
    try:
        metrics = await analytics_service.get_metrics()
        return metrics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching metrics: {str(e)}")


@router.get("/user-activity", response_model=Dict[str, Any])
async def get_user_activity_metrics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user activity metrics
    """
    try:
        metrics = await analytics_service.get_metrics("user_activity")
        return metrics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching user activity metrics: {str(e)}")


@router.get("/system-usage", response_model=Dict[str, Any])
async def get_system_usage_metrics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get system usage metrics from audit logs
    """
    try:
        metrics = await analytics_service.get_metrics("system_usage")
        return metrics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching system usage metrics: {str(e)}")


@router.get("/project-metrics", response_model=Dict[str, Any])
async def get_project_metrics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get project and deliverable metrics
    """
    try:
        metrics = await analytics_service.get_metrics("project_metrics")
        return metrics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching project metrics: {str(e)}")


@router.get("/user/{user_id}", response_model=Dict[str, Any])
async def get_user_analytics(
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get analytics for a specific user
    """
    # Only allow users to view their own analytics or admins
    if current_user.id != user_id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to view this user's analytics")
    
    try:
        user_analytics = await analytics_service.get_user_analytics(user_id)
        return user_analytics
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching user analytics: {str(e)}")


@router.get("/health")
async def get_analytics_health():
    """
    Get analytics service health status
    """
    return {
        "status": "running" if analytics_service._is_running else "stopped",
        "last_updated": analytics_service.metrics_cache.get("timestamp") if analytics_service.metrics_cache else None
    }


@router.get("/health/public")
async def get_public_analytics_health():
    """
    Get public analytics service health status (no authentication required)
    """
    try:
        # Test that we can get metrics without authentication
        metrics = await analytics_service.get_metrics()
        return {
            "status": "running",
            "has_metrics": bool(metrics),
            "total_sprints": metrics.get("total_sprints", 0),
            "total_deliverables": metrics.get("total_deliverables", 0),
            "total_users": metrics.get("total_users", 0)
        }
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }


@router.get("/trends/daily-activity")
async def get_daily_activity_trend(
    days: int = Query(30, ge=1, le=365),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get daily activity trend for charting
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    try:
        from sqlalchemy import func, Date
        from datetime import datetime, timedelta
        
        daily_activity = db.query(
            func.date(analytics_service._AuditLog.timestamp).label("date"),
            func.count(analytics_service._AuditLog.id)
        ).filter(
            analytics_service._AuditLog.timestamp >= datetime.now() - timedelta(days=days)
        ).group_by(func.date(analytics_service._AuditLog.timestamp)).order_by("date").all()
        
        return [{"date": date.isoformat(), "count": count} for date, count in daily_activity]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching daily activity: {str(e)}")


@router.get("/trends/user-registration")
async def get_user_registration_trend(
    weeks: int = Query(12, ge=1, le=52),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get user registration trend for charting
    """
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    try:
        from sqlalchemy import func
        from datetime import datetime, timedelta
        
        weekly_registrations = db.query(
            func.date_trunc('week', User.created_at).label("week"),
            func.count(User.id)
        ).filter(
            User.created_at >= datetime.now() - timedelta(weeks=weeks)
        ).group_by(func.date_trunc('week', User.created_at)).order_by("week").all()
        
        return [{"week": week.isoformat(), "count": count} for week, count in weekly_registrations]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching registration trend: {str(e)}")