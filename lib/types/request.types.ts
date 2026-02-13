/**
 * Match Request Domain Types
 * Tipos relacionados con solicitudes de partidos
 */

export type RequestStatus = 'active' | 'matched' | 'completed' | 'cancelled';
export type FootballType = '5' | '7' | '8' | '11' | 'futsal';

export interface MatchRequest {
  id: string;
  userId: string;
  teamId: string;
  footballType: FootballType | null;
  fieldName: string | null;
  fieldAddress: string | null;
  country: string | null;
  state: string | null;
  fieldPrice: number | null;
  matchDate: Date | string | null;
  league: string | null;
  description: string | null;
  status: RequestStatus;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export interface MatchRequestWithDetails extends MatchRequest {
  team: {
    id: string;
    name: string;
  };
  user: {
    id: string;
    name: string;
    email: string;
    phone: string | null;
  };
  match?: any | null;
}

export interface CreateMatchRequestDTO {
  teamId: string;
  footballType?: FootballType;
  fieldName?: string;
  fieldAddress?: string;
  country?: string;
  state?: string;
  fieldPrice?: number;
  matchDate?: Date | string;
  league?: string;
  description?: string;
}

export interface UpdateMatchRequestDTO {
  status?: RequestStatus;
}

export interface RequestStatusBadge {
  text: string;
  class: string;
  icon: string;
}
