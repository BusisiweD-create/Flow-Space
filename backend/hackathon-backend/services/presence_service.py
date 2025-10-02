"""
Real-time user presence tracking service
Tracks user online/offline status and last activity
"""

import asyncio
from datetime import datetime, timedelta
from typing import Dict, Set, Optional
import json
from sqlalchemy.orm import Session
from fastapi import WebSocket

from database import get_db
from models import UserProfile
from crud import update_user_profile

class PresenceService:
    """Service for managing user presence and activity tracking"""
    
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        self.user_presence: Dict[str, Dict] = {}  # user_id -> presence data
        self.presence_update_handlers = []
    
    async def connect(self, websocket: WebSocket, user_id: str):
        """Handle new WebSocket connection"""
        await websocket.accept()
        self.active_connections[user_id] = websocket
        
        # Update user presence
        await self.update_presence(user_id, "online")
        
        # Broadcast presence update
        await self.broadcast_presence_update()
    
    async def disconnect(self, user_id: str):
        """Handle WebSocket disconnection"""
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            await self.update_presence(user_id, "offline")
            await self.broadcast_presence_update()
    
    async def update_presence(self, user_id: str, status: str):
        """Update user presence status"""
        current_time = datetime.utcnow()
        
        self.user_presence[user_id] = {
            "status": status,
            "last_seen": current_time.isoformat(),
            "user_id": user_id
        }
        
        # Update last active timestamp in database
        try:
            db = next(get_db())
            profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
            if profile:
                profile.last_active_at = current_time
                db.commit()
        except Exception as e:
            print(f"Error updating last active time: {e}")
    
    async def broadcast_presence_update(self):
        """Broadcast presence updates to all connected clients"""
        presence_data = {
            "type": "presence_update",
            "data": list(self.user_presence.values())
        }
        
        disconnected_users = []
        
        for user_id, websocket in self.active_connections.items():
            try:
                await websocket.send_json(presence_data)
            except Exception as e:
                print(f"Error broadcasting to user {user_id}: {e}")
                disconnected_users.append(user_id)
        
        # Clean up disconnected users
        for user_id in disconnected_users:
            await self.disconnect(user_id)
    
    async def handle_activity(self, user_id: str, activity_type: str, details: Optional[Dict] = None):
        """Handle user activity (typing, viewing, etc.)"""
        activity_data = {
            "type": "user_activity",
            "data": {
                "user_id": user_id,
                "activity_type": activity_type,
                "timestamp": datetime.utcnow().isoformat(),
                "details": details or {}
            }
        }
        
        # Broadcast activity to relevant users
        for conn_user_id, websocket in self.active_connections.items():
            if conn_user_id != user_id:  # Don't send to self
                try:
                    await websocket.send_json(activity_data)
                except Exception as e:
                    print(f"Error broadcasting activity to user {conn_user_id}: {e}")
    
    async def get_user_presence(self, user_id: str) -> Optional[Dict]:
        """Get presence data for a specific user"""
        return self.user_presence.get(user_id)
    
    async def get_all_presence(self) -> Dict[str, Dict]:
        """Get presence data for all users"""
        return self.user_presence
    
    def register_presence_handler(self, handler):
        """Register callback for presence updates"""
        self.presence_update_handlers.append(handler)
    
    async def cleanup_inactive_users(self, inactive_minutes: int = 30):
        """Clean up users who haven't been active"""
        current_time = datetime.utcnow()
        cutoff_time = current_time - timedelta(minutes=inactive_minutes)
        
        users_to_remove = []
        
        for user_id, presence_data in self.user_presence.items():
            last_seen = datetime.fromisoformat(presence_data["last_seen"])
            if last_seen < cutoff_time and presence_data["status"] == "online":
                users_to_remove.append(user_id)
        
        for user_id in users_to_remove:
            await self.update_presence(user_id, "offline")
        
        if users_to_remove:
            await self.broadcast_presence_update()

# Global instance
presence_service = PresenceService()

# Background task for cleaning up inactive users
async def presence_cleanup_task():
    """Background task to clean up inactive users"""
    while True:
        try:
            await presence_service.cleanup_inactive_users()
            await asyncio.sleep(300)  # Run every 5 minutes
        except Exception as e:
            print(f"Error in presence cleanup task: {e}")
            await asyncio.sleep(60)

# Add start and stop methods to PresenceService for consistency with other services
async def start_presence_service():
    """Start presence service background tasks"""
    # Start the presence cleanup task
    asyncio.create_task(presence_cleanup_task())
    print("Presence service background tasks started")

async def stop_presence_service():
    """Stop presence service (placeholder for consistency)"""
    print("Presence service stopped")