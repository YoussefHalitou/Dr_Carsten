import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import clsx from 'clsx';
import { ChatButton } from './ChatButton';
import { ChatMessages } from './ChatMessages';
import { QuickReplies } from './QuickReplies';
import { useChat } from '../hooks/useChat';

export const ChatWidget = () => {
  const {
    isOpen,
    toggleOpen,
    messages,
    isTyping,
    isLoading,
    error,
    sendMessage,
    quickReplies,
    socketStatus,
    handleLinkAction,
    resetChat
  } = useChat();
  const [inputValue, setInputValue] = useState('');
  const inputRef = useRef<HTMLInputElement | null>(null);

  const isSendDisabled = !inputValue.trim();

  useEffect(() => {
    if (isOpen) {
      inputRef.current?.focus();
    }
  }, [isOpen]);

  const handleSend = useCallback(() => {
    const value = inputValue.trim();
    if (!value) return;
    sendMessage(value);
    setInputValue('');
  }, [inputValue, sendMessage]);

  const handleQuickReply = useCallback(
    (payload: string) => {
      setInputValue('');
      sendMessage(payload);
    },
    [sendMessage]
  );

  const statusLabel = useMemo(() => {
    switch (socketStatus) {
      case 'connecting':
        return 'Verbindung wird hergestellt...';
      case 'open':
        return 'Online';
      case 'closed':
        return 'Offline';
      default:
        return '';
    }
  }, [socketStatus]);

  return (
    <>
      <ChatButton onClick={toggleOpen} isOpen={isOpen} />

      <div
        className={clsx(
          'fixed bottom-[90px] left-1/2 z-40 flex h-[600px] w-[calc(100vw-40px)] max-w-[380px] -translate-x-1/2 flex-col overflow-hidden rounded-3xl bg-white shadow-chat transition-transform duration-300 md:left-auto md:right-5 md:translate-x-0',
          isOpen ? 'translate-y-0 opacity-100 animate-slideUp' : 'pointer-events-none translate-y-10 opacity-0'
        )}
      >
        <header className="flex items-center justify-between bg-gradient-to-br from-primary-500 to-secondary-500 px-6 py-5 text-white">
          <div>
            <h3 className="text-lg font-semibold">Online-Rezeption</h3>
            <p className="text-xs opacity-90">Wir helfen Ihnen gerne weiter.</p>
            {statusLabel ? <p className="text-xs opacity-75">{statusLabel}</p> : null}
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={resetChat}
              className="hidden rounded-full border border-white/30 px-3 py-1 text-xs font-medium text-white transition-colors duration-200 hover:bg-white/20 focus:outline-none focus-visible:ring-2 focus-visible:ring-white md:inline-flex"
            >
              Zurücksetzen
            </button>
            <button
              type="button"
              onClick={toggleOpen}
              className="flex h-8 w-8 items-center justify-center rounded-full transition-colors duration-200 hover:bg-white/20 focus:outline-none focus-visible:ring-2 focus-visible:ring-white"
              aria-label="Chat schließen"
            >
              <span className="text-2xl leading-none">&times;</span>
            </button>
          </div>
        </header>

        <ChatMessages messages={messages} isTyping={isTyping || isLoading} onLinkSelect={handleLinkAction} />

        {error ? (
          <div className="bg-red-50 px-5 py-2 text-xs text-red-600">{error}</div>
        ) : null}

        <QuickReplies quickReplies={quickReplies} onSelect={handleQuickReply} />

        <div className="border-t border-slate-200 bg-white px-5 py-4">
          <div className="flex items-center gap-3 rounded-full border border-slate-200 bg-white px-3 py-2">
            <input
              ref={inputRef}
              type="text"
              value={inputValue}
              onChange={(event) => setInputValue(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === 'Enter') {
                  event.preventDefault();
                  handleSend();
                }
              }}
              placeholder="Nachricht eingeben..."
              className="flex-1 border-none bg-transparent text-sm text-slate-800 outline-none placeholder:text-slate-400"
            />
            <button
              type="button"
              onClick={handleSend}
              disabled={isSendDisabled}
              className={clsx(
                'flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-primary-500 to-secondary-500 text-white transition-transform duration-200',
                isSendDisabled ? 'opacity-50' : 'hover:scale-105'
              )}
              aria-label="Nachricht senden"
            >
              <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 24 24" fill="currentColor">
                <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z" />
              </svg>
            </button>
          </div>
        </div>
      </div>
    </>
  );
};

