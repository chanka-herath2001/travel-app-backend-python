"""Main FastAPI application."""
import json

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.websocket.handler import WebSocketHandler

# Initialize settings and app
settings = get_settings()
app = FastAPI(
    title="Travel Chat API",
    description="WebSocket-based travel recommendation chat service",
    version="1.0.0"
)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize WebSocket handler
ws_handler = WebSocketHandler()

@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Travel Chat WebSocket API",
        "websocket_endpoint": "/ws/chat",
        "status": "running",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}

@app.websocket("/ws/chat")
async def websocket_chat(websocket: WebSocket):
    """
    WebSocket endpoint for chat communication.
    
    Expected message format:
    {
        "message": "user query",
        "user_lat": 40.7128,  // optional
        "user_lng": -74.0060  // optional
    }
    """
    await websocket.accept()
    print("Client connected")
    
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            # Handle the message
            await ws_handler.handle_message(websocket, message_data)
            
    except WebSocketDisconnect:
        print("Client disconnected")
    except Exception as e:
        print(f"Error: {e}")
        try:
            await websocket.send_json({
                "type": "error",
                "message": f"Connection error: {str(e)}"
            })
        except:
            pass