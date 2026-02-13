/**
 * ============================================
 * MATCHES REPOSITORY
 * ============================================
 * 
 * Capa de acceso a datos para la entidad Match.
 * Solo contiene queries SQL/Prisma, sin lógica de negocio.
 */

import { prisma } from '@/lib/prisma';
import { Prisma } from '@prisma/client';

export class MatchesRepository {
  /**
   * Busca un partido por ID
   */
  static async findById(id: string) {
    return await prisma.match.findUnique({
      where: { id },
      include: {
        team1: {
          include: {
            user: { select: { id: true, name: true, phone: true } },
          },
        },
        team2: {
          include: {
            user: { select: { id: true, name: true, phone: true } },
          },
        },
        matchRequest: {
          select: {
            footballType: true,
            fieldAddress: true,
          },
        },
        matchResult: true,
      },
    });
  }

  /**
   * Busca partidos de un usuario
   */
  static async findByUserId(userId: string, status?: string) {
    const where: Prisma.MatchWhereInput = {
      OR: [{ userId1: userId }, { userId2: userId }],
    };

    if (status) {
      where.status = status;
    }

    return await prisma.match.findMany({
      where,
      include: {
        team1: true,
        team2: true,
        matchRequest: {
          select: {
            footballType: true,
            fieldAddress: true,
          },
        },
        matchResult: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Busca partidos de un equipo
   */
  static async findByTeamId(teamId: string) {
    return await prisma.match.findMany({
      where: {
        OR: [{ team1Id: teamId }, { team2Id: teamId }],
      },
      include: {
        team1: true,
        team2: true,
        matchResult: true,
      },
      orderBy: { finalDate: 'desc' },
    });
  }

  /**
   * Busca partidos completados
   */
  static async findCompleted(filters?: {
    userId?: string;
    teamId?: string;
    limit?: number;
    offset?: number;
  }) {
    const where: Prisma.MatchWhereInput = {
      status: 'completed',
    };

    if (filters?.userId) {
      where.OR = [{ userId1: filters.userId }, { userId2: filters.userId }];
    }

    if (filters?.teamId) {
      where.OR = [{ team1Id: filters.teamId }, { team2Id: filters.teamId }];
    }

    return await prisma.match.findMany({
      where,
      include: {
        team1: { select: { id: true, name: true } },
        team2: { select: { id: true, name: true } },
        matchResult: true,
      },
      orderBy: { finalDate: 'desc' },
      take: filters?.limit,
      skip: filters?.offset,
    });
  }

  /**
   * Busca partidos próximos
   */
  static async findUpcoming(userId?: string, limit: number = 10) {
    const where: Prisma.MatchWhereInput = {
      status: { in: ['pending', 'confirmed'] },
      finalDate: { gte: new Date() },
    };

    if (userId) {
      where.OR = [{ userId1: userId }, { userId2: userId }];
    }

    return await prisma.match.findMany({
      where,
      include: {
        team1: { select: { name: true } },
        team2: { select: { name: true } },
      },
      orderBy: { finalDate: 'asc' },
      take: limit,
    });
  }

  /**
   * Crea un nuevo partido
   */
  static async create(data: {
    matchRequestId: string;
    team1Id: string;
    team2Id: string;
    userId1: string;
    userId2: string;
    status?: string;
    finalDate?: Date;
    finalAddress?: string;
    finalPrice?: number;
  }) {
    return await prisma.match.create({
      data: {
        matchRequestId: data.matchRequestId,
        team1Id: data.team1Id,
        team2Id: data.team2Id,
        userId1: data.userId1,
        userId2: data.userId2,
        status: data.status || 'pending',
        finalDate: data.finalDate,
        finalAddress: data.finalAddress,
        finalPrice: data.finalPrice,
      },
      include: {
        team1: true,
        team2: true,
      },
    });
  }

  /**
   * Actualiza un partido
   */
  static async update(id: string, data: Prisma.MatchUpdateInput) {
    return await prisma.match.update({
      where: { id },
      data,
    });
  }

  /**
   * Actualiza el estado de un partido
   */
  static async updateStatus(id: string, status: string) {
    return await prisma.match.update({
      where: { id },
      data: { status },
    });
  }

  /**
   * Elimina un partido
   */
  static async delete(id: string) {
    return await prisma.match.delete({
      where: { id },
    });
  }

  /**
   * Verifica si un usuario participa en un partido
   */
  static async userParticipates(matchId: string, userId: string): Promise<boolean> {
    const match = await prisma.match.findUnique({
      where: { id: matchId },
      select: { userId1: true, userId2: true },
    });
    return match?.userId1 === userId || match?.userId2 === userId;
  }

  /**
   * Cuenta partidos con filtros
   */
  static async count(filters?: {
    userId?: string;
    teamId?: string;
    status?: string;
  }) {
    const where: Prisma.MatchWhereInput = {};

    if (filters?.userId) {
      where.OR = [{ userId1: filters.userId }, { userId2: filters.userId }];
    }

    if (filters?.teamId) {
      where.OR = [{ team1Id: filters.teamId }, { team2Id: filters.teamId }];
    }

    if (filters?.status) {
      where.status = filters.status;
    }

    return await prisma.match.count({ where });
  }

  /**
   * Query RAW SQL: Obtiene historial de enfrentamientos entre dos equipos
   */
  static async getHeadToHead(team1Id: string, team2Id: string) {
    return await prisma.$queryRaw`
      SELECT 
        m.id,
        m.final_date,
        m.status,
        t1.name as team1_name,
        t2.name as team2_name,
        mr.team1_score,
        mr.team2_score,
        CASE 
          WHEN mr.winner_id = ${team1Id} THEN 'team1'
          WHEN mr.winner_id = ${team2Id} THEN 'team2'
          ELSE 'draw'
        END as result
      FROM matches m
      INNER JOIN teams t1 ON m.team1_id = t1.id
      INNER JOIN teams t2 ON m.team2_id = t2.id
      LEFT JOIN match_results mr ON m.id = mr.match_id
      WHERE (
        (m.team1_id = ${team1Id} AND m.team2_id = ${team2Id})
        OR (m.team1_id = ${team2Id} AND m.team2_id = ${team1Id})
      )
      AND m.status = 'completed'
      ORDER BY m.final_date DESC
    `;
  }

  /**
   * Query RAW SQL: Obtiene estadísticas de partidos por mes
   */
  static async getMonthlyStats(userId: string, year: number) {
    return await prisma.$queryRaw`
      SELECT 
        MONTH(m.final_date) as month,
        COUNT(*) as total_matches,
        SUM(CASE WHEN m.status = 'completed' THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN m.status = 'cancelled' THEN 1 ELSE 0 END) as cancelled
      FROM matches m
      WHERE (m.user_id1 = ${userId} OR m.user_id2 = ${userId})
        AND YEAR(m.final_date) = ${year}
      GROUP BY MONTH(m.final_date)
      ORDER BY month
    `;
  }

  /**
   * Query RAW SQL: Obtiene partidos con resultados más reñidos
   */
  static async getClosestMatches(limit: number = 10) {
    return await prisma.$queryRaw`
      SELECT 
        m.id,
        m.final_date,
        t1.name as team1_name,
        t2.name as team2_name,
        mr.team1_score,
        mr.team2_score,
        ABS(mr.team1_score - mr.team2_score) as score_difference
      FROM matches m
      INNER JOIN teams t1 ON m.team1_id = t1.id
      INNER JOIN teams t2 ON m.team2_id = t2.id
      INNER JOIN match_results mr ON m.id = mr.match_id
      WHERE m.status = 'completed'
      ORDER BY score_difference ASC, m.final_date DESC
      LIMIT ${limit}
    `;
  }
}
