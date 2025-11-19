import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import type { ChatMessage, QuickReplyOption } from '../types/chat';
import { API_KEY, BACKEND_BASE_URL, createSession, fetchHistory, sendMessage as sendMessageApi } from '../services/api';
import { DEFAULT_QUICK_REPLY_LABELS, responses } from '../data/responses';
import type { ResponseTemplate } from '../data/responses';

const getRandomId = () =>
  (typeof crypto !== 'undefined' && crypto.randomUUID ? crypto.randomUUID() : Math.random().toString(36).slice(2));

const QUICK_REPLY_LIBRARY: Record<string, QuickReplyOption> = {
  'Termin vereinbaren': { label: 'Termin vereinbaren', payload: 'Termin vereinbaren', icon: '📅' },
  'Termin absagen': { label: 'Termin absagen', payload: 'Termin absagen', icon: '❌' },
  'Befund anfragen': { label: 'Befund anfragen', payload: 'Befund anfragen', icon: '📋' },
  'Rezept anfordern': { label: 'Rezept anfordern', payload: 'Rezept anfordern', icon: '💊' },
  'Krankmeldung anfordern': { label: 'Krankmeldung anfordern', payload: 'Krankmeldung anfordern', icon: '📝' },
  'Überweisung anfordern': { label: 'Überweisung anfordern', payload: 'Überweisung anfordern', icon: '📄' },
  'Öffnungszeiten': { label: 'Öffnungszeiten', payload: 'Öffnungszeiten', icon: '🕑' },
  'Kontakt': { label: 'Kontakt', payload: 'Kontakt', icon: '☎️' },
  'Leistungen': { label: 'Leistungen', payload: 'Leistungen', icon: '🩺' },
  'Zurück zum Hauptmenü': { label: 'Zurück zum Hauptmenü', payload: 'Zurück zum Hauptmenü', icon: '🏠' }
};

const mapQuickReplies = (labels?: string[]): QuickReplyOption[] => {
  if (labels === undefined) {
    return DEFAULT_QUICK_REPLY_LABELS.map((label) => QUICK_REPLY_LIBRARY[label] ?? { label, payload: label });
  }
  if (labels.length === 0) {
    return [];
  }
  return labels.map((label) => QUICK_REPLY_LIBRARY[label] ?? { label, payload: label });
};

type WebSocketStatus = 'idle' | 'connecting' | 'open' | 'closed';

const parseAssistantMessage = (message: ChatMessage): ChatMessage => {
  const containsHtml = /<[^>]+>/.test(message.content);
  return {
    ...message,
    isHtml: containsHtml
  };
};

const normalize = (value: string) => value.toLowerCase().trim();

const findTemplateResponse = (message: string): { key: string; template: ResponseTemplate } | null => {
  const normalized = normalize(message);
  for (const [key, template] of Object.entries(responses)) {
    if (key === 'default') continue;
    if (normalized.includes(key)) {
      return { key, template };
    }
  }
  if (responses.default && normalized.includes('default')) {
    return { key: 'default', template: responses.default };
  }
  return null;
};

export const useChat = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isTyping, setIsTyping] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [socketStatus, setSocketStatus] = useState<WebSocketStatus>('idle');
  const [quickRepliesState, setQuickRepliesState] = useState<QuickReplyOption[]>(mapQuickReplies());

  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<number | null>(null);
  const messageIdsRef = useRef<Set<string>>(new Set());

  const addMessage = useCallback((message: ChatMessage) => {
    setMessages((prev) => {
      if (messageIdsRef.current.has(message.id)) {
        return prev;
      }
      messageIdsRef.current.add(message.id);
      const nextMessages = [...prev, message];
      if (nextMessages.length > 200) {
        nextMessages.shift();
      }
      return nextMessages;
    });
  }, []);

  const setupWebSocket = useCallback(
    (id: string) => {
      if (wsRef.current?.readyState === WebSocket.OPEN) {
        return;
      }

      try {
        setSocketStatus('connecting');
        const wsUrl = new URL(`/api/chat/ws/${id}`, BACKEND_BASE_URL);
        wsUrl.protocol = wsUrl.protocol.replace('http', 'ws');
        wsUrl.searchParams.set('api_key', API_KEY);

        const socket = new WebSocket(wsUrl.toString());
        wsRef.current = socket;

        socket.onopen = () => {
          setSocketStatus('open');
          setError(null);
        };

        socket.onclose = () => {
          setSocketStatus('closed');
          if (reconnectTimeoutRef.current) {
            window.clearTimeout(reconnectTimeoutRef.current);
          }
          reconnectTimeoutRef.current = window.setTimeout(() => {
            setupWebSocket(id);
          }, 2000);
        };

        socket.onerror = () => {
          setError('Verbindungsfehler. Bitte prüfen Sie Ihre Internetverbindung.');
          setSocketStatus('closed');
        };

        socket.onmessage = (event) => {
          try {
            const payload = JSON.parse(event.data);
            if (payload.type === 'assistant_message' && payload.message) {
              const message: ChatMessage = parseAssistantMessage({
                id: payload.message.message_id,
                role: payload.message.role,
                content: payload.message.content,
                timestamp: payload.message.timestamp
              });
              addMessage(message);
              setIsTyping(false);
              setQuickRepliesState(mapQuickReplies());
            } else if (payload.type === 'user_message' && payload.message) {
              const message: ChatMessage = {
                id: payload.message.message_id,
                role: 'user',
                content: payload.message.content,
                timestamp: payload.message.timestamp
              };
              addMessage(message);
            } else if (payload.type === 'error') {
              setError(payload.message ?? 'Unbekannter Fehler');
              setIsTyping(false);
            }
          } catch (err) {
            console.error('Fehler beim Verarbeiten der WebSocket-Nachricht', err);
          }
        };
      } catch (err) {
        console.error('WebSocket konnte nicht erstellt werden', err);
        setSocketStatus('closed');
      }
    },
    [addMessage]
  );

  const initialise = useCallback(async () => {
    try {
      setIsLoading(true);
      const session = await createSession();
      setSessionId(session.session_id);

      const history = await fetchHistory(session.session_id);
      if (history.length === 0) {
        addMessage({
          id: getRandomId(),
          role: 'assistant',
          content: 'Willkommen! Wie kann ich Ihnen heute helfen?',
          timestamp: new Date().toISOString()
        });
      } else {
        history.forEach((message) => addMessage(parseAssistantMessage(message)));
      }

      setupWebSocket(session.session_id);
      setQuickRepliesState(mapQuickReplies());
    } catch (err) {
      console.error('Fehler bei der Initialisierung der Sitzung', err);
      setError('Die Sitzung konnte nicht gestartet werden. Bitte versuchen Sie es später erneut.');
    } finally {
      setIsLoading(false);
    }
  }, [addMessage, setupWebSocket]);

  useEffect(() => {
    initialise();

    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
      if (reconnectTimeoutRef.current) {
        window.clearTimeout(reconnectTimeoutRef.current);
      }
    };
  }, [initialise]);

  const sendMessage = useCallback(
    async (content: string, options?: { skipUserMessage?: boolean }) => {
      const skipUserMessage = options?.skipUserMessage ?? false;
      const trimmed = content.trim();
      if (!trimmed) return;

      const templateMatch = findTemplateResponse(trimmed);
      if (templateMatch) {
        if (!skipUserMessage) {
          addMessage({
            id: getRandomId(),
            role: 'user',
            content: trimmed,
            timestamp: new Date().toISOString()
          });
        }
        setError(null);
        setIsTyping(true);
        window.setTimeout(() => {
          const templateContent = templateMatch.template.html ?? templateMatch.template.text ?? '';
          if (templateContent) {
            addMessage({
              id: getRandomId(),
              role: 'assistant',
              content: templateContent,
              timestamp: new Date().toISOString(),
              isHtml: Boolean(templateMatch.template.html),
              linkCards: templateMatch.template.links
            });
          }
          setQuickRepliesState(mapQuickReplies(templateMatch.template.quickReplies));
          setIsTyping(false);
        }, 500);
        return;
      }

      if (!sessionId) {
        setError('Keine aktive Sitzung. Bitte laden Sie die Seite neu.');
        return;
      }

      setError(null);
      setIsTyping(true);

      const activeSocket = wsRef.current && wsRef.current.readyState === WebSocket.OPEN;

      if (activeSocket) {
        wsRef.current?.send(JSON.stringify({ content: trimmed }));
        return;
      }

      if (!skipUserMessage) {
        addMessage({
          id: getRandomId(),
          role: 'user',
          content: trimmed,
          timestamp: new Date().toISOString()
        });
      }

      try {
        const response = await sendMessageApi(sessionId, trimmed);
        const assistantMessage: ChatMessage = parseAssistantMessage({
          id: response.message_id,
          role: response.role,
          content: response.content,
          timestamp: response.timestamp
        });
        addMessage(assistantMessage);
        setQuickRepliesState(mapQuickReplies());
      } catch (err) {
        console.error('Fehler beim Senden der Nachricht', err);
        setError('Nachricht konnte nicht gesendet werden. Bitte versuchen Sie es erneut.');
      } finally {
        setIsTyping(false);
      }
    },
    [addMessage, sessionId]
  );

  const toggleOpen = useCallback(() => {
    setIsOpen((prev) => !prev);
  }, []);

  const quickReplies = useMemo(() => quickRepliesState, [quickRepliesState]);

  const handleLinkAction = useCallback(
    ({ action, title }: { action?: string; title: string }) => {
      const displayText = title.trim();
      if (displayText) {
        addMessage({
          id: getRandomId(),
          role: 'user',
          content: displayText,
          timestamp: new Date().toISOString()
        });
      }
      const payload = (action ?? displayText).trim();
      if (!payload) return;
      void sendMessage(payload, { skipUserMessage: true });
    },
    [addMessage, sendMessage]
  );

  const resetChat = useCallback(() => {
    setMessages([]);
    messageIdsRef.current.clear();
    setQuickRepliesState(mapQuickReplies());
    setError(null);
    setIsTyping(false);
    addMessage({
      id: getRandomId(),
      role: 'assistant',
      content: 'Willkommen! Wie kann ich Ihnen heute helfen?',
      timestamp: new Date().toISOString()
    });
  }, [addMessage]);

  return {
    isOpen,
    toggleOpen,
    messages,
    isTyping,
    isLoading,
    error,
    sendMessage,
    quickReplies,
    sessionId,
    socketStatus,
    handleLinkAction,
    resetChat
  };
};

export type UseChatReturn = ReturnType<typeof useChat>;

