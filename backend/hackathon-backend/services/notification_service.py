"""
Real-time notification service with WebSocket support
Handles delivery of notifications to connected clients in real-time
"""

import asyncio
from datetime import datetime
from typing import Dict, List, Optional, Set
import json
from sqlalchemy.orm import Session
from fastapi import WebSocket

from database import get_db
from models import Notification as NotificationModel, User
from crud import create_notification, mark_notification_as_read

class NotificationService:
    """Service for managing real-time notifications and WebSocket connections"""
    
    def __init__(self):
        self.active_connections: Dict[int, WebSocket] = {}  # user_id -> WebSocket
        self.user_subscriptions: Dict[int, Set[str]] = {}  # user_id -> set of notification types
        self.notification_handlers = []
    
    async def connect(self, websocket: WebSocket, user_id: int):
        """Handle new WebSocket connection for notifications"""
        await websocket.accept()
        self.active_connections[user_id] = websocket
        
        # Subscribe user to default notification types
        self.user_subscriptions[user_id] = {
            "message", "task_assigned", "sprint_update", "system", "mention"
        }
        
        # Send any pending notifications
        await self.send_pending_notifications(user_id)
    
    async def disconnect(self, user_id: int):
        """Handle WebSocket disconnection"""
        if user_id in self.active_connections:
            del self.active_connections[user_id]
        if user_id in self.user_subscriptions:
            del self.user_subscriptions[user_id]
    
    async def send_pending_notifications(self, user_id: int):
        """Send any unread notifications to the user upon connection"""
        try:
            db = next(get_db())
            unread_notifications = db.query(NotificationModel).filter(
                NotificationModel.recipient_id == user_id,
                NotificationModel.is_read == False
            ).all()
            
            for notification in unread_notifications:
                await self.send_notification_to_user(user_id, {
                    "type": "notification",
                    "data": {
                        "id": notification.id,
                        "type": notification.type,
                        "message": notification.message,
                        "payload": notification.payload,
                        "created_at": notification.created_at.isoformat(),
                        "is_read": notification.is_read,
                        "sender_id": notification.sender_id
                    }
                })
        except Exception as e:
            print(f"Error sending pending notifications to user {user_id}: {e}")
    
    async def send_notification_to_user(self, user_id: int, notification_data: dict):
        """Send a notification to a specific user if they're connected"""
        if user_id in self.active_connections:
            try:
                websocket = self.active_connections[user_id]
                await websocket.send_json(notification_data)
            except Exception as e:
                print(f"Error sending notification to user {user_id}: {e}")
                await self.disconnect(user_id)
    
    async def broadcast_notification(self, notification_data: dict, user_ids: Optional[List[int]] = None):
        """Broadcast notification to multiple users or all subscribed users"""
        target_users = user_ids if user_ids else list(self.active_connections.keys())
        
        disconnected_users = []
        
        for user_id in target_users:
            if user_id in self.active_connections:
                try:
                    websocket = self.active_connections[user_id]
                    await websocket.send_json(notification_data)
                except Exception as e:
                    print(f"Error broadcasting to user {user_id}: {e}")
                    disconnected_users.append(user_id)
        
        # Clean up disconnected users
        for user_id in disconnected_users:
            await self.disconnect(user_id)
    
    async def create_and_send_notification(
        self,
        recipient_id: int,
        notification_type: str,
        message: str,
        sender_id: Optional[int] = None,
        payload: Optional[dict] = None
    ):
        """Create a notification and send it to the recipient in real-time"""
        try:
            db = next(get_db())
            
            # Create notification in database
            notification_data = {
                "recipient_id": recipient_id,
                "type": notification_type,
                "message": message,
                "sender_id": sender_id,
                "payload": payload
            }
            
            notification = create_notification(db, notification_data)
            
            # Send real-time notification if user is connected
            notification_message = {
                "type": "notification",
                "data": {
                    "id": notification.id,
                    "type": notification.type,
                    "message": notification.message,
                    "payload": notification.payload,
                    "created_at": notification.created_at.isoformat(),
                    "is_read": notification.is_read,
                    "sender_id": notification.sender_id
                }
            }
            
            await self.send_notification_to_user(recipient_id, notification_message)
            
            return notification
            
        except Exception as e:
            print(f"Error creating and sending notification: {e}")
            return None
    
    async def mark_as_read_and_notify(self, notification_id: int, user_id: int):
        """Mark notification as read and notify client"""
        try:
            db = next(get_db())
            notification = mark_notification_as_read(db, notification_id)
            
            if notification:
                # Send update to client
                update_message = {
                    "type": "notification_read",
                    "data": {
                        "notification_id": notification_id,
                        "read_at": datetime.utcnow().isoformat()
                    }
                }
                
                await self.send_notification_to_user(user_id, update_message)
                
            return notification
            
        except Exception as e:
            print(f"Error marking notification as read: {e}")
            return None
    
    def subscribe_user_to_types(self, user_id: int, notification_types: Set[str]):
        """Subscribe user to specific notification types"""
        if user_id not in self.user_subscriptions:
            self.user_subscriptions[user_id] = set()
        self.user_subscriptions[user_id].update(notification_types)
    
    def unsubscribe_user_from_types(self, user_id: int, notification_types: Set[str]):
        """Unsubscribe user from specific notification types"""
        if user_id in self.user_subscriptions:
            self.user_subscriptions[user_id].difference_update(notification_types)
    
    def get_user_subscriptions(self, user_id: int) -> Set[str]:
        """Get user's current notification subscriptions"""
        return self.user_subscriptions.get(user_id, set())
    
    async def cleanup_inactive_connections(self):
        """Clean up inactive WebSocket connections"""
        current_time = datetime.utcnow()
        users_to_remove = []
        
        # In a real implementation, you might check connection activity
        # For now, we'll just remove connections that might have issues
        for user_id, websocket in self.active_connections.items():
            try:
                # Simple ping to check connection
                await websocket.send_json({"type": "ping", "timestamp": current_time.isoformat()})
            except:
                users_to_remove.append(user_id)
        
        for user_id in users_to_remove:
            await self.disconnect(user_id)

# Global instance
notification_service = NotificationService()

# Background task for cleaning up inactive connections
async def notification_cleanup_task():
    """Background task to clean up inactive WebSocket connections"""
    while True:
        try:
            await notification_service.cleanup_inactive_connections()
            await asyncio.sleep(60)  # Run every minute
        except Exception as e:
            print(f"Error in notification cleanup task: {e}")
            await asyncio.sleep(30)

# Add start and stop methods to NotificationService for consistency with other services
async def start_notification_service():
    """Start notification service background tasks"""
    # Start the notification cleanup task
    asyncio.create_task(notification_cleanup_task())
    print("Notification service background tasks started")

async def stop_notification_service():
    """Stop notification service (placeholder for consistency)"""
    print("Notification service stopped")