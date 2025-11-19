import clsx from 'clsx';
import type { LinkCardData } from '../types/chat';

interface LinkCardProps extends LinkCardData {
  onSelect?: (payload: { action?: string; title: string }) => void;
}

export const LinkCard = ({ icon, title, subtitle, url, action, onSelect }: LinkCardProps) => {
  const handleClick = () => {
    if (url) {
      window.open(url, '_blank', 'noopener,noreferrer');
    }
    if (onSelect) {
      onSelect({ action, title });
    }
  };

  return (
    <button
      type="button"
      onClick={handleClick}
      className={clsx(
        'w-full cursor-pointer rounded-xl border border-slate-200 bg-slate-100 px-3 py-2 text-left transition-all duration-200',
        'hover:translate-x-0.5 hover:bg-slate-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary-500'
      )}
    >
      <div className="flex items-center gap-3">
        <span className="text-xl">{icon}</span>
        <div className="flex-1">
          <p className="text-sm font-semibold text-slate-700">{title}</p>
          <p className="text-xs text-slate-500">{subtitle}</p>
        </div>
        <span className="text-lg text-slate-400">→</span>
      </div>
    </button>
  );
};

