export type MessageRole = 'user' | 'assistant';

export interface LinkCardData {
  icon: string;
  title: string;
  subtitle: string;
  url?: string;
  action?: string;
}

export interface ChatMessage {
  id: string;
  role: MessageRole;
  content: string;
  timestamp: string;
  linkCards?: LinkCardData[];
  isHtml?: boolean;
}

export interface QuickReplyOption {
  label: string;
  payload: string;
  icon?: string;
}
