import logging
import sys
from contextlib import asynccontextmanager
from typing import AsyncIterator

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from starlette.responses import JSONResponse

from .dependencies import limiter
from .models.database import init_models
from .routers.chat import router as chat_router
from .settings import settings

logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    stream=sys.stdout,
)

logger = logging.getLogger("medical-chatbot")


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    logger.info("Initialising application...")
    await init_models()
    logger.info("Database ready.")
    yield
    logger.info("Shutting down application...")


app = FastAPI(
    title="Medical Chatbot API",
    description="Chatbot-Backend für die Online-Rezeption einer Arztpraxis.",
    version="1.0.0",
    debug=settings.debug,
    lifespan=lifespan,
)

app.state.limiter = limiter


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    return JSONResponse({"detail": "Rate limit exceeded. Bitte versuchen Sie es später erneut."}, status_code=429)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(SlowAPIMiddleware)


@app.middleware("http")
async def add_security_headers(request: Request, call_next) -> Response:
    """
    Security headers middleware.
    
    Important for iframe embedding:
    - CSP frame-ancestors: Allows embedding from chatbotcarsten.live and Netlify domains
    - X-Frame-Options: Removed to allow cross-origin iframe embedding
    - CORS is handled by CORSMiddleware above
    """
    response = await call_next(request)
    
    # Get the Origin header for dynamic CSP frame-ancestors
    origin = request.headers.get("origin")
    allowed_origins = settings.cors_origins
    
    # Build frame-ancestors directive dynamically
    # Allow self and all CORS-allowed origins
    frame_ancestors = ["'self'"]
    for allowed_origin in allowed_origins:
        if allowed_origin not in frame_ancestors:
            frame_ancestors.append(allowed_origin)
    
    frame_ancestors_str = " ".join(frame_ancestors)
    
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    
    if request.url.path.startswith(("/docs", "/redoc", "/openapi.json", "/swagger-ui")):
        # Swagger UI needs more permissive CSP
        response.headers[
            "Content-Security-Policy"
        ] = (
            f"default-src 'self'; "
            f"frame-ancestors {frame_ancestors_str}; "
            "img-src 'self' data:; "
            "style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; "
            "script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; "
            "font-src 'self' data: https://cdn.jsdelivr.net"
        )
    else:
        # API endpoints: Allow iframe embedding from allowed origins
        # This is important for the frontend to work when embedded on Netlify
        response.headers[
            "Content-Security-Policy"
        ] = (
            f"default-src 'self'; "
            f"frame-ancestors {frame_ancestors_str};"
        )
    
    response.headers["X-Content-Type-Options"] = "nosniff"
    
    # DO NOT set X-Frame-Options - it conflicts with CSP frame-ancestors
    # and would block iframe embedding. CSP frame-ancestors is the modern way.
    # X-Frame-Options removed to allow cross-origin iframe embedding
    
    return response


@app.get("/health", tags=["health"])
async def health_check() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(chat_router)


def run() -> None:
    import uvicorn

    uvicorn.run(
        "backend.main:app",
        host="0.0.0.0",
        port=settings.port,
        reload=settings.debug,
        ssl_keyfile=None,
        ssl_certfile=None,
    )


if __name__ == "__main__":
    run()

