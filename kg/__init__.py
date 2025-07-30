# Knowledge Graph Plugin - Main Entry Point
# This import is currently required for the plugin to load properly
# Will be improved in future versions

from .graph_commands import *
from .file_commands import *
from .mod import *
from .consolidate_entities import *
from .router import *

# Import pipes to register them
from . import filter

# Create the FastAPI app for uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

app = FastAPI()
app.include_router(router)

# Simple middleware to set dummy user for all requests
class UserMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        print(f"🔧 [UserMiddleware] Setting user for request to: {request.url}")
        print(f"🔧 [UserMiddleware] Request method: {request.method}")
        # Create dummy user inline
        class DummyUser:
            def __init__(self):
                self.roles = ["user", "admin"]
                self.id = "dummy_user"
                self.name = "Dummy User"
        
        request.state.user = DummyUser()
        print(f"🔧 [UserMiddleware] User set: {request.state.user}")
        response = await call_next(request)
        print(f"🔧 [UserMiddleware] Response status: {response.status_code}")
        return response

# Add user middleware first (before CORS)
app.add_middleware(UserMiddleware)

# Add CORS middleware to allow Swift app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Knowledge Graph API is running"}
