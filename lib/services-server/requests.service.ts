/**
 * ============================================
 * MATCH REQUESTS SERVICE (Server-Side)
 * ============================================
 * 
 * Capa de lógica de negocio para solicitudes de partidos.
 * Usa los repositorios y aplica validaciones/reglas de negocio.
 */

import { MatchRequestsRepository, TeamsRepository } from '@/lib/repositories';
import { ValidationError, NotFoundError, UnauthorizedError, BusinessRuleError } from '@/lib/errors';

export class MatchRequestsService {
  /**
   * Obtiene solicitudes de un usuario
   */
  static async getUserRequests(
    userId: string,
    status?: string,
    filters?: { footballType?: string; country?: string }
  ) {
    if (!userId) {
      throw new ValidationError('User ID es requerido');
    }

    return await MatchRequestsRepository.findByUserId(userId, status, filters);
  }

  /**
   * Obtiene solicitudes disponibles (públicas)
   */
  static async getAvailableRequests(filters?: {
    excludeUserId?: string;
    footballType?: string;
    country?: string;
    page?: number;
    pageSize?: number;
  }) {
    const page = filters?.page || 1;
    const pageSize = Math.min(filters?.pageSize || 20, 100);
    const offset = (page - 1) * pageSize;

    const [requests, total] = await Promise.all([
      MatchRequestsRepository.findActive({
        excludeUserId: filters?.excludeUserId,
        footballType: filters?.footballType,
        country: filters?.country,
        limit: pageSize,
        offset,
      }),
      MatchRequestsRepository.count({
        status: 'active',
        footballType: filters?.footballType,
        country: filters?.country,
      }),
    ]);

    return {
      requests,
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
    };
  }

  /**
   * Obtiene una solicitud por ID
   */
  static async getRequestById(requestId: string) {
    if (!requestId) {
      throw new ValidationError('Request ID es requerido');
    }

    const request = await MatchRequestsRepository.findById(requestId);

    if (!request) {
      throw new NotFoundError('Solicitud no encontrada');
    }

    return request;
  }

  /**
   * Crea una nueva solicitud
   */
  static async createRequest(data: {
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
    // Validaciones
    if (!data.userId) {
      throw new ValidationError('User ID es requerido');
    }

    if (!data.teamId) {
      throw new ValidationError('Team ID es requerido');
    }

    if (!data.footballType || !['5', '7', '8', '11', 'futsal'].includes(data.footballType)) {
      throw new ValidationError('Tipo de fútbol inválido (5, 7, 8, 11 o futsal)');
    }

    if (!data.fieldAddress || data.fieldAddress.trim().length === 0) {
      throw new ValidationError('Dirección del campo es requerida');
    }

    // Verificar que el equipo pertenece al usuario
    const teamBelongs = await TeamsRepository.belongsToUser(data.teamId, data.userId);
    if (!teamBelongs) {
      throw new UnauthorizedError('El equipo no te pertenece');
    }

    // Restricción eliminada: Ahora un equipo puede tener múltiples solicitudes activas
    // Esto permite mayor flexibilidad para buscar partidos en diferentes fechas/ubicaciones

    // Parsear fecha si se proporciona
    if (data.date) {
      if (isNaN(data.date.getTime())) {
        throw new ValidationError('Formato de fecha inválido');
      }

      // Verificar que la fecha no sea del pasado
      if (data.date < new Date()) {
        throw new ValidationError('La fecha no puede ser del pasado');
      }
    }

    return await MatchRequestsRepository.create({
      userId: data.userId,
      teamId: data.teamId,
      footballType: data.footballType,
      fieldName: data.fieldName?.trim(),
      fieldAddress: data.fieldAddress.trim(),
      country: data.country?.trim(),
      state: data.state?.trim(),
      date: data.date,
      fieldPrice: data.fieldPrice,
      league: data.league?.trim(),
      description: data.description?.trim(),
    });
  }

  /**
   * Actualiza una solicitud
   */
  static async updateRequest(
    requestId: string,
    userId: string,
    data: {
      fieldAddress?: string;
      fieldName?: string;
      date?: string;
      time?: string;
      fieldPrice?: number;
      description?: string;
    }
  ) {
    // Verificar que la solicitud pertenece al usuario
    const belongs = await MatchRequestsRepository.belongsToUser(requestId, userId);
    if (!belongs) {
      throw new UnauthorizedError('No tienes permiso para actualizar esta solicitud');
    }

    // Verificar que la solicitud está activa
    const request = await MatchRequestsRepository.findById(requestId);
    if (request?.status !== 'active') {
      throw new BusinessRuleError('Solo se pueden actualizar solicitudes activas');
    }

    const updateData: any = {};

    if (data.fieldAddress) {
      updateData.fieldAddress = data.fieldAddress.trim();
    }

    if (data.fieldName !== undefined) {
      updateData.fieldName = data.fieldName?.trim();
    }

    if (data.date) {
      const parsedDate = new Date(data.date);
      if (isNaN(parsedDate.getTime())) {
        throw new ValidationError('Formato de fecha inválido');
      }
      updateData.date = parsedDate;
    }

    if (data.time !== undefined) {
      updateData.time = data.time;
    }

    if (data.fieldPrice !== undefined) {
      updateData.fieldPrice = data.fieldPrice;
    }

    if (data.description !== undefined) {
      updateData.description = data.description?.trim();
    }

    return await MatchRequestsRepository.update(requestId, updateData);
  }

  /**
   * Cancela una solicitud
   */
  static async cancelRequest(requestId: string, userId: string) {
    // Verificar que la solicitud pertenece al usuario
    const belongs = await MatchRequestsRepository.belongsToUser(requestId, userId);
    if (!belongs) {
      throw new UnauthorizedError('No tienes permiso para cancelar esta solicitud');
    }

    // Verificar que puede ser cancelada
    const canDelete = await MatchRequestsRepository.canBeDeleted(requestId);
    if (!canDelete) {
      throw new BusinessRuleError(
        'No se puede cancelar una solicitud con match confirmado'
      );
    }

    return await MatchRequestsRepository.updateStatus(requestId, 'cancelled');
  }

  /**
   * Elimina una solicitud
   */
  static async deleteRequest(requestId: string, userId: string) {
    // Verificar que la solicitud pertenece al usuario
    const belongs = await MatchRequestsRepository.belongsToUser(requestId, userId);
    if (!belongs) {
      throw new UnauthorizedError('No tienes permiso para eliminar esta solicitud');
    }

    // Verificar que puede ser eliminada
    const canDelete = await MatchRequestsRepository.canBeDeleted(requestId);
    if (!canDelete) {
      throw new BusinessRuleError(
        'No se puede eliminar una solicitud con match confirmado'
      );
    }

    return await MatchRequestsRepository.delete(requestId);
  }

  /**
   * Busca solicitudes por ubicación
   */
  static async searchByLocation(location: string, limit: number = 20) {
    if (!location || location.trim().length < 3) {
      throw new ValidationError('La ubicación debe tener al menos 3 caracteres');
    }

    return await MatchRequestsRepository.searchByLocation(location.trim(), limit);
  }

  /**
   * Obtiene solicitudes con disponibilidad
   */
  static async getRequestsWithAvailability(footballType?: string) {
    if (footballType && !['5', '7', '8', '11', 'futsal'].includes(footballType)) {
      throw new ValidationError('Tipo de fútbol inválido');
    }

    return await MatchRequestsRepository.findWithAvailability(footballType);
  }

  /**
   * Búsqueda full-text
   */
  static async fullTextSearch(searchTerm: string, limit: number = 20) {
    if (!searchTerm || searchTerm.trim().length < 2) {
      throw new ValidationError('El término de búsqueda debe tener al menos 2 caracteres');
    }

    return await MatchRequestsRepository.fullTextSearch(searchTerm.trim(), limit);
  }
}
