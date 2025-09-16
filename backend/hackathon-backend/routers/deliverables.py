"""
Router for deliverable-related endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from schemas import Deliverable, DeliverableCreate, DeliverableUpdate
from crud import (
    get_deliverable, get_deliverables, get_deliverables_by_sprint,
    create_deliverable, update_deliverable, delete_deliverable
)

router = APIRouter()

@router.get("/", response_model=List[Deliverable])
def read_deliverables(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all deliverables with pagination"""
    deliverables = get_deliverables(db, skip=skip, limit=limit)
    return deliverables

@router.get("/sprint/{sprint_id}", response_model=List[Deliverable])
def read_deliverables_by_sprint(
    sprint_id: int,
    db: Session = Depends(get_db)
):
    """Get all deliverables for a specific sprint"""
    deliverables = get_deliverables_by_sprint(db, sprint_id=sprint_id)
    return deliverables

@router.get("/{deliverable_id}", response_model=Deliverable)
def read_deliverable(
    deliverable_id: int,
    db: Session = Depends(get_db)
):
    """Get a specific deliverable by ID"""
    deliverable = get_deliverable(db, deliverable_id=deliverable_id)
    if deliverable is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Deliverable not found"
        )
    return deliverable

@router.post("/", response_model=Deliverable, status_code=status.HTTP_201_CREATED)
def create_new_deliverable(
    deliverable: DeliverableCreate,
    db: Session = Depends(get_db)
):
    """Create a new deliverable"""
    return create_deliverable(db=db, deliverable=deliverable)

@router.put("/{deliverable_id}", response_model=Deliverable)
def update_existing_deliverable(
    deliverable_id: int,
    deliverable: DeliverableUpdate,
    db: Session = Depends(get_db)
):
    """Update an existing deliverable"""
    updated_deliverable = update_deliverable(
        db=db, deliverable_id=deliverable_id, deliverable=deliverable
    )
    if updated_deliverable is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Deliverable not found"
        )
    return updated_deliverable

@router.delete("/{deliverable_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_existing_deliverable(
    deliverable_id: int,
    db: Session = Depends(get_db)
):
    """Delete a deliverable"""
    success = delete_deliverable(db=db, deliverable_id=deliverable_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Deliverable not found"
        )
