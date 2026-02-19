/**
 * ============================================
 * MATCH REQUESTS REPOSITORY
 * ============================================
 * 
 * Capa de acceso a datos para la entidad MatchRequest.
 * Solo contiene queries SQL/Prisma, sin lógica de negocio.
 */

import { prisma } from '@/lib/prisma';
import { Prisma } from '@prisma/client';

export class MatchRequestsRepository {
  /**
   * Busca una solicitud por ID
   */
  static async findById(id: string) {
    return await prisma.matchRequest.findUnique({
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
        team: true,
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
   * Busca solicitudes de un usuario
   */
  static async findByUserId(
    userId: string,
    status?: string,
    filters?: { footballType?: string; country?: string }
  ) {
    const where: Prisma.MatchRequestWhereInput = { userId };

    if (status) {
      where.status = status;
    }

    if (filters?.footballType) {
      where.footballType = filters.footballType;
    }

    if (filters?.country) {
      where.country = {
        equals: filters.country,
      };
    }

    return await prisma.matchRequest.findMany({
      where,
      include: {
        team: true,
        match: {
          include: {
            team1: { select: { name: true } },
            team2: { select: { name: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Busca solicitudes de un equipo
   */
  static async findByTeamId(teamId: string) {
    return await prisma.matchRequest.findMany({
      where: { teamId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
        match: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Busca solicitudes activas (disponibles)
   */
  static async findActive(filters?: {
    excludeUserId?: string;
    footballType?: string;
    country?: string;
    limit?: number;
    offset?: number;
  }) {
    const where: Prisma.MatchRequestWhereInput = {
      status: 'active',
    };

    if (filters?.excludeUserId) {
      where.userId = { not: filters.excludeUserId };
    }

    if (filters?.footballType) {
      where.footballType = filters.footballType;
    }

    if (filters?.country) {
      where.country = {
        equals: filters.country,
      };
    }

    return await prisma.matchRequest.findMany({
      where,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
        team: true,
      },
      orderBy: { createdAt: 'desc' },
      take: filters?.limit,
      skip: filters?.offset,
    });
  }

  /**
   * Cuenta solicitudes con filtros
   */
  static async count(filters?: {
    userId?: string;
    status?: string;
    footballType?: string;
    country?: string;
  }) {
    const where: Prisma.MatchRequestWhereInput = {};

    if (filters?.userId) {
      where.userId = filters.userId;
    }

    if (filters?.status) {
      where.status = filters.status;
    }

    if (filters?.footballType) {
      where.footballType = filters.footballType;
    }

    if (filters?.country) {
      where.country = {
        equals: filters.country,
      };
    }

    return await prisma.matchRequest.count({ where });
  }

  /**
   * Crea una nueva solicitud
   */
  static async create(data: {
    userId: string;
    teamId: string;
    footballType: string;
    fieldName?: string;
    fieldAddress: string;
    country?: string;
    state?: string;
    date?: Date;
    fieldPrice?: number;
    league?: string;
    description?: string;
  }) {
    return await prisma.matchRequest.create({
      data: {
        userId: data.userId,
        teamId: data.teamId,
        footballType: data.footballType,
        fieldName: data.fieldName,
        fieldAddress: data.fieldAddress,
        country: data.country,
        state: data.state,
        matchDate: data.date,
        fieldPrice: data.fieldPrice,
        league: data.league,
        description: data.description,
        status: 'active',
      },
      include: {
        team: true,
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
   * Actualiza una solicitud
   */
  static async update(id: string, data: Prisma.MatchRequestUpdateInput) {
    return await prisma.matchRequest.update({
      where: { id },
      data,
    });
  }

  /**
   * Actualiza el estado de una solicitud
   */
  static async updateStatus(id: string, status: string) {
    return await prisma.matchRequest.update({
      where: { id },
      data: { status },
    });
  }

  /**
   * Elimina una solicitud
   */
  static async delete(id: string) {
    return await prisma.matchRequest.delete({
      where: { id },
    });
  }

  /**
   * Verifica si una solicitud pertenece a un usuario
   */
  static async belongsToUser(requestId: string, userId: string): Promise<boolean> {
    const request = await prisma.matchRequest.findUnique({
      where: { id: requestId },
      select: { userId: true },
    });
    return request?.userId === userId;
  }

  /**
   * Verifica si una solicitud puede ser eliminada
   */
  static async canBeDeleted(requestId: string): Promise<boolean> {
    const request = await prisma.matchRequest.findUnique({
      where: { id: requestId },
      select: { status: true },
    });
    return request?.status !== 'matched';
  }

  /**
   * Query RAW SQL: Busca solicitudes cercanas por ubicación (texto)
   * ✅ SEGURO: Usa Prisma parameterization y CONCAT para construir pattern
   */
  static async searchByLocation(location: string, limit: number = 20) {
    // Sanitizar input: remover caracteres especiales de SQL
    const sanitized = location.replace(/[%_\\]/g, '\\$&'); // Escapar %, _, \
    
    return await prisma.$queryRaw`
      SELECT 
        mr.id,
        mr.field_address,
        mr.field_name,
        mr.football_type,
        mr.status,
        t.name as team_name,
        u.name as user_name,
        u.phone as user_phone
      FROM match_requests mr
      INNER JOIN teams t ON mr.team_id = t.id
      INNER JOIN users u ON mr.user_id = u.id
      WHERE mr.status = 'ACTIVE'
        AND (
          mr.field_address LIKE CONCAT('%', ${sanitized}, '%')
          OR mr.field_name LIKE CONCAT('%', ${sanitized}, '%')
        )
      ORDER BY mr.created_at DESC
      LIMIT ${limit}
    `;
  }

  /**
   * Query RAW SQL: Obtiene solicitudes con mejor disponibilidad
   */
  static async findWithAvailability(footballType?: string) {
    const typeFilter = footballType 
      ? Prisma.sql`AND mr.football_type = ${footballType}` 
      : Prisma.sql``;

    return await prisma.$queryRaw`
      SELECT 
        mr.id,
        mr.football_type,
        mr.field_address,
        mr.field_name,
        mr.date,
        mr.time,
        t.name as team_name,
        t.total_games,
        u.name as user_name,
        u.phone as user_phone,
        DATEDIFF(mr.date, NOW()) as days_until_match
      FROM match_requests mr
      INNER JOIN teams t ON mr.team_id = t.id
      INNER JOIN users u ON mr.user_id = u.id
      WHERE mr.status = 'active'
        AND mr.date >= CURDATE()
        ${typeFilter}
      ORDER BY mr.date ASC
      LIMIT 50
    `;
  }

  /**
   * Query RAW SQL: FULLTEXT search en solicitudes
   * ⚠️ Requiere índice FULLTEXT creado en schema:
   *    @@fulltext([fieldAddress, description], name: "idx_request_fulltext")
   * ✅ SEGURO: El parámetro ya es escapado por Prisma en MATCH...AGAINST
   */
  static async fullTextSearch(searchTerm: string, limit: number = 20) {
    // FULLTEXT search solo funciona en MySQL/MariaDB con índice específico
    // El término es automáticamente escapado por Prisma
    return await prisma.$queryRaw`
      SELECT 
        mr.id,
        mr.field_address,
        mr.field_name,
        mr.description,
        mr.football_type,
        t.name as team_name,
        u.name as user_name,
        MATCH(mr.field_address, mr.description) 
          AGAINST(${searchTerm} IN NATURAL LANGUAGE MODE) as relevance
      FROM match_requests mr
      INNER JOIN teams t ON mr.team_id = t.id
      INNER JOIN users u ON mr.user_id = u.id
      WHERE mr.status = 'ACTIVE'
        AND MATCH(mr.field_address, mr.description) 
          AGAINST(${searchTerm} IN NATURAL LANGUAGE MODE)
      ORDER BY relevance DESC
      LIMIT ${limit}
    `;
  }
}
