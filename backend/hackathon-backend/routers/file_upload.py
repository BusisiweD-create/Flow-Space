"""
File upload router for handling general file uploads
"""

from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from typing import List
import os

from services.file_upload_service import file_upload_service
from schemas import FileUploadResponse, PresignedUrlResponse

router = APIRouter()


@router.post("/upload", response_model=FileUploadResponse)
async def upload_file(
    file: UploadFile = File(...),
    prefix: str = ""
):
    """
    Upload a file to configured storage (S3/MinIO/Local)
    
    - **file**: The file to upload
    - **prefix**: Optional prefix for organizing files (e.g., "documents", "images")
    """
    try:
        upload_result = await file_upload_service.upload_file(file, prefix)
        return upload_result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"File upload failed: {str(e)}")


@router.post("/upload-multiple", response_model=List[FileUploadResponse])
async def upload_multiple_files(
    files: List[UploadFile] = File(...),
    prefix: str = ""
):
    """
    Upload multiple files to configured storage
    
    - **files**: List of files to upload
    - **prefix**: Optional prefix for organizing files
    """
    results = []
    
    for file in files:
        try:
            upload_result = await file_upload_service.upload_file(file, prefix)
            results.append(upload_result)
        except HTTPException as e:
            # Skip failed files but continue with others
            results.append({
                "filename": file.filename,
                "error": e.detail,
                "success": False
            })
        except Exception as e:
            results.append({
                "filename": file.filename,
                "error": str(e),
                "success": False
            })
    
    return results


@router.get("/presigned-url/{filename}", response_model=PresignedUrlResponse)
async def get_presigned_url(
    filename: str,
    expires_in: int = 3600
):
    """
    Generate a presigned URL for accessing a file
    
    - **filename**: The filename to generate URL for
    - **expires_in**: URL expiration time in seconds (default: 1 hour)
    """
    presigned_url = file_upload_service.get_presigned_url(filename, expires_in)
    
    if not presigned_url:
        raise HTTPException(status_code=404, detail="File not found or presigned URL generation failed")
    
    from datetime import datetime, timedelta
    expires_at = datetime.now() + timedelta(seconds=expires_in)
    
    return {
        "filename": filename,
        "presigned_url": presigned_url,
        "expires_at": expires_at
    }


@router.delete("/{filename}")
async def delete_file(filename: str):
    """
    Delete a file from storage
    
    - **filename**: The filename to delete
    """
    success = await file_upload_service.delete_file(filename)
    
    if not success:
        raise HTTPException(status_code=404, detail="File not found or deletion failed")
    
    return {"message": "File deleted successfully", "filename": filename}