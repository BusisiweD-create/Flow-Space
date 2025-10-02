"""
Role-Based Access Control (RBAC) system for the application
Defines permissions and authorization logic for different user roles
"""

from enum import Enum
from typing import List, Set, Optional
from fastapi import HTTPException, status, Depends
from sqlalchemy.orm import Session

from database import get_db
from models import User
from dependencies import get_current_user
from user_roles import UserRole


class Permission(str, Enum):
    """Available permissions in the system"""
    # User management
    CREATE_USER = "create_user"
    READ_USER = "read_user"
    UPDATE_USER = "update_user"
    DELETE_USER = "delete_user"
    
    # Deliverable management
    CREATE_DELIVERABLE = "create_deliverable"
    READ_DELIVERABLE = "read_deliverable"
    UPDATE_DELIVERABLE = "update_deliverable"
    DELETE_DELIVERABLE = "delete_deliverable"
    
    # Sprint management
    CREATE_SPRINT = "create_sprint"
    READ_SPRINT = "read_sprint"
    UPDATE_SPRINT = "update_sprint"
    DELETE_SPRINT = "delete_sprint"
    
    # Signoff management
    CREATE_SIGNOFF = "create_signoff"
    READ_SIGNOFF = "read_signoff"
    UPDATE_SIGNOFF = "update_signoff"
    APPROVE_SIGNOFF = "approve_signoff"
    
    # Audit logs
    READ_AUDIT_LOGS = "read_audit_logs"
    
    # System settings
    MANAGE_SETTINGS = "manage_settings"
    
    # Profile management
    UPDATE_PROFILE = "update_profile"
    READ_PROFILE = "read_profile"


# Role-Permission mappings
ROLE_PERMISSIONS = {
    UserRole.ADMIN: {
        Permission.CREATE_USER,
        Permission.READ_USER,
        Permission.UPDATE_USER,
        Permission.DELETE_USER,
        Permission.CREATE_DELIVERABLE,
        Permission.READ_DELIVERABLE,
        Permission.UPDATE_DELIVERABLE,
        Permission.DELETE_DELIVERABLE,
        Permission.CREATE_SPRINT,
        Permission.READ_SPRINT,
        Permission.UPDATE_SPRINT,
        Permission.DELETE_SPRINT,
        Permission.CREATE_SIGNOFF,
        Permission.READ_SIGNOFF,
        Permission.UPDATE_SIGNOFF,
        Permission.APPROVE_SIGNOFF,
        Permission.READ_AUDIT_LOGS,
        Permission.MANAGE_SETTINGS,
        Permission.UPDATE_PROFILE,
        Permission.READ_PROFILE,
    },
    UserRole.MANAGER: {
        Permission.CREATE_DELIVERABLE,
        Permission.READ_DELIVERABLE,
        Permission.UPDATE_DELIVERABLE,
        Permission.DELETE_DELIVERABLE,
        Permission.CREATE_SPRINT,
        Permission.READ_SPRINT,
        Permission.UPDATE_SPRINT,
        Permission.DELETE_SPRINT,
        Permission.CREATE_SIGNOFF,
        Permission.READ_SIGNOFF,
        Permission.UPDATE_SIGNOFF,
        Permission.APPROVE_SIGNOFF,
        Permission.READ_AUDIT_LOGS,
        Permission.UPDATE_PROFILE,
        Permission.READ_PROFILE,
    },
    UserRole.USER: {
        Permission.READ_DELIVERABLE,
        Permission.UPDATE_DELIVERABLE,
        Permission.READ_SPRINT,
        Permission.CREATE_SIGNOFF,
        Permission.READ_SIGNOFF,
        Permission.UPDATE_SIGNOFF,
        Permission.UPDATE_PROFILE,
        Permission.READ_PROFILE,
    },
    UserRole.CLIENT: {
        Permission.READ_DELIVERABLE,
        Permission.READ_SPRINT,
        Permission.READ_SIGNOFF,
        Permission.READ_PROFILE,
    }
}


def has_permission(user_role: UserRole, permission: Permission) -> bool:
    """Check if a user role has a specific permission"""
    return permission in ROLE_PERMISSIONS.get(user_role, set())


def get_role_permissions(user_role: UserRole) -> Set[Permission]:
    """Get all permissions for a specific user role"""
    return ROLE_PERMISSIONS.get(user_role, set())


def require_permission(permission: Permission):
    """Dependency to require a specific permission for an endpoint"""
    def permission_dependency(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
    ):
        user_role = UserRole(current_user.role)
        if not has_permission(user_role, permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient permissions. Required: {permission}"
            )
        return current_user
    
    return permission_dependency


def require_role(required_role: UserRole):
    """Dependency to require a specific user role for an endpoint"""
    def role_dependency(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
    ):
        user_role = UserRole(current_user.role)
        if user_role != required_role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient role privileges. Required: {required_role}"
            )
        return current_user
    
    return role_dependency


def require_any_role(required_roles: List[UserRole]):
    """Dependency to require any of the specified roles for an endpoint"""
    def any_role_dependency(
        current_user: User = Depends(get_current_user),
        db: Session = Depends(get_db)
    ):
        user_role = UserRole(current_user.role)
        if user_role not in required_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Insufficient role privileges. Required one of: {', '.join(required_roles)}"
            )
        return current_user
    
    return any_role_dependency


def can_access_entity(current_user: User, entity_owner_id: Optional[int] = None) -> bool:
    """
    Check if a user can access a specific entity.
    Admins and managers can access all entities, users can access their own.
    """
    user_role = UserRole(current_user.role)
    
    # Admins and managers can access everything
    if user_role in [UserRole.ADMIN, UserRole.MANAGER]:
        return True
    
    # Users can access their own entities
    if user_role == UserRole.USER and entity_owner_id and current_user.id == entity_owner_id:
        return True
    
    # Clients have very limited access
    return False


def get_accessible_entities_query(db: Session, current_user: User, model_class):
    """
    Get a query that filters entities based on user role and permissions
    """
    user_role = UserRole(current_user.role)
    
    # Admins and managers can see all entities
    if user_role in [UserRole.ADMIN, UserRole.MANAGER]:
        return db.query(model_class)
    
    # Users can only see their own entities (if the model has a user_id field)
    if user_role == UserRole.USER:
        if hasattr(model_class, 'user_id'):
            return db.query(model_class).filter(model_class.user_id == current_user.id)
        elif hasattr(model_class, 'created_by'):
            return db.query(model_class).filter(model_class.created_by == current_user.email)
    
    # Clients have very limited access
    if user_role == UserRole.CLIENT:
        # Clients can only see entities explicitly shared with them
        # This would need to be implemented based on your sharing mechanism
        return db.query(model_class).filter(False)  # Empty result by default
    
    return db.query(model_class).filter(False)  # Default to empty result


# Common permission dependencies for easy use
require_admin = require_role(UserRole.ADMIN)
require_manager = require_role(UserRole.MANAGER)
require_user = require_role(UserRole.USER)
require_client = require_role(UserRole.CLIENT)

require_admin_or_manager = require_any_role([UserRole.ADMIN, UserRole.MANAGER])
require_admin_manager_user = require_any_role([UserRole.ADMIN, UserRole.MANAGER, UserRole.USER])

# Common permission dependencies
require_user_management = require_permission(Permission.CREATE_USER)
require_deliverable_management = require_permission(Permission.CREATE_DELIVERABLE)
require_sprint_management = require_permission(Permission.CREATE_SPRINT)
require_signoff_management = require_permission(Permission.CREATE_SIGNOFF)
require_audit_access = require_permission(Permission.READ_AUDIT_LOGS)
require_settings_management = require_permission(Permission.MANAGE_SETTINGS)