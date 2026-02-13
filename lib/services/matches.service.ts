/**
 * Matches Service
 * Servicio para gestión de partidos
 */

import { Match, MatchWithDetails, CreateMatchResultDTO, MatchStatusInfo } from '@/lib/types';
import { API_ROUTES } from '@/lib/utils/constants';

export class MatchesService {
  /**
   * Obtiene todos los matches del usuario
   */
  static async getUserMatches(): Promise<MatchWithDetails[]> {
    const response = await fetch(API_ROUTES.MATCHES);
    
    if (!response.ok) {
      throw new Error('Error al obtener matches');
    }
    
    return response.json();
  }

  /**
   * Obtiene un match por ID
   */
  static async getMatchById(id: string): Promise<MatchWithDetails> {
    const response = await fetch(`${API_ROUTES.MATCHES}/${id}`);
    
    if (!response.ok) {
      throw new Error('Error al obtener match');
    }
    
    return response.json();
  }

  /**
   * Registra el resultado de un match
   */
  static async createMatchResult(matchId: string, data: CreateMatchResultDTO): Promise<void> {
    const response = await fetch(`${API_ROUTES.MATCHES}/${matchId}/result`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Error al guardar resultado');
    }
  }

  /**
   * Obtiene información de estado del match
   */
  static getMatchStatusInfo(match: MatchWithDetails): MatchStatusInfo {
    if (match.matchResult) {
      return {
        text: '✅ Finalizado',
        icon: '✅',
        class: 'bg-gray-800 text-white border border-black',
      };
    } else if (match.status === 'confirmed') {
      return {
        text: 'Confirmado',
        icon: '🤝',
        class: 'bg-gray-300 text-black border border-black',
      };
    } else {
      return {
        text: 'Pendiente',
        icon: '⏳',
        class: 'bg-white text-black border border-black',
      };
    }
  }

  /**
   * Determina el ganador de un match
   */
  static getMatchWinner(team1Score: number, team2Score: number): 'team1' | 'team2' | 'draw' {
    if (team1Score > team2Score) return 'team1';
    if (team2Score > team1Score) return 'team2';
    return 'draw';
  }
}
