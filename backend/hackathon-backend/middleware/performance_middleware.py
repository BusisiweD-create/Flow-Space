"""
Performance monitoring middleware for tracking response times and errors
"""

import time
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

from services.analytics_service import analytics_service


class PerformanceMiddleware(BaseHTTPMiddleware):
    """Middleware for performance monitoring and metrics collection"""
    
    def __init__(self, app: ASGIApp):
        super().__init__(app)
    
    async def dispatch(self, request: Request, call_next) -> Response:
        # Skip metrics for monitoring endpoints
        if request.url.path.startswith('/monitoring') or request.url.path == '/health':
            return await call_next(request)
        
        start_time = time.time()
        
        try:
            response = await call_next(request)
            response_time = time.time() - start_time
            
            # Record successful request
            analytics_service.record_success()
            analytics_service.record_response_time(response_time)
            
            # Add performance headers
            response.headers["X-Response-Time"] = f"{response_time:.3f}s"
            response.headers["X-Performance-Monitored"] = "true"
            
            return response
            
        except Exception as e:
            response_time = time.time() - start_time
            
            # Record error
            analytics_service.record_error()
            analytics_service.record_response_time(response_time)
            
            # Re-raise the exception
            raise e