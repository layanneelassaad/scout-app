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

app = FastAPI()
app.include_router(router)

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
