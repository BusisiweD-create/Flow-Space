"""
WebSocket router for real-time communication including presence tracking and notifications
"""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, HTTPException
from typing import Optional
import json

from services.presence_service import presence_service
from services.notification_service import notification_service
from routers.auth import get_current_user
from database import get_db
from models import User

router = APIRouter()

@router.websocket("/ws/presence/{user_id}")
async def websocket_presence_endpoint(websocket: WebSocket, user_id: str):
    """
    WebSocket endpoint for user presence tracking
    """
    await presence_service.connect(websocket, user_id)
    
    try:
        while True:
            # Keep connection alive and handle incoming messages
            data = await websocket.receive_text()
            message = json.loads(data)
            
            if message.get("type") == "ping":
                # Respond to ping with pong
                await websocket.send_json({"type": "pong", "timestamp": message.get("timestamp")})
                
            elif message.get("type") == "activity":
                # Handle user activity
                activity_type = message.get("activity_type")
                details = message.get("details", {})
                await presence_service.handle_activity(user_id, activity_type, details)
                
    except WebSocketDisconnect:
        await presence_service.disconnect(user_id)
    except Exception as e:
        print(f"WebSocket error for user {user_id}: {e}")
        await presence_service.disconnect(user_id)

@router.websocket("/ws/notifications/{user_id}")
async def websocket_notifications_endpoint(websocket: WebSocket, user_id: str):
    """
    WebSocket endpoint for real-time notifications
    """
    # Convert user_id to integer for consistency
    try:
        user_id_int = int(user_id)
    except ValueError:
        await websocket.close(code=1008, reason="Invalid user ID")
        return
    
    await notification_service.connect(websocket, user_id_int)
    
    try:
        while True:
            # Handle incoming messages
            data = await websocket.receive_text()
            message = json.loads(data)
            
            if message.get("type") == "ping":
                # Respond to ping with pong
                await websocket.send_json({"type": "pong", "timestamp": message.get("timestamp")})
                
            elif message.get("type") == "mark_read":
                # Mark notification as read
                notification_id = message.get("notification_id")
                if notification_id:
                    await notification_service.mark_as_read_and_notify(notification_id, user_id_int)
                
            elif message.get("type") == "subscribe":
                # Subscribe to notification types
                types_to_subscribe = set(message.get("types", []))
                notification_service.subscribe_user_to_types(user_id_int, types_to_subscribe)
                
            elif message.get("type") == "unsubscribe":
                # Unsubscribe from notification types
                types_to_unsubscribe = set(message.get("types", []))
                notification_service.unsubscribe_user_from_types(user_id_int, types_to_unsubscribe)
                
    except WebSocketDisconnect:
        await notification_service.disconnect(user_id_int)
    except Exception as e:
        print(f"WebSocket notification error for user {user_id}: {e}")
        await notification_service.disconnect(user_id_int)

@router.get("/presence/{user_id}")
async def get_user_presence(user_id: str):
    """
    Get presence status for a specific user
    """
    presence_data = await presence_service.get_user_presence(user_id)
    return {"presence": presence_data}

@router.get("/presence")
async def get_all_presence():
    """
    Get presence status for all users
    """
    all_presence = await presence_service.get_all_presence()
    return {"presence": all_presence}

@router.post("/presence/{user_id}/activity")
async def report_user_activity(user_id: str, activity_type: str, details: Optional[dict] = None):
    """
    Report user activity (typing, viewing, etc.)
    """
    await presence_service.handle_activity(user_id, activity_type, details)
    return {"status": "activity_reported"}

@router.post("/notifications/send")
async def send_real_time_notification(
    recipient_id: int,
    notification_type: str,
    message: str,
    sender_id: Optional[int] = None,
    payload: Optional[dict] = None,
    current_user: User = Depends(get_current_user)
):
    """
    Send a real-time notification to a user
    """
    # Verify the current user has permission to send notifications
    if sender_id and sender_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to send notifications on behalf of another user")
    
    notification = await notification_service.create_and_send_notification(
        recipient_id=recipient_id,
        notification_type=notification_type,
        message=message,
        sender_id=sender_id,
        payload=payload
    )
    
    if notification:
        return {"status": "notification_sent", "notification_id": notification.id}
    else:
        raise HTTPException(status_code=500, detail="Failed to send notification")

@router.get("/notifications/subscriptions/{user_id}")
async def get_user_notification_subscriptions(
    user_id: int,
    current_user: User = Depends(get_current_user)
):
    """
    Get user's current notification subscriptions
    """
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view another user's subscriptions")
    
    subscriptions = notification_service.get_user_subscriptions(user_id)
    return {"user_id": user_id, "subscriptions": list(subscriptions)}