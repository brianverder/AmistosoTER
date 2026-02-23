/**
 * ============================================
 * RANKING REPOSITORY
 * ============================================
 *
 * Acceso a datos para la tabla rankings.
 * Permite obtener y actualizar el ranking global y por filtros.
 */

import { prisma } from '@/lib/prisma';

export class RankingRepository {
  /**
   * Obtener ranking con paginación y filtros
   */
  static async getLeaderboard(options: {
    season: string;
    footballType?: string;
    country?: string;
    page?: number;
    pageSize?: number;
  }) {
    const { season, footballType, country, page = 1, pageSize = 50 } = options;
    const offset = (page - 1) * pageSize;

    const [rankings, total] = await Promise.all([
      prisma.ranking.findMany({
        where: {
          season,
          ...(footballType ? { footballType } : {}),
          ...(country ? { country } : {}),
        },
        orderBy: [
          { points: 'desc' },
          { goalDiff: 'desc' },
          { goalsFor: 'desc' },
          { gamesPlayed: 'desc' },
        ],
        skip: offset,
        take: pageSize,
        include: {
          team: {
            select: {
              id: true,
              name: true,
              instagram: true,
              country: true,
              footballType: true,
            },
          },
          user: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      }),
      prisma.ranking.count({
        where: {
          season,
          ...(footballType ? { footballType } : {}),
          ...(country ? { country } : {}),
        },
      }),
    ]);

    return {
      rankings,
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
      season,
      footballType: footballType ?? null,
      country: country ?? null,
    };
  }

  /**
   * Posición de un equipo específico en la temporada
   */
  static async getTeamPosition(teamId: string, season: string, footballType?: string) {
    return prisma.ranking.findUnique({
      where: {
        teamId_season_footballType_country: {
          teamId,
          season,
          footballType: footballType ?? '',
          country: '',
        },
      },
      include: {
        team: { select: { id: true, name: true } },
      },
    });
  }

  /**
   * Obtener todas las temporadas disponibles
   */
  static async getSeasons() {
    const rows = await prisma.ranking.findMany({
      select: { season: true },
      distinct: ['season'],
      orderBy: { season: 'desc' },
    });
    return rows.map(r => r.season);
  }

  /**
   * Top N equipos de una temporada
   */
  static async getTopTeams(season: string, limit = 10, footballType?: string, country?: string) {
    return prisma.ranking.findMany({
      where: {
        season,
        ...(footballType ? { footballType } : {}),
        ...(country ? { country } : {}),
        position: { lte: limit },
      },
      orderBy: { position: 'asc' },
      take: limit,
      include: {
        team: {
          select: { id: true, name: true, instagram: true },
        },
      },
    });
  }

  /**
   * Upsert entrada de ranking (usar recalcRanking de lib/db.ts para bulk)
   */
  static async upsertEntry(data: {
    teamId: string;
    userId: string;
    season: string;
    footballType?: string | null;
    country?: string | null;
    position: number;
    points: number;
    gamesPlayed: number;
    gamesWon: number;
    gamesLost: number;
    gamesDrawn: number;
    goalsFor: number;
    goalsAgainst: number;
    goalDiff: number;
  }) {
    return prisma.ranking.upsert({
      where: {
        teamId_season_footballType_country: {
          teamId: data.teamId,
          season: data.season,
          footballType: data.footballType ?? '',
          country: data.country ?? '',
        },
      },
      create: data,
      update: {
        userId: data.userId,
        position: data.position,
        points: data.points,
        gamesPlayed: data.gamesPlayed,
        gamesWon: data.gamesWon,
        gamesLost: data.gamesLost,
        gamesDrawn: data.gamesDrawn,
        goalsFor: data.goalsFor,
        goalsAgainst: data.goalsAgainst,
        goalDiff: data.goalDiff,
      },
    });
  }
}
