from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime

from crud import (
    create_notification,
    get_notification,
    get_notifications_for_user,
    mark_notification_as_read,
    delete_notification,
    get_user_profile
)
from models import User
import schemas
from dependencies import get_db, get_current_user

router = APIRouter(
    prefix="/notifications",
    tags=["Notifications"],
    responses={404: {"description": "Not found"}},
)

@router.post("/", response_model=schemas.Notification)
def create_notification(
    notification: schemas.NotificationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Ensure the recipient exists
    db_recipient = get_user_profile(db, user_id=notification.recipient_id)
    if not db_recipient:
        raise HTTPException(status_code=404, detail="Recipient not found")

    # Set sender_id if not provided (e.g., system notification) or if it's the current user
    if notification.sender_id is None:
        notification.sender_id = current_user.id
    elif notification.sender_id != current_user.id:
        # Optionally, add logic to allow other users to send notifications if needed
        # For now, restrict sender to current user or system
        raise HTTPException(status_code=403, detail="Not authorized to send notifications on behalf of another user")

    return create_notification(db=db, notification=notification)

@router.get("/me", response_model=List[schemas.Notification])
def read_my_notifications(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    notifications = get_notifications_for_user(db, user_id=current_user.id, skip=skip, limit=limit)
    return notifications

@router.get("/{notification_id}", response_model=schemas.Notification)
def read_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_notification = get_notification(db, notification_id=notification_id)
    if db_notification is None:
        raise HTTPException(status_code=404, detail="Notification not found")
    if db_notification.recipient_id != current_user.id and db_notification.sender_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this notification")
    return db_notification

@router.put("/{notification_id}/read", response_model=schemas.Notification)
def mark_notification_as_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_notification = get_notification(db, notification_id=notification_id)
    if db_notification is None:
        raise HTTPException(status_code=404, detail="Notification not found")
    if db_notification.recipient_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to mark this notification as read")
    
    return mark_notification_as_read(db=db, notification_id=notification_id)

@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_notification(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_notification = get_notification(db, notification_id=notification_id)
    if db_notification is None:
        raise HTTPException(status_code=404, detail="Notification not found")
    if db_notification.recipient_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this notification")
    
    delete_notification(db=db, notification_id=notification_id)
    return {"ok": True}