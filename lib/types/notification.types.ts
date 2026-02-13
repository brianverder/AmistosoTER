/**
 * Notification Domain Types
 * Tipos para sistema de notificaciones (PREPARADO PARA FUTURO)
 */

export type NotificationType = 
  | 'match_request'
  | 'match_accepted'
  | 'match_result'
  | 'team_invitation'
  | 'message'
  | 'payment'
  | 'system';

export type NotificationPriority = 'low' | 'medium' | 'high' | 'urgent';

export interface Notification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  priority: NotificationPriority;
  read: boolean;
  actionUrl?: string | null;
  metadata?: Record<string, any>;
  createdAt: Date | string;
}

export interface CreateNotificationDTO {
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  priority?: NotificationPriority;
  actionUrl?: string;
  metadata?: Record<string, any>;
}

export interface NotificationPreferences {
  userId: string;
  emailNotifications: boolean;
  pushNotifications: boolean;
  matchRequests: boolean;
  matchResults: boolean;
  messages: boolean;
  payments: boolean;
}
