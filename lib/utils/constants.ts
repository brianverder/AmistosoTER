/**
 * Application Constants
 * Constantes globales de la aplicación
 */

// Football Types
export const FOOTBALL_TYPES = ['5', '7', '8', '11', 'otro'] as const;

export const FOOTBALL_TYPE_LABELS: Record<string, string> = {
  '5': 'Fútbol 5',
  '7': 'Fútbol 7',
  '8': 'Fútbol 8',
  '11': 'Fútbol 11',
  'otro': 'Otro',
};

// Request Status
export const REQUEST_STATUS = {
  ACTIVE: 'active',
  MATCHED: 'matched',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
} as const;

export const REQUEST_STATUS_LABELS: Record<string, string> = {
  active: 'Activa',
  matched: 'Match Hecho',
  completed: 'Finalizado',
  cancelled: 'Cancelado',
};

// Match Status
export const MATCH_STATUS = {
  PENDING: 'pending',
  CONFIRMED: 'confirmed',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
} as const;

export const MATCH_STATUS_LABELS: Record<string, string> = {
  pending: 'Pendiente',
  confirmed: 'Confirmado',
  completed: 'Finalizado',
  cancelled: 'Cancelado',
};

// Pagination
export const DEFAULT_PAGE_SIZE = 20;
export const MAX_PAGE_SIZE = 100;

// File Upload
export const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
export const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

// Date Formats
export const DATE_FORMAT = 'dd/MM/yyyy';
export const DATETIME_FORMAT = 'dd/MM/yyyy HH:mm';

// API Routes
export const API_ROUTES = {
  TEAMS: '/api/teams',
  REQUESTS: '/api/requests',
  MATCHES: '/api/matches',
  USERS: '/api/users',
  // Preparado para futuras features
  NOTIFICATIONS: '/api/notifications',
  PAYMENTS: '/api/payments',
  CHAT: '/api/chat',
} as const;

// App Routes
export const APP_ROUTES = {
  HOME: '/',
  LOGIN: '/login',
  REGISTER: '/register',
  DASHBOARD: '/dashboard',
  TEAMS: '/dashboard/teams',
  REQUESTS: '/dashboard/requests',
  MATCHES: '/dashboard/matches',
  STATS: '/dashboard/stats',
  PUBLIC_MATCHES: '/partidos',
  HELP: '/dashboard/help',
  // Preparado para futuras features
  NOTIFICATIONS: '/dashboard/notifications',
  PAYMENTS: '/dashboard/payments',
  CHAT: '/dashboard/chat',
  PROFILE: '/dashboard/profile',
} as const;

// Error Messages
export const ERROR_MESSAGES = {
  UNAUTHORIZED: 'No estás autorizado para realizar esta acción',
  NOT_FOUND: 'Recurso no encontrado',
  SERVER_ERROR: 'Error del servidor, intenta nuevamente',
  NETWORK_ERROR: 'Error de conexión, verifica tu internet',
  VALIDATION_ERROR: 'Datos inválidos, revisa los campos',
} as const;

// Success Messages
export const SUCCESS_MESSAGES = {
  TEAM_CREATED: 'Equipo creado exitosamente',
  TEAM_UPDATED: 'Equipo actualizado exitosamente',
  TEAM_DELETED: 'Equipo eliminado exitosamente',
  REQUEST_CREATED: 'Solicitud creada exitosamente',
  REQUEST_CANCELLED: 'Solicitud cancelada exitosamente',
  MATCH_ACCEPTED: 'Match aceptado exitosamente',
  RESULT_SAVED: 'Resultado guardado exitosamente',
} as const;
