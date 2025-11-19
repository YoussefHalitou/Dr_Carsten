import json
import logging
import uuid
from typing import Any

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Path,
    Request,
    WebSocket,
    WebSocketDisconnect,
    status,
)
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..dependencies import enforce_https, limiter, verify_api_key
from ..models.database import ChatSession, Message, async_session_factory, get_db_session
from ..models.schemas import HistoryResponse, MessageRequest, MessageResponse, SessionCreateResponse
from ..services.openai_service import openai_service
from ..settings import settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/chat", tags=["chat"])


class WebSocketManager:
    def __init__(self) -> None:
        self.connections: dict[uuid.UUID, set[WebSocket]] = {}

    async def connect(self, session_id: uuid.UUID, websocket: WebSocket) -> None:
        await websocket.accept()
        self.connections.setdefault(session_id, set()).add(websocket)
        logger.debug("WebSocket connected for session %s", session_id)

    def disconnect(self, session_id: uuid.UUID, websocket: WebSocket) -> None:
        session_connections = self.connections.get(session_id)
        if not session_connections:
            return
        session_connections.discard(websocket)
        if not session_connections:
            self.connections.pop(session_id, None)
        logger.debug("WebSocket disconnected for session %s", session_id)

    async def broadcast(self, session_id: uuid.UUID, payload: dict[str, Any]) -> None:
        connections = self.connections.get(session_id, set())
        if not connections:
            return
        message = json.dumps(payload, default=str)
        for websocket in list(connections):
            try:
                await websocket.send_text(message)
            except Exception:  # noqa: BLE001
                logger.exception("Failed to broadcast to session %s", session_id)
                self.disconnect(session_id, websocket)


ws_manager = WebSocketManager()


async def _get_session(session_id: uuid.UUID, db: AsyncSession) -> ChatSession:
    session = await db.get(ChatSession, session_id)
    if session is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sitzung nicht gefunden.")
    return session


@router.post(
    "/session",
    response_model=SessionCreateResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(verify_api_key)],
)
@limiter.limit("10/minute")
async def create_session(
    request: Request,
    db: AsyncSession = Depends(get_db_session),
    _: None = Depends(enforce_https),
) -> SessionCreateResponse:
    new_session = ChatSession()
    db.add(new_session)
    await db.commit()
    await db.refresh(new_session)
    logger.info("Chat session created: %s", new_session.id)
    return SessionCreateResponse(session_id=new_session.id, created_at=new_session.created_at)


@router.get(
    "/history/{session_id}",
    response_model=HistoryResponse,
    dependencies=[Depends(verify_api_key)],
)
@limiter.limit("20/minute")
async def get_history(
    request: Request,
    session_id: uuid.UUID = Path(..., description="ID der Sitzung"),
    db: AsyncSession = Depends(get_db_session),
    _: None = Depends(enforce_https),
) -> HistoryResponse:
    await _get_session(session_id, db)
    result = await db.execute(
        select(Message)
        .where(Message.session_id == session_id)
        .order_by(Message.timestamp.asc())
    )
    messages = [
        MessageResponse(
            message_id=message.id,  # type: ignore[arg-type]
            session_id=session_id,
            role=message.role,  # type: ignore[arg-type]
            content=message.content,
            timestamp=message.timestamp,
        )
        for message in result.scalars()
    ]
    return HistoryResponse(session_id=session_id, messages=messages)


async def _build_conversation_history(
    db: AsyncSession, session_id: uuid.UUID, limit: int = 10
) -> list[dict[str, str]]:
    result = await db.execute(
        select(Message).where(Message.session_id == session_id).order_by(Message.timestamp.desc()).limit(limit)
    )
    messages = list(result.scalars())
    return [
        {"role": message.role, "content": message.content}
        for message in reversed(messages)
    ]


@router.post(
    "/message",
    response_model=MessageResponse,
    dependencies=[Depends(verify_api_key)],
)
@limiter.limit("20/minute")
async def post_message(
    request: Request,
    payload: MessageRequest,
    db: AsyncSession = Depends(get_db_session),
    _: None = Depends(enforce_https),
) -> MessageResponse:
    session = await _get_session(payload.session_id, db)

    user_message = Message(session_id=session.id, role="user", content=payload.content.strip())
    db.add(user_message)
    await db.commit()
    await db.refresh(user_message)

    await ws_manager.broadcast(
        session.id,
        {
            "type": "user_message",
            "message": {
                "message_id": str(user_message.id),
                "session_id": str(session.id),
                "role": "user",
                "content": user_message.content,
                "timestamp": user_message.timestamp.isoformat(),
            },
        },
    )

    conversation = await _build_conversation_history(db, session.id, limit=10)

    try:
        assistant_reply = await openai_service.generate_response(conversation)
    except Exception as exc:  # noqa: BLE001
        await db.rollback()
        logger.exception("Assistant response failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Antwort des Assistenten derzeit nicht verfügbar.",
        ) from exc

    assistant_message = Message(session_id=session.id, role="assistant", content=assistant_reply)
    db.add(assistant_message)
    await db.commit()
    await db.refresh(user_message)
    await db.refresh(assistant_message)

    response_payload = MessageResponse(
        message_id=assistant_message.id,
        session_id=session.id,
        role="assistant",
        content=assistant_message.content,
        timestamp=assistant_message.timestamp,
    )

    await ws_manager.broadcast(
        session.id,
        {
            "type": "assistant_message",
            "message": response_payload.dict(),
        },
    )

    return response_payload


@router.websocket("/ws/{session_id}")
async def websocket_endpoint(websocket: WebSocket, session_id: uuid.UUID) -> None:
    api_key = websocket.headers.get("x-api-key") or websocket.query_params.get("api_key")
    if api_key != settings.api_key:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    await ws_manager.connect(session_id, websocket)

    try:
        async with async_session_factory() as db_session:
            await _get_session(session_id, db_session)

            while True:
                raw_data = await websocket.receive_text()
                data = json.loads(raw_data)
                content = data.get("content")
                if not isinstance(content, str) or not content.strip():
                    await websocket.send_text(json.dumps({"error": "Ungültige Nachricht."}))
                    continue

                user_message = Message(session_id=session_id, role="user", content=content.strip())
                db_session.add(user_message)
                await db_session.commit()
                await db_session.refresh(user_message)

                await ws_manager.broadcast(
                    session_id,
                    {
                        "type": "user_message",
                        "message": {
                            "message_id": str(user_message.id),
                            "session_id": str(session_id),
                            "role": "user",
                            "content": user_message.content,
                            "timestamp": user_message.timestamp.isoformat(),
                        },
                    },
                )

                conversation = await _build_conversation_history(db_session, session_id, limit=10)
                try:
                    assistant_reply = await openai_service.generate_response(conversation)
                except Exception as exc:  # noqa: BLE001
                    await db_session.rollback()
                    logger.exception("Assistant response failed: %s", exc)
                    await websocket.send_text(
                        json.dumps({"type": "error", "message": "Antwort des Assistenten derzeit nicht verfügbar."})
                    )
                    continue

                assistant_message = Message(session_id=session_id, role="assistant", content=assistant_reply)
                db_session.add(assistant_message)
                await db_session.commit()
                await db_session.refresh(assistant_message)

                payload = {
                    "type": "assistant_message",
                    "message": {
                        "message_id": str(assistant_message.id),
                        "session_id": str(session_id),
                        "role": "assistant",
                        "content": assistant_message.content,
                        "timestamp": assistant_message.timestamp.isoformat(),
                    },
                }
                await ws_manager.broadcast(session_id, payload)
    except WebSocketDisconnect:
        ws_manager.disconnect(session_id, websocket)
    except Exception as exc:  # noqa: BLE001
        logger.exception("WebSocket error for session %s: %s", session_id, exc)
        ws_manager.disconnect(session_id, websocket)
    finally:
        if db_session:
            await db_session.close()

