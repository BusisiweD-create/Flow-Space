"""
User role definitions to avoid circular imports
"""

from enum import Enum


class UserRole(str, Enum):
    """Available user roles in the system"""
    ADMIN = "admin"
    MANAGER = "manager" 
    USER = "user"
    CLIENT = "client"