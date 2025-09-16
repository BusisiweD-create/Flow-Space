"""
Router for sprint-related endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from schemas import Sprint, SprintCreate, SprintUpdate
from crud import get_sprint, get_sprints, create_sprint, update_sprint, delete_sprint

router = APIRouter()

@router.get("/", response_model=List[Sprint])
def read_sprints(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all sprints with pagination"""
    sprints = get_sprints(db, skip=skip, limit=limit)
    return sprints

@router.get("/{sprint_id}", response_model=Sprint)
def read_sprint(
    sprint_id: int,
    db: Session = Depends(get_db)
):
    """Get a specific sprint by ID"""
    sprint = get_sprint(db, sprint_id=sprint_id)
    if sprint is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sprint not found"
        )
    return sprint

@router.post("/", response_model=Sprint, status_code=status.HTTP_201_CREATED)
def create_new_sprint(
    sprint: SprintCreate,
    db: Session = Depends(get_db)
):
    """Create a new sprint"""
    return create_sprint(db=db, sprint=sprint)

@router.put("/{sprint_id}", response_model=Sprint)
def update_existing_sprint(
    sprint_id: int,
    sprint: SprintUpdate,
    db: Session = Depends(get_db)
):
    """Update an existing sprint"""
    updated_sprint = update_sprint(
        db=db, sprint_id=sprint_id, sprint=sprint
    )
    if updated_sprint is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sprint not found"
        )
    return updated_sprint

@router.delete("/{sprint_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_existing_sprint(
    sprint_id: int,
    db: Session = Depends(get_db)
):
    """Delete a sprint"""
    success = delete_sprint(db=db, sprint_id=sprint_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sprint not found"
        )
