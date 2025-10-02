"""
Authentication router for user registration, login, token refresh, and account management
"""

from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime, timedelta

from database import get_db
from models import User as UserModel, RefreshToken
from schemas import (
    Token, UserLogin, UserRegister, User as UserSchema, UserCreate, 
    RefreshTokenCreate, RefreshToken as RefreshTokenSchema
)
from auth_utils import (
    verify_password, get_password_hash, create_tokens,
    verify_token, generate_verification_token, generate_password_reset_token,
    get_default_user_role
)
from dependencies import get_current_user, get_current_active_user
from user_roles import UserRole

router = APIRouter()


@router.post("/register", response_model=Token)
def register_user(
    user_data: UserRegister,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Register a new user"""
    # Check if user already exists
    existing_user = db.query(UserModel).filter(UserModel.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this email already exists"
        )
    
    # Validate user role if provided
    if user_data.role:
        from auth_utils import validate_user_role
        if not validate_user_role(user_data.role):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid user role. Allowed roles: {[role.value for role in UserRole]}"
            )
    
    # Create new user
    hashed_password = get_password_hash(user_data.password)
    verification_token = generate_verification_token()
    
    user = UserModel(
        email=user_data.email,
        hashed_password=hashed_password,
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        company=user_data.company,
        role=user_data.role if user_data.role else get_default_user_role(),
        verification_token=verification_token,
        is_verified=False
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Create tokens
    tokens = create_tokens(user.id, user.email, user.role)
    
    # Create refresh token in database
    refresh_token_payload = verify_token(tokens["refresh_token"])
    if refresh_token_payload:
        refresh_token = RefreshToken(
            user_id=user.id,
            token=tokens["refresh_token"],
            expires_at=datetime.fromtimestamp(refresh_token_payload["exp"])
        )
        db.add(refresh_token)
        db.commit()
    
    # TODO: Send verification email in background task
    
    return tokens


@router.post("/login", response_model=Token)
def login_user(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """Login user and return JWT tokens"""
    user = db.query(UserModel).filter(UserModel.email == form_data.username).first()
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Account deactivated",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Update last login
    user.last_login = datetime.utcnow()
    db.commit()
    
    # Create tokens
    tokens = create_tokens(user.id, user.email, user.role)
    
    # Create refresh token in database
    refresh_token_payload = verify_token(tokens["refresh_token"])
    if refresh_token_payload:
        refresh_token = RefreshToken(
            user_id=user.id,
            token=tokens["refresh_token"],
            expires_at=datetime.fromtimestamp(refresh_token_payload["exp"])
        )
        db.add(refresh_token)
        db.commit()
    
    return tokens


@router.post("/refresh", response_model=Token)
def refresh_token(
    refresh_token: str,
    db: Session = Depends(get_db)
):
    """Refresh access token using refresh token"""
    # Verify refresh token
    payload = verify_token(refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token"
        )
    
    # Check if refresh token exists in database and is not revoked
    db_refresh_token = db.query(RefreshToken).filter(
        RefreshToken.token == refresh_token,
        RefreshToken.is_revoked == False,
        RefreshToken.expires_at > datetime.utcnow()
    ).first()
    
    if not db_refresh_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )
    
    # Get user
    user = db.query(UserModel).filter(UserModel.id == db_refresh_token.user_id).first()
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive"
        )
    
    # Create new access token
    access_token_expires = timedelta(minutes=30)
    access_token = create_tokens(user.id, user.email, user.role)["access_token"]
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "refresh_token": refresh_token,
        "expires_in": 30 * 60
    }


@router.post("/logout")
def logout_user(
    refresh_token: str,
    db: Session = Depends(get_db)
):
    """Logout user by revoking refresh token"""
    # Find and revoke refresh token
    db_refresh_token = db.query(RefreshToken).filter(
        RefreshToken.token == refresh_token,
        RefreshToken.is_revoked == False
    ).first()
    
    if db_refresh_token:
        db_refresh_token.is_revoked = True
        db.commit()
    
    return {"message": "Successfully logged out"}


@router.get("/me", response_model=UserSchema)
def get_current_user_info(
    current_user: UserModel = Depends(get_current_active_user)
):
    """Get current user information"""
    return current_user


@router.post("/forgot-password")
def forgot_password(
    email: str,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Request password reset"""
    user = db.query(UserModel).filter(UserModel.email == email).first()
    if user:
        reset_token = generate_password_reset_token()
        user.reset_token = reset_token
        db.commit()
        
        # TODO: Send password reset email in background task
        
    return {"message": "If the email exists, a password reset link has been sent"}


@router.post("/reset-password")
def reset_password(
    token: str,
    new_password: str,
    db: Session = Depends(get_db)
):
    """Reset user password using reset token"""
    user = db.query(UserModel).filter(UserModel.reset_token == token).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token"
        )
    
    user.hashed_password = get_password_hash(new_password)
    user.reset_token = None
    db.commit()
    
    return {"message": "Password reset successfully"}


@router.post("/verify-email")
def verify_email(
    token: str,
    db: Session = Depends(get_db)
):
    """Verify user email address"""
    user = db.query(UserModel).filter(UserModel.verification_token == token).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid verification token"
        )
    
    user.is_verified = True
    user.verification_token = None
    db.commit()
    
    return {"message": "Email verified successfully"}