"""
Middleware for request logging, monitoring, and performance tracking
"""

import time
import uuid
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

from services.logging_service import logging_service, request_id_var, user_id_var, LogLevel, LogCategory

class LoggingMiddleware(BaseHTTPMiddleware):
    def __init__(self, app: ASGIApp):
        super().__init__(app)
    
    async def dispatch(self, request: Request, call_next):
        # Generate request ID
        request_id = str(uuid.uuid4())
        request_id_var.set(request_id)
        
        # Extract user ID from request if available
        user_id = None
        if hasattr(request.state, 'user') and request.state.user:
            user_id = str(request.state.user.get('user_id', ''))
        user_id_var.set(user_id or '')
        
        # Start request tracking
        logging_service.start_request(request_id, user_id)
        
        # Log request start
        logging_service.log(
            LogLevel.INFO,
            LogCategory.API,
            f"Request started: {request.method} {request.url.path}",
            metadata={
                'method': request.method,
                'path': request.url.path,
                'query_params': dict(request.query_params),
                'client_host': request.client.host if request.client else None,
                'user_agent': request.headers.get('user-agent')
            }
        )
        
        # Process request
        start_time = time.time()
        response = None
        try:
            response = await call_next(request)
            return response
        except Exception as e:
            # Log unhandled exceptions
            import traceback
            logging_service.log(
                LogLevel.ERROR,
                LogCategory.API,
                f"Unhandled exception in request: {str(e)}",
                error=str(e),
                stack_trace=traceback.format_exc()
            )
            raise
        finally:
            # Calculate request duration
            duration = (time.time() - start_time) * 1000
            
            # Get response status
            status_code = 500
            if response:
                status_code = response.status_code
            elif hasattr(response, 'status_code'):
                status_code = response.status_code
            
            # Log request completion
            log_level = LogLevel.INFO if status_code < 400 else LogLevel.ERROR
            
            logging_service.log(
                log_level,
                LogCategory.API,
                f"Request completed: {status_code}",
                duration_ms=duration,
                metadata={
                    'status_code': status_code,
                    'duration_ms': duration
                }
            )
            
            # End request tracking
            logging_service.end_request(request_id, status_code)

class PerformanceMiddleware(BaseHTTPMiddleware):
    def __init__(self, app: ASGIApp):
        super().__init__(app)
    
    async def dispatch(self, request: Request, call_next):
        # Add performance headers
        start_time = time.time()
        response = await call_next(request)
        duration = (time.time() - start_time) * 1000
        
        # Add performance headers
        response.headers["X-Response-Time"] = f"{duration:.2f}ms"
        response.headers["X-Request-ID"] = request_id_var.get()
        
        return response