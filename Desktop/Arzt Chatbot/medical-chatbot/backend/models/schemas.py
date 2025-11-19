import uuid
from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field


class SessionCreateResponse(BaseModel):
    session_id: uuid.UUID
    created_at: datetime


class MessageRequest(BaseModel):
    session_id: uuid.UUID = Field(..., description="ID der laufenden Sitzung")
    content: str = Field(..., min_length=1, max_length=2000)


class MessageResponse(BaseModel):
    message_id: uuid.UUID
    session_id: uuid.UUID
    role: Literal["user", "assistant"]
    content: str
    timestamp: datetime


class HistoryResponse(BaseModel):
    session_id: uuid.UUID
    messages: list[MessageResponse]

