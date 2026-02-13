/**
 * ============================================
 * MATCHES SERVICE (Server-Side)
 * ============================================
 * 
 * Capa de lógica de negocio para partidos.
 * Usa los repositorios y aplica validaciones/reglas de negocio.
 */

import {
  MatchesRepository,
  MatchResultsRepository,
  MatchRequestsRepository,
  TeamsRepository,
} from '@/lib/repositories';
import { ValidationError, NotFoundError, UnauthorizedError, BusinessRuleError } from '@/lib/errors';
import { TeamsService } from './teams.service';
import { prisma } from '@/lib/prisma';

export class MatchesService {
  /**
   * Obtiene partidos de un usuario
   */
  static async getUserMatches(userId: string, status?: string) {
    if (!userId) {
      throw new ValidationError('User ID es requerido');
    }

    return await MatchesRepository.findByUserId(userId, status);
  }

  /**
   * Obtiene un partido por ID
   */
  static async getMatchById(matchId: string, userId: string) {
    if (!matchId) {
      throw new ValidationError('Match ID es requerido');
    }

    const match = await MatchesRepository.findById(matchId);

    if (!match) {
      throw new NotFoundError('Partido no encontrado');
    }

    // Verificar que el usuario participa en el partido
    if (match.userId1 !== userId && match.userId2 !== userId) {
      throw new UnauthorizedError('No tienes acceso a este partido');
    }

    return match;
  }

  /**
   * Obtiene partidos completados
   */
  static async getCompletedMatches(filters?: {
    userId?: string;
    teamId?: string;
    page?: number;
    pageSize?: number;
  }) {
    const page = filters?.page || 1;
    const pageSize = Math.min(filters?.pageSize || 20, 100);
    const offset = (page - 1) * pageSize;

    const [matches, total] = await Promise.all([
      MatchesRepository.findCompleted({
        userId: filters?.userId,
        teamId: filters?.teamId,
        limit: pageSize,
        offset,
      }),
      MatchesRepository.count({
        userId: filters?.userId,
        teamId: filters?.teamId,
        status: 'completed',
      }),
    ]);

    return {
      matches,
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
    };
  }

  /**
   * Obtiene partidos próximos
   */
  static async getUpcomingMatches(userId?: string, limit: number = 10) {
    return await MatchesRepository.findUpcoming(userId, limit);
  }

  /**
   * Crea un partido a partir de una solicitud (accept request)
   */
  static async createMatchFromRequest(
    requestId: string,
    acceptingUserId: string,
    acceptingTeamId: string
  ) {
    // 1. Obtener la solicitud
    const request = await MatchRequestsRepository.findById(requestId);

    if (!request) {
      throw new NotFoundError('Solicitud no encontrada');
    }

    // 2. Verificar que la solicitud está activa
    if (request.status !== 'active') {
      throw new BusinessRuleError('La solicitud no está disponible');
    }

    // 3. Verificar que el usuario que acepta no es el dueño de la solicitud
    if (request.userId === acceptingUserId) {
      throw new BusinessRuleError('No puedes aceptar tu propia solicitud');
    }

    // 4. Verificar que el equipo pertenece al usuario que acepta
    const teamBelongs = await TeamsRepository.belongsToUser(
      acceptingTeamId,
      acceptingUserId
    );

    if (!teamBelongs) {
      throw new UnauthorizedError('El equipo no te pertenece');
    }

    // 5. Crear el partido usando una transacción
    return await prisma.$transaction(async (tx) => {
      // Crear match
      const match = await tx.match.create({
        data: {
          matchRequestId: requestId,
          team1Id: request.teamId,
          team2Id: acceptingTeamId,
          userId1: request.userId,
          userId2: acceptingUserId,
          status: 'pending',
          finalDate: request.matchDate,
          finalAddress: request.fieldAddress,
        },
        include: {
          team1: true,
          team2: true,
        },
      });

      // Actualizar solicitud a 'matched'
      await tx.matchRequest.update({
        where: { id: requestId },
        data: { status: 'matched' },
      });

      return match;
    });
  }

  /**
   * Confirma un partido (establece fecha final)
   */
  static async confirmMatch(
    matchId: string,
    userId: string,
    finalDate: Date
  ) {
    // Verificar que el usuario participa
    const participates = await MatchesRepository.userParticipates(matchId, userId);
    if (!participates) {
      throw new UnauthorizedError('No tienes acceso a este partido');
    }

    // Verificar que el partido está pendiente
    const match = await MatchesRepository.findById(matchId);
    if (match?.status !== 'pending') {
      throw new BusinessRuleError('Solo se pueden confirmar partidos pendientes');
    }

    // Validar fecha
    if (isNaN(finalDate.getTime())) {
      throw new ValidationError('Fecha inválida');
    }

    return await MatchesRepository.update(matchId, {
      status: 'confirmed',
      finalDate,
    });
  }

  /**
   * Registra el resultado de un partido
   */
  static async registerResult(
    matchId: string,
    userId: string,
    data: {
      team1Score: number;
      team2Score: number;
    }
  ) {
    // 1. Verificar que el usuario participa
    const participates = await MatchesRepository.userParticipates(matchId, userId);
    if (!participates) {
      throw new UnauthorizedError('No tienes acceso a este partido');
    }

    // 2. Obtener el partido
    const match = await MatchesRepository.findById(matchId);
    if (!match) {
      throw new NotFoundError('Partido no encontrado');
    }

    // 3. Verificar que no tenga resultado ya
    const existingResult = await MatchResultsRepository.exists(matchId);
    if (existingResult) {
      throw new BusinessRuleError('El partido ya tiene un resultado registrado');
    }

    // 4. Validar marcadores
    if (
      typeof data.team1Score !== 'number' ||
      typeof data.team2Score !== 'number' ||
      data.team1Score < 0 ||
      data.team2Score < 0 ||
      data.team1Score > 99 ||
      data.team2Score > 99
    ) {
      throw new ValidationError('Marcadores inválidos (0-99)');
    }

    // 5. Determinar ganador
    let winnerId: string | null = null;
    let team1Result: 'win' | 'loss' | 'draw' = 'draw';
    let team2Result: 'win' | 'loss' | 'draw' = 'draw';

    if (data.team1Score > data.team2Score) {
      winnerId = match.team1Id;
      team1Result = 'win';
      team2Result = 'loss';
    } else if (data.team2Score > data.team1Score) {
      winnerId = match.team2Id;
      team1Result = 'loss';
      team2Result = 'win';
    }

    // 6. Crear resultado y actualizar estadísticas (transacción)
    return await prisma.$transaction(async (tx) => {
      // Crear resultado
      const result = await tx.matchResult.create({
        data: {
          matchId,
          team1Score: data.team1Score,
          team2Score: data.team2Score,
          winnerId,
        },
      });

      // Actualizar estado del partido
      await tx.match.update({
        where: { id: matchId },
        data: { status: 'completed' },
      });

      // Actualizar estadísticas de equipos
      await Promise.all([
        TeamsService.updateStatsAfterMatch(match.team1Id, team1Result),
        TeamsService.updateStatsAfterMatch(match.team2Id, team2Result),
      ]);

      return result;
    });
  }

  /**
   * Cancela un partido
   */
  static async cancelMatch(matchId: string, userId: string) {
    // Verificar que el usuario participa
    const participates = await MatchesRepository.userParticipates(matchId, userId);
    if (!participates) {
      throw new UnauthorizedError('No tienes acceso a este partido');
    }

    // Verificar que el partido no está completado
    const match = await MatchesRepository.findById(matchId);
    if (match?.status === 'completed') {
      throw new BusinessRuleError('No se puede cancelar un partido completado');
    }

    return await MatchesRepository.updateStatus(matchId, 'cancelled');
  }

  /**
   * Obtiene historial de enfrentamientos entre dos equipos
   */
  static async getHeadToHead(team1Id: string, team2Id: string) {
    if (!team1Id || !team2Id) {
      throw new ValidationError('Team IDs son requeridos');
    }

    return await MatchesRepository.getHeadToHead(team1Id, team2Id);
  }

  /**
   * Obtiene estadísticas mensuales de un usuario
   */
  static async getMonthlyStats(userId: string, year: number) {
    if (!userId) {
      throw new ValidationError('User ID es requerido');
    }

    const currentYear = new Date().getFullYear();
    if (year < 2020 || year > currentYear + 1) {
      throw new ValidationError('Año inválido');
    }

    return await MatchesRepository.getMonthlyStats(userId, year);
  }

  /**
   * Obtiene partidos más reñidos
   */
  static async getClosestMatches(limit: number = 10) {
    return await MatchesRepository.getClosestMatches(limit);
  }

  /**
   * Determina el resultado para un equipo específico
   */
  static determineTeamResult(
    match: any,
    teamId: string
  ): 'win' | 'loss' | 'draw' | null {
    if (!match.matchResult) return null;

    const { team1Score, team2Score, winnerId } = match.matchResult;

    if (team1Score === team2Score) return 'draw';

    return winnerId === teamId ? 'win' : 'loss';
  }
}
