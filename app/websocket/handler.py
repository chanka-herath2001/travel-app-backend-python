"""WebSocket message handler."""
from fastapi import WebSocket

from app.models.schemas import ChatMessage
from app.services.maps_service import GoogleMapsService
from app.services.openai_service import OpenAIService


class WebSocketHandler:
    """Handles WebSocket messages and orchestrates services."""
    
    def __init__(self):
        """Initialize services."""
        self.openai_service = OpenAIService()
        self.maps_service = GoogleMapsService()
    
    async def handle_message(self, websocket: WebSocket, data: dict):
        """
        Handle incoming WebSocket messages.
        
        Args:
            websocket: The WebSocket connection
            data: Message data from client
        """
        try:
            # Parse the incoming message
            chat_msg = ChatMessage(**data)
            
            # Send acknowledgment
            await websocket.send_json({
                "type": "status",
                "message": "Processing your request..."
            })
            
            # Extract intent using OpenAI
            has_location = chat_msg.user_lat is not None and chat_msg.user_lng is not None
            intent = self.openai_service.extract_intent(
                chat_msg.message, 
                has_location=has_location
            )
            
            # Send intent extraction status
            await websocket.send_json({
                "type": "status",
                "message": "Searching for locations..."
            })
            
            # Search for locations using Google Maps
            locations = self.maps_service.search_places(
                intent,
                user_lat=chat_msg.user_lat,
                user_lng=chat_msg.user_lng
            )
            
            if not locations:
                await websocket.send_json({
                    "type": "error",
                    "message": "Sorry, I couldn't find any locations matching your request. Could you try rephrasing?"
                })
                return
            
            # Stream the AI response
            await websocket.send_json({
                "type": "stream_start",
                "message": "Generating response..."
            })
            
            # Stream each chunk of the response
            async for chunk in self.openai_service.generate_streaming_response(
                chat_msg.message, 
                locations
            ):
                await websocket.send_json({
                    "type": "stream_chunk",
                    "content": chunk
                })
            
            # Send stream end signal
            await websocket.send_json({
                "type": "stream_end"
            })
            
            # Send location cards
            location_cards = []
            for loc in locations:
                card = loc.model_dump()
                if card['photo_reference']:
                    card['photo_url'] = self.maps_service.get_photo_url(card['photo_reference'])
                location_cards.append(card)
            
            await websocket.send_json({
                "type": "locations",
                "locations": location_cards
            })
            
            # Send completion signal
            await websocket.send_json({
                "type": "complete",
                "message": "Response complete"
            })
            
        except Exception as e:
            await websocket.send_json({
                "type": "error",
                "message": f"An error occurred: {str(e)}"
            })