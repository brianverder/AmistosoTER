/**
 * ============================================
 * MATCH RESULTS REPOSITORY
 * ============================================
 * 
 * Capa de acceso a datos para la entidad MatchResult.
 * Solo contiene queries SQL/Prisma, sin lógica de negocio.
 */

import { prisma } from '@/lib/prisma';
import { Prisma } from '@prisma/client';

export class MatchResultsRepository {
  /**
   * Busca un resultado por ID
   */
  static async findById(id: string) {
    return await prisma.matchResult.findUnique({
      where: { id },
      include: {
        match: {
          include: {
            team1: true,
            team2: true,
          },
        },
      },
    });
  }

  /**
   * Busca el resultado de un partido
   */
  static async findByMatchId(matchId: string) {
    return await prisma.matchResult.findUnique({
      where: { matchId },
      include: {
        match: {
          include: {
            team1: { select: { id: true, name: true } },
            team2: { select: { id: true, name: true } },
          },
        },
      },
    });
  }

  /**
   * Crea un nuevo resultado
   */
  static async create(data: {
    matchId: string;
    team1Score: number;
    team2Score: number;
    winnerId?: string | null;
  }) {
    return await prisma.matchResult.create({
      data,
      include: {
        match: {
          include: {
            team1: true,
            team2: true,
          },
        },
      },
    });
  }

  /**
   * Actualiza un resultado
   */
  static async update(id: string, data: Prisma.MatchResultUpdateInput) {
    return await prisma.matchResult.update({
      where: { id },
      data,
    });
  }

  /**
   * Elimina un resultado
   */
  static async delete(id: string) {
    return await prisma.matchResult.delete({
      where: { id },
    });
  }

  /**
   * Verifica si un partido ya tiene resultado
   */
  static async exists(matchId: string): Promise<boolean> {
    const count = await prisma.matchResult.count({
      where: { matchId },
    });
    return count > 0;
  }

  /**
   * Query RAW SQL: Obtiene resultados con mayor cantidad de goles
   */
  static async getHighScoringMatches(limit: number = 10) {
    return await prisma.$queryRaw`
      SELECT 
        mr.id,
        mr.team1_score,
        mr.team2_score,
        (mr.team1_score + mr.team2_score) as total_goals,
        t1.name as team1_name,
        t2.name as team2_name,
        m.final_date
      FROM match_results mr
      INNER JOIN matches m ON mr.match_id = m.id
      INNER JOIN teams t1 ON m.team1_id = t1.id
      INNER JOIN teams t2 ON m.team2_id = t2.id
      ORDER BY total_goals DESC, m.final_date DESC
      LIMIT ${limit}
    `;
  }

  /**
   * Query RAW SQL: Obtiene estadísticas de goles por equipo
   */
  static async getTeamScoringStats(teamId: string) {
    return await prisma.$queryRaw`
      SELECT 
        COUNT(*) as matches_played,
        SUM(CASE WHEN m.team1_id = ${teamId} THEN mr.team1_score ELSE mr.team2_score END) as total_goals_scored,
        SUM(CASE WHEN m.team1_id = ${teamId} THEN mr.team2_score ELSE mr.team1_score END) as total_goals_conceded,
        AVG(CASE WHEN m.team1_id = ${teamId} THEN mr.team1_score ELSE mr.team2_score END) as avg_goals_scored,
        AVG(CASE WHEN m.team1_id = ${teamId} THEN mr.team2_score ELSE mr.team1_score END) as avg_goals_conceded,
        MAX(CASE WHEN m.team1_id = ${teamId} THEN mr.team1_score ELSE mr.team2_score END) as max_goals_in_match
      FROM match_results mr
      INNER JOIN matches m ON mr.match_id = m.id
      WHERE m.team1_id = ${teamId} OR m.team2_id = ${teamId}
    `;
  }
}
