"""
Router for signoff-related endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
from schemas import Signoff, SignoffCreate, SignoffUpdate
from crud import (
    get_signoff, get_signoffs_by_sprint,
    create_signoff, update_signoff, delete_signoff
)
from services.report_service import generate_signoff_report

router = APIRouter()

@router.get("/{entity_type}/{entity_id}/report")
def generate_signoff_report_endpoint(
    entity_type: str,
    entity_id: int,
    format: Optional[str] = "html",
    include_audit_logs: Optional[bool] = True,
    db: Session = Depends(get_db)
):
    """
    Generate a comprehensive sign-off report for a specific entity
    
    Args:
        entity_type: Type of entity (sprint or deliverable)
        entity_id: ID of the entity
        format: Report format (html, pdf, json, text)
        include_audit_logs: Whether to include audit logs in the report
    """
    # Validate entity type
    if entity_type not in ["sprint", "deliverable"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Entity type must be 'sprint' or 'deliverable'"
        )
    
    # Validate format
    if format not in ["html", "pdf", "json", "text"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Format must be 'html', 'pdf', 'json', or 'text'"
        )
    
    try:
        # Generate the report
        report_data = generate_signoff_report(
            db=db,
            entity_type=entity_type,
            entity_id=entity_id,
            format=format,
            include_audit_logs=include_audit_logs
        )
        
        # Return appropriate response based on format
        if format == "json":
            return report_data
        else:
            return {
                "content": report_data["content"],
                "metadata": report_data["metadata"],
                "format": format
            }
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error generating report: {str(e)}"
        )

@router.get("/sprint/{sprint_id}", response_model=List[Signoff])
def read_signoffs_by_sprint(
    sprint_id: int,
    db: Session = Depends(get_db)
):
    """Get all signoffs for a specific sprint"""
    signoffs = get_signoffs_by_sprint(db, sprint_id=sprint_id)
    return signoffs

@router.get("/{signoff_id}", response_model=Signoff)
def read_signoff(
    signoff_id: int,
    db: Session = Depends(get_db)
):
    """Get a specific signoff by ID"""
    signoff = get_signoff(db, signoff_id=signoff_id)
    if signoff is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Signoff not found"
        )
    return signoff

@router.post("/", response_model=Signoff, status_code=status.HTTP_201_CREATED)
def create_new_signoff(
    signoff: SignoffCreate,
    db: Session = Depends(get_db)
):
    """Create a new signoff"""
    return create_signoff(db=db, signoff=signoff)

@router.put("/{signoff_id}", response_model=Signoff)
def update_existing_signoff(
    signoff_id: int,
    signoff: SignoffUpdate,
    db: Session = Depends(get_db)
):
    """Update an existing signoff"""
    updated_signoff = update_signoff(
        db=db, signoff_id=signoff_id, signoff=signoff
    )
    if updated_signoff is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Signoff not found"
        )
    return updated_signoff

@router.delete("/{signoff_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_existing_signoff(
    signoff_id: int,
    db: Session = Depends(get_db)
):
    """Delete a signoff"""
    success = delete_signoff(db=db, signoff_id=signoff_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Signoff not found"
        )

@router.post("/{signoff_id}/approve", response_model=Signoff)
def approve_signoff(
    signoff_id: int,
    db: Session = Depends(get_db)
):
    """Approve a signoff"""
    signoff = get_signoff(db, signoff_id=signoff_id)
    if signoff is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Signoff not found"
        )
    
    # Update the signoff to approved
    signoff_update = SignoffUpdate(decision="approved")
    updated_signoff = update_signoff(
        db=db, signoff_id=signoff_id, signoff=signoff_update
    )
    return updated_signoff
