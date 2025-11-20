import axios from 'axios';
import type { ChatMessage } from '../types/chat';

export const BACKEND_BASE_URL = import.meta.env.VITE_BACKEND_URL ?? 'http://localhost:8000';
export const API_KEY = import.meta.env.VITE_API_KEY ?? '';

const apiClient = axios.create({
  baseURL: BACKEND_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'X-API-Key': API_KEY
  },
  timeout: 15000
});

export interface SessionResponse {
  session_id: string;
  created_at: string;
}

export interface MessageResponse {
  message_id: string;
  session_id: string;
  role: 'assistant' | 'user';
  content: string;
  timestamp: string;
}

export const createSession = async (): Promise<SessionResponse> => {
  const { data } = await apiClient.post<SessionResponse>('/api/chat/session');
  return data;
};

export const sendMessage = async (
  sessionId: string,
  content: string
): Promise<MessageResponse> => {
  const { data } = await apiClient.post<MessageResponse>('/api/chat/message', {
    session_id: sessionId,
    content
  });
  return data;
};

export const fetchHistory = async (sessionId: string): Promise<ChatMessage[]> => {
  const { data } = await apiClient.get<{ session_id: string; messages: MessageResponse[] }>(
    `/api/chat/history/${sessionId}`
  );

  return data.messages.map((message) => ({
    id: message.message_id,
    role: message.role,
    content: message.content,
    timestamp: message.timestamp
  }));
};
