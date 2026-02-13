/**
 * Match Domain Types
 * Tipos relacionados con partidos y matches
 */

export type MatchStatus = 'pending' | 'confirmed' | 'completed' | 'cancelled';

export interface Match {
  id: string;
  matchRequestId: string;
  team1Id: string;
  team2Id: string;
  userId1: string;
  userId2: string;
  status: MatchStatus;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export interface MatchResult {
  id: string;
  matchId: string;
  team1Score: number;
  team2Score: number;
  winnerId: string | null;
  createdAt: Date | string;
}

export interface MatchWithDetails extends Match {
  team1: {
    id: string;
    name: string;
  };
  team2: {
    id: string;
    name: string;
  };
  matchResult?: MatchResult | null;
  matchRequest: {
    footballType: string | null;
    fieldAddress: string | null;
    matchDate: Date | string | null;
  };
}

export interface CreateMatchResultDTO {
  team1Score: number;
  team2Score: number;
}

export interface MatchStatusInfo {
  text: string;
  icon: string;
  class: string;
}
