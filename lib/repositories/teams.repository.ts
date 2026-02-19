/**
 * ============================================
 * TEAMS REPOSITORY
 * ============================================
 * 
 * Capa de acceso a datos para la entidad Team.
 * Solo contiene queries SQL/Prisma, sin lógica de negocio.
 */

import { prisma } from '@/lib/prisma';
import { Prisma } from '@prisma/client';

export class TeamsRepository {
  /**
   * Busca un equipo por ID
   */
  static async findById(id: string) {
    return await prisma.team.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
      },
    });
  }

  /**
   * Busca todos los equipos de un usuario
   */
  static async findByUserId(userId: string) {
    return await prisma.team.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Busca equipos con filtros
   */
  static async findMany(filters?: {
    userId?: string;
    search?: string;
    sortBy?: 'name' | 'createdAt' | 'totalGames' | 'gamesWon';
    sortOrder?: 'asc' | 'desc';
    limit?: number;
    offset?: number;
  }) {
    const where: Prisma.TeamWhereInput = {};

    if (filters?.userId) {
      where.userId = filters.userId;
    }

    if (filters?.search) {
      where.name = {
        contains: filters.search,
      };
    }

    const orderBy: Prisma.TeamOrderByWithRelationInput = {};
    if (filters?.sortBy) {
      orderBy[filters.sortBy] = filters.sortOrder || 'desc';
    } else {
      orderBy.createdAt = 'desc';
    }

    return await prisma.team.findMany({
      where,
      orderBy,
      take: filters?.limit,
      skip: filters?.offset,
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });
  }

  /**
   * Cuenta equipos con filtros
   */
  static async count(filters?: { userId?: string; search?: string }) {
    const where: Prisma.TeamWhereInput = {};

    if (filters?.userId) {
      where.userId = filters.userId;
    }

    if (filters?.search) {
      where.name = {
        contains: filters.search,
      };
    }

    return await prisma.team.count({ where });
  }

  /**
   * Crea un nuevo equipo
   */
  static async create(data: { name: string; userId: string; instagram?: string }) {
    return await prisma.team.create({
      data: {
        name: data.name,
        userId: data.userId,
        instagram: data.instagram,
        gamesWon: 0,
        gamesLost: 0,
        gamesDrawn: 0,
        totalGames: 0,
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });
  }

  /**
   * Actualiza un equipo
   */
  static async update(id: string, data: Prisma.TeamUpdateInput) {
    return await prisma.team.update({
      where: { id },
      data,
    });
  }

  /**
   * Actualiza estadísticas de un equipo
   */
  static async updateStats(
    id: string,
    stats: {
      gamesWon?: number;
      gamesLost?: number;
      gamesDrawn?: number;
      totalGames?: number;
    }
  ) {
    return await prisma.team.update({
      where: { id },
      data: stats,
    });
  }

  /**
   * Incrementa estadísticas de un equipo (atómico)
   */
  static async incrementStats(
    id: string,
    increment: {
      gamesWon?: number;
      gamesLost?: number;
      gamesDrawn?: number;
      totalGames?: number;
    }
  ) {
    return await prisma.team.update({
      where: { id },
      data: {
        gamesWon: { increment: increment.gamesWon || 0 },
        gamesLost: { increment: increment.gamesLost || 0 },
        gamesDrawn: { increment: increment.gamesDrawn || 0 },
        totalGames: { increment: increment.totalGames || 0 },
      },
    });
  }

  /**
   * Elimina un equipo
   */
  static async delete(id: string) {
    return await prisma.team.delete({
      where: { id },
    });
  }

  /**
   * Verifica si un equipo pertenece a un usuario
   */
  static async belongsToUser(teamId: string, userId: string): Promise<boolean> {
    const team = await prisma.team.findUnique({
      where: { id: teamId },
      select: { userId: true },
    });
    return team?.userId === userId;
  }

  /**
   * Obtiene estadísticas detalladas de un equipo
   */
  static async getDetailedStats(teamId: string) {
    const team = await prisma.team.findUnique({
      where: { id: teamId },
      select: {
        id: true,
        name: true,
        gamesWon: true,
        gamesLost: true,
        gamesDrawn: true,
        totalGames: true,
      },
    });

    if (!team) return null;

    // Calcular win rate
    const winRate = team.totalGames > 0 
      ? (team.gamesWon / team.totalGames) * 100 
      : 0;

    // Obtener últimos partidos
    const recentMatches = await prisma.match.findMany({
      where: {
        OR: [{ team1Id: teamId }, { team2Id: teamId }],
        status: 'completed',
      },
      include: {
        matchResult: true,
        team1: { select: { name: true } },
        team2: { select: { name: true } },
      },
      orderBy: { finalDate: 'desc' },
      take: 5,
    });

    return {
      ...team,
      winRate: Math.round(winRate * 100) / 100,
      recentMatches,
    };
  }

  /**
   * Query RAW SQL: Obtiene ranking de equipos por victorias
   */
  static async getTopTeamsByWins(limit: number = 10) {
    return await prisma.$queryRaw`
      SELECT 
        t.id,
        t.name,
        t.games_won,
        t.games_lost,
        t.games_draw,
        t.total_games,
        u.name as owner_name,
        CASE 
          WHEN t.total_games > 0 
          THEN ROUND((t.games_won * 100.0 / t.total_games), 2)
          ELSE 0 
        END as win_rate
      FROM teams t
      INNER JOIN users u ON t.user_id = u.id
      WHERE t.total_games >= 3
      ORDER BY t.games_won DESC, win_rate DESC
      LIMIT ${limit}
    `;
  }

  /**
   * Query RAW SQL: Busca equipos con texto completo (LIKE search)
   * ✅ SEGURO: Usa Prisma parameterization y CONCAT para construir pattern
   */
  static async searchByName(searchTerm: string, limit: number = 20) {
    // Sanitizar input: remover caracteres especiales de SQL
    const sanitized = searchTerm.replace(/[%_\\]/g, '\\$&'); // Escapar %, _, \
    
    return await prisma.$queryRaw`
      SELECT 
        t.id,
        t.name,
        t.total_games,
        t.games_won,
        u.name as owner_name
      FROM teams t
      INNER JOIN users u ON t.user_id = u.id
      WHERE t.name LIKE CONCAT('%', ${sanitized}, '%')
      ORDER BY t.total_games DESC
      LIMIT ${limit}
    `;
  }
}
