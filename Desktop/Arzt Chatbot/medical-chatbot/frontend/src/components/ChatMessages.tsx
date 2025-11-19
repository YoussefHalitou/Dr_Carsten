import DOMPurify from 'dompurify';
import { useEffect, useRef } from 'react';
import type { ChatMessage } from '../types/chat';
import { LinkCard } from './LinkCard';

interface ChatMessagesProps {
  messages: ChatMessage[];
  isTyping: boolean;
  onLinkSelect?: (payload: { action?: string; title: string }) => void;
}

const sanitize = (html: string) => ({
  __html: DOMPurify.sanitize(html, { ALLOWED_TAGS: ['strong', 'em', 'br', 'ul', 'ol', 'li', 'p', 'a'] })
});

export const ChatMessages = ({ messages, isTyping, onLinkSelect }: ChatMessagesProps) => {
  const containerRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;
    containerRef.current.scrollTop = containerRef.current.scrollHeight;
  }, [messages, isTyping]);

  return (
    <div ref={containerRef} className="flex-1 overflow-y-auto bg-slate-50 px-5 py-6">
      {messages.map((message) => {
        const isAssistant = message.role === 'assistant';
        return (
          <div
            key={message.id}
            className={`mb-4 flex animate-fadeIn ${isAssistant ? 'justify-start' : 'justify-end'}`}
          >
            <div
              className={`max-w-[85%] rounded-2xl px-4 py-3 text-sm leading-relaxed shadow-sm ${
                isAssistant
                  ? 'rounded-tl-sm bg-white text-slate-800 shadow'
                  : 'rounded-tr-sm bg-gradient-to-br from-primary-500 to-secondary-500 text-white'
              }`}
            >
              {message.isHtml ? (
                <div dangerouslySetInnerHTML={sanitize(message.content)} />
              ) : (
                <p className="whitespace-pre-line">{message.content}</p>
              )}

              {message.linkCards?.length ? (
                <div className="mt-3 space-y-2">
                  {message.linkCards.map((card) => (
                    <LinkCard key={`${message.id}-${card.title}`} {...card} onSelect={onLinkSelect} />
                  ))}
                </div>
              ) : null}
            </div>
          </div>
        );
      })}

      {isTyping ? (
        <div className="flex justify-start">
          <div className="mt-2 inline-flex items-center gap-1 rounded-xl bg-white px-3 py-2 shadow">
            <span className="h-2.5 w-2.5 animate-typing rounded-full bg-slate-400" style={{ animationDelay: '0ms' }} />
            <span className="h-2.5 w-2.5 animate-typing rounded-full bg-slate-400" style={{ animationDelay: '200ms' }} />
            <span className="h-2.5 w-2.5 animate-typing rounded-full bg-slate-400" style={{ animationDelay: '400ms' }} />
          </div>
        </div>
      ) : null}
    </div>
  );
};

