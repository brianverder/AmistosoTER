/**
 * Chat Domain Types
 * Tipos para sistema de mensajería (PREPARADO PARA FUTURO)
 */

export type MessageType = 'text' | 'image' | 'file' | 'system';
export type ConversationType = 'direct' | 'match' | 'team' | 'group';

export interface Message {
  id: string;
  conversationId: string;
  senderId: string;
  content: string;
  type: MessageType;
  attachmentUrl?: string | null;
  read: boolean;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export interface Conversation {
  id: string;
  type: ConversationType;
  matchId?: string | null;
  teamId?: string | null;
  participants: string[]; // Array de userIds
  lastMessage?: Message | null;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export interface ConversationWithDetails extends Conversation {
  participantDetails: Array<{
    id: string;
    name: string;
    avatar?: string;
  }>;
  unreadCount: number;
}

export interface SendMessageDTO {
  conversationId: string;
  content: string;
  type?: MessageType;
  attachmentUrl?: string;
}

export interface CreateConversationDTO {
  type: ConversationType;
  participantIds: string[];
  matchId?: string;
  teamId?: string;
}
