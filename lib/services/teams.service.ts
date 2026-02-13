/**
 * Teams Service
 * Servicio para gestión de equipos
 */

import { Team, CreateTeamDTO, UpdateTeamDTO, TeamStats } from '@/lib/types';
import { API_ROUTES } from '@/lib/utils/constants';

export class TeamsService {
  /**
   * Obtiene todos los equipos del usuario actual
   */
  static async getUserTeams(): Promise<Team[]> {
    const response = await fetch(API_ROUTES.TEAMS);
    
    if (!response.ok) {
      throw new Error('Error al obtener equipos');
    }
    
    return response.json();
  }

  /**
   * Obtiene un equipo por ID
   */
  static async getTeamById(id: string): Promise<Team> {
    const response = await fetch(`${API_ROUTES.TEAMS}/${id}`);
    
    if (!response.ok) {
      throw new Error('Error al obtener equipo');
    }
    
    return response.json();
  }

  /**
   * Obtiene estadísticas de un equipo
   */
  static async getTeamStats(id: string): Promise<TeamStats> {
    const response = await fetch(`${API_ROUTES.TEAMS}/${id}/stats`);
    
    if (!response.ok) {
      throw new Error('Error al obtener estadísticas');
    }
    
    return response.json();
  }

  /**
   * Crea un nuevo equipo
   */
  static async createTeam(data: CreateTeamDTO): Promise<Team> {
    const response = await fetch(API_ROUTES.TEAMS, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Error al crear equipo');
    }
    
    return response.json();
  }

  /**
   * Actualiza un equipo
   */
  static async updateTeam(id: string, data: UpdateTeamDTO): Promise<Team> {
    const response = await fetch(`${API_ROUTES.TEAMS}/${id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Error al actualizar equipo');
    }
    
    return response.json();
  }

  /**
   * Elimina un equipo
   */
  static async deleteTeam(id: string): Promise<void> {
    const response = await fetch(`${API_ROUTES.TEAMS}/${id}`, {
      method: 'DELETE',
    });
    
    if (!response.ok) {
      throw new Error('Error al eliminar equipo');
    }
  }

  /**
   * Calcula el win rate de un equipo
   */
  static calculateWinRate(team: Team): number {
    if (team.totalGames === 0) return 0;
    return (team.gamesWon / team.totalGames) * 100;
  }
}
