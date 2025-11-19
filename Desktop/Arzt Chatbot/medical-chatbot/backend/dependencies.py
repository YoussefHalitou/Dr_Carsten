import logging
from typing import Annotated

from fastapi import Header, HTTPException, Request, status
from slowapi import Limiter
from slowapi.util import get_remote_address

from .settings import settings

logger = logging.getLogger(__name__)

limiter = Limiter(key_func=get_remote_address, default_limits=["20/minute"])


async def enforce_https(request: Request) -> None:
    # OPTIONS-Requests (CORS Preflight) immer erlauben
    if request.method == "OPTIONS":
        return
    if not settings.enforce_https:
        return
    if request.client and request.client.host in {"127.0.0.1", "localhost"}:
        return

    proto = request.headers.get("x-forwarded-proto", request.url.scheme)
    if proto != "https":
        logger.warning("Rejected insecure request from %s", request.client)
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="HTTPS is required for this endpoint.",
        )


async def verify_api_key(request: Request, x_api_key: Annotated[str | None, Header(alias="X-API-Key")] = None) -> None:
    # OPTIONS-Requests (CORS Preflight) immer erlauben
    if request.method == "OPTIONS":
        return
    if x_api_key is None or x_api_key != settings.api_key:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid API key.")

