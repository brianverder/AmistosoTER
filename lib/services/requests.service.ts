/**
 * Match Requests Service
 * Servicio para gestión de solicitudes de partidos
 */

import { 
  MatchRequest, 
  MatchRequestWithDetails, 
  CreateMatchRequestDTO, 
  UpdateMatchRequestDTO,
  RequestStatusBadge 
} from '@/lib/types';
import { API_ROUTES } from '@/lib/utils/constants';

export class RequestsService {
  /**
   * Obtiene todas las solicitudes del usuario
   */
  static async getUserRequests(): Promise<MatchRequestWithDetails[]> {
    const response = await fetch(API_ROUTES.REQUESTS);
    
    if (!response.ok) {
      throw new Error('Error al obtener solicitudes');
    }
    
    return response.json();
  }

  /**
   * Obtiene solicitudes públicas
   */
  static async getPublicRequests(status?: 'active' | 'historical'): Promise<MatchRequestWithDetails[]> {
    const url = status 
      ? `/api/public/requests?status=${status}`
      : '/api/public/requests';
    
    const response = await fetch(url);
    
    if (!response.ok) {
      throw new Error('Error al obtener solicitudes públicas');
    }
    
    return response.json();
  }

  /**
   * Obtiene una solicitud por ID
   */
  static async getRequestById(id: string): Promise<MatchRequestWithDetails> {
    const response = await fetch(`${API_ROUTES.REQUESTS}/${id}`);
    
    if (!response.ok) {
      throw new Error('Error al obtener solicitud');
    }
    
    return response.json();
  }

  /**
   * Crea una nueva solicitud
   */
  static async createRequest(data: CreateMatchRequestDTO): Promise<MatchRequest> {
    const response = await fetch(API_ROUTES.REQUESTS, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Error al crear solicitud');
    }
    
    return response.json();
  }

  /**
   * Actualiza una solicitud
   */
  static async updateRequest(id: string, data: UpdateMatchRequestDTO): Promise<MatchRequest> {
    const response = await fetch(`${API_ROUTES.REQUESTS}/${id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Error al actualizar solicitud');
    }
    
    return response.json();
  }

  /**
   * Cancela una solicitud
   */
  static async cancelRequest(id: string): Promise<void> {
    await this.updateRequest(id, { status: 'cancelled' });
  }

  /**
   * Acepta una solicitud (crea un match)
   */
  static async acceptRequest(requestId: string, teamId: string): Promise<Match> {
    const response = await fetch(`${API_ROUTES.REQUESTS}/${requestId}/match`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ teamId }),
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Error al aceptar solicitud');
    }
    
    return response.json();
  }

  /**
   * Obtiene badge de estado de solicitud
   */
  static getRequestStatusBadge(status: string): RequestStatusBadge {
    const badges: Record<string, RequestStatusBadge> = {
      active: {
        text: 'Disponible',
        class: 'bg-black text-white border border-black',
        icon: '🟢',
      },
      matched: {
        text: 'Match Hecho',
        class: 'bg-gray-300 text-black border border-black',
        icon: '🤝',
      },
      completed: {
        text: 'Finalizado',
        class: 'bg-gray-700 text-white border border-black',
        icon: '✅',
      },
      cancelled: {
        text: 'Cancelado',
        class: 'bg-white text-black border border-black',
        icon: '❌',
      },
    };

    return badges[status] || badges.active;
  }
}

// Import Match from correct path
import { Match } from '@/lib/types';
