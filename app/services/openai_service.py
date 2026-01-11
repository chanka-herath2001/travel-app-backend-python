"""OpenAI service for intent extraction and response generation."""
import json
from typing import List

from openai import OpenAI

from app.config import get_settings
from app.models.schemas import ExtractedIntent, LocationCard

settings = get_settings()

class OpenAIService:
    """Service for OpenAI API interactions."""
    
    def __init__(self):
        """Initialize OpenAI client."""
        self.client = OpenAI(api_key=settings.openai_api_key)
    
    def extract_intent(self, user_message: str, has_location: bool = False) -> ExtractedIntent:
        """
        Extract travel intent from user message using OpenAI.
        
        Args:
            user_message: The user's input message
            has_location: Whether user has provided geolocation
            
        Returns:
            ExtractedIntent object with parsed information
        """
        prompt = f"""
Analyze this travel query and extract key information in JSON format:
"{user_message}"

Return a JSON object with:
- destination: the location they want to visit (null if not specified or if nearby request)
- activity_type: type of activity (e.g., "restaurant", "tourist_attraction", "hotel", "museum")
- preferences: array of specific preferences (e.g., ["romantic", "family-friendly", "budget"])
- is_nearby_request: true if they mention "near me", "around me", "nearby", etc.
- search_radius: radius in meters (1000 for nearby, 5000 for general area searches)

User has {'provided' if has_location else 'NOT provided'} their location.

Return ONLY valid JSON, no markdown or explanation.
"""
        
        response = self.client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a travel intent analyzer. Return only JSON."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3
        )
        
        intent_json = json.loads(response.choices[0].message.content)
        return ExtractedIntent(**intent_json)
    
    async def generate_streaming_response(self, user_message: str, locations: List[LocationCard]):
        """
        Generate streaming response about the locations.
        
        Args:
            user_message: The original user message
            locations: List of found locations
            
        Yields:
            Chunks of the AI response text
        """
        locations_text = "\n".join([
            f"- {loc.name} ({loc.rating}★, {loc.user_ratings_total} reviews) at {loc.address}"
            for loc in locations
        ])
        
        prompt = f"""
User asked: "{user_message}"

I found these locations:
{locations_text}

Provide a helpful, conversational response about these travel destinations. 
Be enthusiastic and informative. Highlight what makes each place special.
Keep it concise but engaging (3-4 paragraphs max).
"""
        
        stream = self.client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "You are a friendly travel assistant helping users discover amazing places."},
                {"role": "user", "content": prompt}
            ],
            stream=True,
            temperature=0.7
        )
        
        for chunk in stream:
            if chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content