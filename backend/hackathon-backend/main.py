"""
Main FastAPI application entry point for Hackathon Backend
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
from models import Base
from routers import deliverables, sprints, signoff, audit, settings, profile, websocket, notifications, auth, file_upload, analytics, monitoring
from middleware.logging_middleware import LoggingMiddleware
from middleware.performance_middleware import PerformanceMiddleware

# Create database tables
Base.metadata.create_all(bind=engine)

# Initialize FastAPI app with comprehensive OpenAPI documentation
app = FastAPI(
    title="Hackathon Project Management API",
    description="""
# Hackathon Project Management API

A comprehensive REST API for managing hackathon projects, deliverables, sprints, and team collaboration.

## Features

- **User Authentication & Authorization** - JWT-based authentication with role-based access control
- **Project Management** - Create and manage projects, deliverables, and sprints
- **Team Collaboration** - User roles, permissions, and team management
- **Real-time Notifications** - WebSocket support for real-time updates
- **Audit Logging** - Comprehensive activity tracking and audit trails
- **Settings Management** - User preferences and application settings

## Authentication

This API uses JWT tokens for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## API Endpoints

All endpoints are versioned under `/api/v1/` prefix.

## Error Codes

- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Rate Limiting

API rate limiting is implemented to prevent abuse. Default limits:
- 100 requests per minute per IP
- 1000 requests per hour per user

## Support

For support, please contact the development team or create an issue in the repository.
""",
    version="1.0.0",
    contact={
        "name": "API Support",
        "email": "support@hackathon-api.com",
        "url": "https://github.com/your-org/hackathon-backend"
    },
    license_info={
        "name": "MIT License",
        "url": "https://opensource.org/licenses/MIT"
    },
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/api/v1/openapi.json",
    openapi_tags=[
        {
            "name": "auth",
            "description": "User authentication and authorization endpoints"
        },
        {
            "name": "deliverables", 
            "description": "Manage project deliverables and milestones"
        },
        {
            "name": "sprints",
            "description": "Sprint planning and tracking endpoints"
        },
        {
            "name": "signoff",
            "description": "Deliverable approval and signoff management"
        },
        {
            "name": "audit",
            "description": "Audit logs and activity tracking"
        },
        {
            "name": "settings",
            "description": "User preferences and application settings"
        },
        {
            "name": "profile",
            "description": "User profile management endpoints"
        },
        {
            "name": "websocket",
            "description": "Real-time WebSocket connections"
        },
        {
            "name": "notifications",
            "description": "Push notifications and alerts"
        }
    ]
)

# Add CORS middleware with dynamic origin handling for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:3000", "http://localhost:3000", "http://localhost:65530", "http://localhost:63651", "http://localhost:62240", "http://localhost:60383", "http://localhost:63973"],  # Frontend development URLs including Flutter web dev server ports
    allow_origin_regex=r"http://localhost:\d+",  # Allow any localhost port for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add logging and performance middleware
app.add_middleware(LoggingMiddleware)
app.add_middleware(PerformanceMiddleware)

# Include routers
app.include_router(deliverables.router, prefix="/api/v1/deliverables", tags=["deliverables"])
app.include_router(sprints.router, prefix="/api/v1/sprints", tags=["sprints"])
app.include_router(signoff.router, prefix="/api/v1/signoff", tags=["signoff"])
app.include_router(audit.router, prefix="/api/v1/audit", tags=["audit"])
app.include_router(settings.router, prefix="/api/v1/settings", tags=["settings"])
app.include_router(profile.router, prefix="/api/v1/profile", tags=["profile"])
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(websocket.router, prefix="/api/v1/ws", tags=["websocket"])
app.include_router(notifications.router, prefix="/api/v1/notifications", tags=["notifications"])
app.include_router(file_upload.router, prefix="/api/v1/files", tags=["files"])
app.include_router(analytics.router, prefix="/api/v1/analytics", tags=["analytics"])
app.include_router(monitoring.router, prefix="/api/v1/monitoring", tags=["monitoring"])

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Hackathon Backend API is running"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}

# Startup event to initialize background services
@app.on_event("startup")
async def startup_event():
    """Initialize background services on startup"""
    from services.presence_service import start_presence_service
    from services.notification_service import start_notification_service
    from services.analytics_service import analytics_service
    from services.logging_service import logging_service
    
    # Start presence service background task
    await start_presence_service()
    
    # Start notification service background task
    await start_notification_service()
    
    # Start analytics service background task
    await analytics_service.start()
    
    # Start logging service background task
    await logging_service.start()
    
    print("Background services started successfully")

# Shutdown event to cleanup background services
@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup background services on shutdown"""
    from services.presence_service import stop_presence_service
    from services.notification_service import stop_notification_service
    from services.analytics_service import analytics_service
    from services.logging_service import logging_service
    
    # Stop presence service
    await stop_presence_service()
    
    # Stop notification service
    await stop_notification_service()
    
    # Stop analytics service
    await analytics_service.stop()
    
    # Stop logging service
    await logging_service.stop()
    
    print("Background services stopped successfully")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
