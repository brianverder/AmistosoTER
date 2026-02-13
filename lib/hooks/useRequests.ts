/**
 * useRequests Hook
 * Hook personalizado para gestión de solicitudes
 */

import { useState, useEffect, useCallback } from 'react';
import { MatchRequestWithDetails, CreateMatchRequestDTO } from '@/lib/types';
import { RequestsService } from '@/lib/services/requests.service';

export function useRequests() {
  const [requests, setRequests] = useState<MatchRequestWithDetails[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchRequests = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await RequestsService.getUserRequests();
      setRequests(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al cargar solicitudes');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchRequests();
  }, [fetchRequests]);

  const createRequest = async (data: CreateMatchRequestDTO) => {
    try {
      setError(null);
      await RequestsService.createRequest(data);
      await fetchRequests(); // Refresh después de crear
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error al crear solicitud';
      setError(message);
      throw new Error(message);
    }
  };

  const cancelRequest = async (id: string) => {
    try {
      setError(null);
      await RequestsService.cancelRequest(id);
      setRequests((prev) =>
        prev.map((req) =>
          req.id === id ? { ...req, status: 'cancelled' as const } : req
        )
      );
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error al cancelar solicitud';
      setError(message);
      throw new Error(message);
    }
  };

  const acceptRequest = async (requestId: string, teamId: string) => {
    try {
      setError(null);
      await RequestsService.acceptRequest(requestId, teamId);
      await fetchRequests(); // Refresh después de aceptar
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error al aceptar solicitud';
      setError(message);
      throw new Error(message);
    }
  };

  return {
    requests,
    loading,
    error,
    refresh: fetchRequests,
    createRequest,
    cancelRequest,
    acceptRequest,
  };
}
