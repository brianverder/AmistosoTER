/**
 * ============================================
 * USERS REPOSITORY
 * ============================================
 * 
 * Capa de acceso a datos para la entidad User.
 * Solo contiene queries SQL/Prisma, sin lógica de negocio.
 */

import { prisma } from '@/lib/prisma';
import { Prisma } from '@prisma/client';

export class UsersRepository {
  /**
   * Busca un usuario por ID
   */
  static async findById(id: string) {
    return await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        createdAt: true,
        updatedAt: true,
        // NO incluir password
      },
    });
  }

  /**
   * Busca un usuario por email (incluye password para autenticación)
   */
  static async findByEmail(email: string) {
    return await prisma.user.findUnique({
      where: { email },
    });
  }

  /**
   * Busca un usuario por email sin password (público)
   */
  static async findByEmailPublic(email: string) {
    return await prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        createdAt: true,
      },
    });
  }

  /**
   * Crea un nuevo usuario
   */
  static async create(data: {
    email: string;
    password: string;
    name: string;
    phone?: string;
  }) {
    return await prisma.user.create({
      data,
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        createdAt: true,
      },
    });
  }

  /**
   * Actualiza un usuario
   */
  static async update(id: string, data: Prisma.UserUpdateInput) {
    return await prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        updatedAt: true,
      },
    });
  }

  /**
   * Elimina un usuario
   */
  static async delete(id: string) {
    return await prisma.user.delete({
      where: { id },
    });
  }

  /**
   * Verifica si un email ya existe
   */
  static async emailExists(email: string): Promise<boolean> {
    const count = await prisma.user.count({
      where: { email },
    });
    return count > 0;
  }

  /**
   * Obtiene estadísticas de un usuario
   */
  static async getUserStats(userId: string) {
    const [teamsCount, requestsCount, matchesCount] = await Promise.all([
      prisma.team.count({ where: { userId } }),
      prisma.matchRequest.count({ where: { userId } }),
      prisma.match.count({
        where: {
          OR: [{ userId1: userId }, { userId2: userId }],
        },
      }),
    ]);

    return {
      teamsCount,
      requestsCount,
      matchesCount,
    };
  }

  /**
   * Query RAW SQL: Obtiene usuarios con más equipos
   */
  static async getUsersWithMostTeams(limit: number = 10) {
    return await prisma.$queryRaw`
      SELECT 
        u.id,
        u.name,
        u.email,
        COUNT(t.id) as teams_count
      FROM users u
      LEFT JOIN teams t ON t.user_id = u.id
      GROUP BY u.id, u.name, u.email
      ORDER BY teams_count DESC
      LIMIT ${limit}
    `;
  }
}
