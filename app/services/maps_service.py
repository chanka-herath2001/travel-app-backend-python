"""Google Maps service for location search."""
from typing import List, Optional

import googlemaps

from app.config import get_settings
from app.models.schemas import ExtractedIntent, LocationCard

settings = get_settings()

class GoogleMapsService:
    """Service for Google Maps API interactions."""
    
    def __init__(self):
        """Initialize Google Maps client."""
        self.client = googlemaps.Client(key=settings.google_maps_api_key)
    
    def search_places(
        self, 
        intent: ExtractedIntent, 
        user_lat: Optional[float] = None, 
        user_lng: Optional[float] = None
    ) -> List[LocationCard]:
        """
        Search for places using Google Maps Places API.
        
        Args:
            intent: Extracted user intent
            user_lat: User's latitude (optional)
            user_lng: User's longitude (optional)
            
        Returns:
            List of LocationCard objects
        """
        if intent.is_nearby_request and user_lat and user_lng:
            # Nearby search
            location = f"{user_lat},{user_lng}"
            results = self.client.places_nearby(
                location=location,
                radius=intent.search_radius,
                type=intent.activity_type,
                keyword=" ".join(intent.preferences) if intent.preferences else None
            )
        elif intent.destination:
            # Text search for specific destination
            query = f"{' '.join(intent.preferences)} {intent.activity_type or 'places to visit'} in {intent.destination}"
            results = self.client.places(query=query)
        else:
            # Generic search with preferences
            query = f"{' '.join(intent.preferences)} {intent.activity_type or 'travel destinations'}"
            results = self.client.places(query=query)
        
        locations = []
        places = results.get('results', [])[:5]  # Limit to top 5 results
        
        for place in places:
            photo_ref = None
            if place.get('photos'):
                photo_ref = place['photos'][0].get('photo_reference')
            
            location = LocationCard(
                name=place.get('name', 'Unknown'),
                address=place.get('vicinity') or place.get('formatted_address', 'Address not available'),
                rating=place.get('rating'),
                user_ratings_total=place.get('user_ratings_total'),
                types=place.get('types', []),
                place_id=place.get('place_id', ''),
                lat=place['geometry']['location']['lat'],
                lng=place['geometry']['location']['lng'],
                photo_reference=photo_ref
            )
            locations.append(location)
        
        return locations
    
    def get_photo_url(self, photo_reference: str, max_width: int = 400) -> str:
        """
        Generate Google Maps photo URL.
        
        Args:
            photo_reference: Photo reference from Places API
            max_width: Maximum width of the photo
            
        Returns:
            URL string for the photo
        """
        return f"https://maps.googleapis.com/maps/api/place/photo?maxwidth={max_width}&photoreference={photo_reference}&key={settings.google_maps_api_key}"