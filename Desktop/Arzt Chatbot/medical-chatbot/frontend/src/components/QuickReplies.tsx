import type { QuickReplyOption } from '../types/chat';

interface QuickRepliesProps {
  quickReplies: QuickReplyOption[];
  onSelect: (payload: string) => void;
}

export const QuickReplies = ({ quickReplies, onSelect }: QuickRepliesProps) => {
  if (!quickReplies.length) return null;

  return (
    <div className="border-t border-slate-200 bg-slate-50 px-5 pb-3 pt-4 [overflow-anchor:none]">
      <div className="grid max-h-36 grid-cols-2 gap-2 overflow-y-auto pr-1">
        {quickReplies.map((reply) => (
          <button
            key={reply.label}
            type="button"
            onClick={() => onSelect(reply.payload)}
            className="flex w-full items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2 text-sm text-slate-700 transition-all duration-200 hover:border-primary-500 hover:bg-primary-500 hover:text-white focus:outline-none focus-visible:ring-2 focus-visible:ring-primary-500"
          >
            {reply.icon ? <span>{reply.icon}</span> : null}
            {reply.label}
          </button>
        ))}
      </div>
    </div>
  );
};

