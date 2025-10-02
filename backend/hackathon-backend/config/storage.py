"""
Storage configuration for S3/MinIO file upload service
"""

from pydantic import Field
from pydantic_settings import BaseSettings
from typing import Optional


class StorageSettings(BaseSettings):
    """Storage configuration settings"""
    
    # Storage provider (s3, minio, local)
    STORAGE_PROVIDER: str = Field(default="local", description="Storage provider: s3, minio, or local")
    
    # S3/MinIO configuration
    AWS_ACCESS_KEY_ID: Optional[str] = Field(default=None, description="AWS access key ID")
    AWS_SECRET_ACCESS_KEY: Optional[str] = Field(default=None, description="AWS secret access key")
    AWS_REGION: Optional[str] = Field(default="us-east-1", description="AWS region")
    AWS_S3_BUCKET: Optional[str] = Field(default="hackathon-files", description="S3 bucket name")
    
    # MinIO specific configuration
    MINIO_ENDPOINT: Optional[str] = Field(default="localhost:9000", description="MinIO server endpoint")
    MINIO_ACCESS_KEY: Optional[str] = Field(default=None, description="MinIO access key")
    MINIO_SECRET_KEY: Optional[str] = Field(default=None, description="MinIO secret key")
    MINIO_SECURE: bool = Field(default=False, description="Use HTTPS for MinIO")
    
    # Local storage configuration
    LOCAL_STORAGE_PATH: str = Field(default="uploads", description="Local storage directory path")
    
    # File upload settings
    MAX_FILE_SIZE: int = Field(default=10 * 1024 * 1024, description="Maximum file size in bytes (10MB)")
    ALLOWED_FILE_TYPES: list = Field(
        default=["image/jpeg", "image/png", "image/gif", "image/webp", "application/pdf"],
        description="Allowed MIME types for file uploads"
    )
    
    class Config:
        env_file = ".env"
        env_prefix = "STORAGE_"


def get_storage_settings() -> StorageSettings:
    """Get storage settings instance"""
    return StorageSettings()