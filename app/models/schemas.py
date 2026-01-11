"""Data models and schemas."""
from typing import List, Optional

from pydantic import BaseModel, Field


class LocationCard(BaseModel):
    """Location information card."""
    name: str
    address: str
    rating: Optional[float] = None
    user_ratings_total: Optional[int] = None
    types: List[str] = Field(default_factory=list)
    place_id: str
    lat: float
    lng: float
    photo_reference: Optional[str] = None


class ChatMessage(BaseModel):
    """Incoming chat message from user."""
    message: str
    user_lat: Optional[float] = None
    user_lng: Optional[float] = None


class ExtractedIntent(BaseModel):
    """Extracted user intent from message."""
    destination: Optional[str] = None
    activity_type: Optional[str] = None
    preferences: List[str] = Field(default_factory=list)
    is_nearby_request: bool = False

    # IMPORTANT: Optional to allow AI to omit or return null
    search_radius: Optional[int] = Field(
        default=1000,
        ge=100,
        le=50000,
        description="Search radius in meters"
    )
