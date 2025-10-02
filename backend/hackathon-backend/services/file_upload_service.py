"""
File upload service for handling file storage operations
Supports local file system storage
"""

import os
import uuid
from typing import Optional
from fastapi import UploadFile, HTTPException
from datetime import datetime, timedelta


class FileUploadService:
    """Service for handling file uploads and storage operations"""
    
    def __init__(self):
        self.storage_base_path = os.getenv("FILE_STORAGE_PATH", "uploads")
        self.base_url = os.getenv("FILE_BASE_URL", "/uploads")
        
        # Create storage directory if it doesn't exist
        os.makedirs(self.storage_base_path, exist_ok=True)
    
    async def upload_file(self, file: UploadFile, prefix: str = "") -> dict:
        """
        Upload a file to local storage
        
        Args:
            file: The file to upload
            prefix: Optional prefix for organizing files
            
        Returns:
            Dictionary with file upload information
        """
        try:
            # Generate unique filename
            file_extension = os.path.splitext(file.filename)[1] if file.filename else ".bin"
            unique_filename = f"{uuid.uuid4().hex}{file_extension}"
            
            # Create full path
            if prefix:
                full_prefix = os.path.join(self.storage_base_path, prefix)
                os.makedirs(full_prefix, exist_ok=True)
                storage_path = os.path.join(full_prefix, unique_filename)
                url_path = f"{self.base_url}/{prefix}/{unique_filename}"
            else:
                storage_path = os.path.join(self.storage_base_path, unique_filename)
                url_path = f"{self.base_url}/{unique_filename}"
            
            # Read file content
            content = await file.read()
            file_size = len(content)
            
            # Write file to storage
            with open(storage_path, "wb") as f:
                f.write(content)
            
            return {
                "filename": unique_filename,
                "original_name": file.filename,
                "url": url_path,
                "size": file_size,
                "storage_provider": "local"
            }
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"File upload failed: {str(e)}")
    
    def get_presigned_url(self, filename: str, expires_in: int = 3600) -> Optional[str]:
        """
        Generate a presigned URL for accessing a file (not implemented for local storage)
        
        Args:
            filename: The filename to generate URL for
            expires_in: URL expiration time in seconds
            
        Returns:
            Presigned URL or None if not supported
        """
        # For local storage, we just return the direct URL
        # In production, this would generate a signed URL for cloud storage
        return f"{self.base_url}/{filename}"
    
    async def delete_file(self, filename: str) -> bool:
        """
        Delete a file from storage
        
        Args:
            filename: The filename to delete
            
        Returns:
            True if deletion was successful, False otherwise
        """
        try:
            file_path = os.path.join(self.storage_base_path, filename)
            if os.path.exists(file_path):
                os.remove(file_path)
                return True
            return False
        except:
            return False


# Create global instance
file_upload_service = FileUploadService()