import type { ButtonHTMLAttributes } from 'react';
import clsx from 'clsx';

interface ChatButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  isOpen: boolean;
}

export const ChatButton = ({ isOpen, className, ...props }: ChatButtonProps) => {
  return (
    <button
      type="button"
      aria-label={isOpen ? 'Chat schließen' : 'Chat öffnen'}
      className={clsx(
        'fixed bottom-5 right-5 z-50 flex h-14 w-14 items-center justify-center rounded-full md:h-16 md:w-16',
        'bg-gradient-to-br from-primary-500 to-secondary-500 text-white shadow-xl transition-transform duration-300',
        'hover:scale-110 focus:outline-none focus-visible:ring-2 focus-visible:ring-white focus-visible:ring-offset-2 focus-visible:ring-offset-primary-500',
        className
      )}
      {...props}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        className="h-7 w-7"
        viewBox="0 0 24 24"
        fill="currentColor"
        aria-hidden="true"
      >
        {isOpen ? (
          <path d="M6 18L18 6M6 6l12 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
        ) : (
          <path d="M20 2H4a2 2 0 0 0-2 2v18l4-4h14a2 2 0 0 0 2-2V4a2 2 0 0 0-2-2zm0 14H6l-2 2V4h16v12z" />
        )}
      </svg>
    </button>
  );
};

