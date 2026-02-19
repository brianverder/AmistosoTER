/**
 * Team Domain Types
 * Tipos relacionados con equipos de fútbol
 */

export interface Team {
  id: string;
  name: string;
  instagram?: string | null;
  userId: string;
  gamesWon: number;
  gamesLost: number;
  gamesDrawn: number;
  totalGames: number;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export interface TeamStats {
  team: Team;
  winRate: number;
  recentMatches: number;
}

export interface CreateTeamDTO {
  name: string;
  instagram?: string;
}

export interface UpdateTeamDTO {
  name?: string;
}

export interface TeamWithMatches extends Team {
  matchesAsTeam1: any[];
  matchesAsTeam2: any[];
}
