/**
 * ============================================
 * TEAMS SERVICE (Server-Side)
 * ============================================
 * 
 * Capa de lógica de negocio para equipos.
 * Usa los repositorios y aplica validaciones/reglas de negocio.
 */

import { TeamsRepository } from '@/lib/repositories';
import { ValidationError, NotFoundError, UnauthorizedError } from '@/lib/errors';

export class TeamsService {
  /**
   * Obtiene todos los equipos de un usuario
   */
  static async getUserTeams(userId: string) {
    if (!userId) {
      throw new ValidationError('User ID es requerido');
    }

    return await TeamsRepository.findByUserId(userId);
  }

  /**
   * Obtiene un equipo por ID con autorización
   */
  static async getTeamById(teamId: string, userId: string) {
    if (!teamId) {
      throw new ValidationError('Team ID es requerido');
    }

    const team = await TeamsRepository.findById(teamId);

    if (!team) {
      throw new NotFoundError('Equipo no encontrado');
    }

    // Verificar autorización
    if (team.userId !== userId) {
      throw new UnauthorizedError('No tienes acceso a este equipo');
    }

    return team;
  }

  /**
   * Busca equipos con filtros
   */
  static async searchTeams(filters: {
    userId?: string;
    search?: string;
    sortBy?: 'name' | 'createdAt' | 'totalGames' | 'gamesWon';
    sortOrder?: 'asc' | 'desc';
    page?: number;
    pageSize?: number;
  }) {
    const page = filters.page || 1;
    const pageSize = Math.min(filters.pageSize || 20, 100); // Máximo 100
    const offset = (page - 1) * pageSize;

    const [teams, total] = await Promise.all([
      TeamsRepository.findMany({
        ...filters,
        limit: pageSize,
        offset,
      }),
      TeamsRepository.count({
        userId: filters.userId,
        search: filters.search,
      }),
    ]);

    return {
      teams,
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
    };
  }

  /**
   * Crea un nuevo equipo
   */
  static async createTeam(data: { name: string; userId: string; instagram?: string }) {
    // Validaciones
    if (!data.name || data.name.trim().length === 0) {
      throw new ValidationError('El nombre del equipo es requerido');
    }

    if (data.name.length > 100) {
      throw new ValidationError('El nombre del equipo no puede exceder 100 caracteres');
    }

    if (!data.userId) {
      throw new ValidationError('User ID es requerido');
    }

    // Sanitizar nombre
    const sanitizedName = data.name.trim();
    const sanitizedInstagram = data.instagram?.trim() || undefined;

    if (sanitizedInstagram && sanitizedInstagram.length > 100) {
      throw new ValidationError('El Instagram no puede exceder 100 caracteres');
    }

    return await TeamsRepository.create({
      name: sanitizedName,
      userId: data.userId,
      instagram: sanitizedInstagram,
    });
  }

  /**
   * Actualiza un equipo
   */
  static async updateTeam(
    teamId: string,
    userId: string,
    data: { name?: string }
  ) {
    // Verificar que el equipo existe y pertenece al usuario
    const exists = await TeamsRepository.belongsToUser(teamId, userId);
    if (!exists) {
      throw new UnauthorizedError('No tienes permiso para actualizar este equipo');
    }

    // Validar nombre si se proporciona
    if (data.name !== undefined) {
      if (data.name.trim().length === 0) {
        throw new ValidationError('El nombre del equipo no puede estar vacío');
      }

      if (data.name.length > 100) {
        throw new ValidationError('El nombre del equipo no puede exceder 100 caracteres');
      }
    }

    const updateData: any = {};
    if (data.name) {
      updateData.name = data.name.trim();
    }

    return await TeamsRepository.update(teamId, updateData);
  }

  /**
   * Elimina un equipo
   */
  static async deleteTeam(teamId: string, userId: string) {
    // Verificar que el equipo existe y pertenece al usuario
    const exists = await TeamsRepository.belongsToUser(teamId, userId);
    if (!exists) {
      throw new UnauthorizedError('No tienes permiso para eliminar este equipo');
    }

    // TODO: Verificar que no tenga partidos activos/pendientes
    // Si tiene partidos, no permitir eliminación

    return await TeamsRepository.delete(teamId);
  }

  /**
   * Obtiene estadísticas detalladas de un equipo
   */
  static async getTeamStats(teamId: string, userId: string) {
    // Verificar acceso
    const exists = await TeamsRepository.belongsToUser(teamId, userId);
    if (!exists) {
      throw new UnauthorizedError('No tienes acceso a este equipo');
    }

    const stats = await TeamsRepository.getDetailedStats(teamId);

    if (!stats) {
      throw new NotFoundError('Equipo no encontrado');
    }

    return stats;
  }

  /**
   * Calcula el win rate de un equipo
   */
  static calculateWinRate(team: {
    gamesWon: number;
    totalGames: number;
  }): number {
    if (team.totalGames === 0) return 0;
    return Math.round((team.gamesWon / team.totalGames) * 10000) / 100;
  }

  /**
   * Obtiene el ranking de equipos por victorias
   */
  static async getTopTeams(limit: number = 10) {
    return await TeamsRepository.getTopTeamsByWins(limit);
  }

  /**
   * Busca equipos por nombre (texto completo)
   */
  static async searchByName(searchTerm: string, limit: number = 20) {
    if (!searchTerm || searchTerm.trim().length === 0) {
      throw new ValidationError('Término de búsqueda requerido');
    }

    if (searchTerm.length < 2) {
      throw new ValidationError('El término de búsqueda debe tener al menos 2 caracteres');
    }

    return await TeamsRepository.searchByName(searchTerm.trim(), limit);
  }

  /**
   * Actualiza las estadísticas de un equipo después de un partido
   */
  static async updateStatsAfterMatch(
    teamId: string,
    result: 'win' | 'loss' | 'draw'
  ) {
    const increment: any = {
      totalGames: 1,
    };

    switch (result) {
      case 'win':
        increment.gamesWon = 1;
        break;
      case 'loss':
        increment.gamesLost = 1;
        break;
      case 'draw':
        increment.gamesDraw = 1;
        break;
    }

    return await TeamsRepository.incrementStats(teamId, increment);
  }
}
