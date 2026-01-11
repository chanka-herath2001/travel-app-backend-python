# Travel Chat WebSocket API

A WebSocket-based travel recommendation chat service powered by OpenAI and Google Maps APIs.

## Features

- 🤖 AI-powered intent extraction from user queries
- 🗺️ Google Maps integration for location discovery
- 📍 Nearby location search (1km radius)
- 💬 Streaming chat responses
- 🏞️ Location cards with photos and ratings

## Project Structure

```
travel-chat-backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   ├── config.py            # Configuration management
│   ├── models/
│   │   ├── __init__.py
│   │   └── schemas.py       # Pydantic models
│   ├── services/
│   │   ├── __init__.py
│   │   ├── openai_service.py    # OpenAI integration
│   │   └── maps_service.py      # Google Maps integration
│   ├── websocket/
│   │   ├── __init__.py
│   │   └── handler.py       # WebSocket message handler
│   └── utils/
│       └── __init__.py
├── tests/
│   └── __init__.py
├── .env
├── .gitignore
├── requirements.txt
└── README.md
```

## Setup

### 1. Clone and Navigate

```bash
cd travel-chat-backend
```

### 2. Create Virtual Environment

```bash
python -m venv venv

# Activate it
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure Environment

Create a `.env` file in the root directory:

```env
OPENAI_API_KEY=your_openai_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
HOST=0.0.0.0
PORT=8000
```

### 5. Run the Application

```bash
# From the root directory
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Or:

```bash
uvicorn app.main:app --reload
```

## API Endpoints

### REST Endpoints

- `GET /` - API information
- `GET /health` - Health check

### WebSocket Endpoint

- `WS /ws/chat` - Main chat WebSocket

## Usage

### Message Format

Send JSON messages through the WebSocket:

```json
{
  "message": "Show me romantic restaurants in Paris",
  "user_lat": 48.8566,
  "user_lng": 2.3522
}
```

### Response Types

1. **Status**: Processing updates
2. **Stream Start**: Beginning of AI response
3. **Stream Chunk**: Individual words/phrases
4. **Stream End**: End of AI response
5. **Locations**: Array of location cards
6. **Complete**: Request completed
7. **Error**: Error message

## Testing with Postman

1. Open Postman
2. Create WebSocket Request
3. URL: `ws://localhost:8000/ws/chat`
4. Connect and send test messages

### Example Queries

- "Find coffee shops near me" (with coordinates)
- "Show me museums in London"
- "Romantic restaurants around me"
- "Family-friendly activities in Tokyo"

## Requirements

- Python 3.8+
- OpenAI API key
- Google Maps API key (with Places API enabled)

## License

MIT
