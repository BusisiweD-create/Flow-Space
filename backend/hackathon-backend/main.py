"""
Main FastAPI application entry point for Hackathon Backend
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine
from models import Base
from routers import deliverables, sprints, signoff, audit, settings, profile

# Create database tables
Base.metadata.create_all(bind=engine)

# Initialize FastAPI app
app = FastAPI(
    title="Hackathon Backend API",
    description="Backend API for hackathon project management",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(deliverables.router, prefix="/api/v1/deliverables", tags=["deliverables"])
app.include_router(sprints.router, prefix="/api/v1/sprints", tags=["sprints"])
app.include_router(signoff.router, prefix="/api/v1/signoff", tags=["signoff"])
app.include_router(audit.router, prefix="/api/v1/audit", tags=["audit"])
app.include_router(settings.router, prefix="/api/v1/settings", tags=["settings"])
app.include_router(profile.router, prefix="/api/v1/profile", tags=["profile"])

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Hackathon Backend API is running"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8002)
