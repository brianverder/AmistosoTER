/**
 * useTeams Hook
 * Hook personalizado para gestión de equipos
 */

import { useState, useEffect, useCallback } from 'react';
import { Team } from '@/lib/types';
import { TeamsService } from '@/lib/services/teams.service';

export function useTeams() {
  const [teams, setTeams] = useState<Team[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTeams = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await TeamsService.getUserTeams();
      setTeams(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al cargar equipos');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchTeams();
  }, [fetchTeams]);

  const createTeam = async (name: string) => {
    try {
      setError(null);
      const newTeam = await TeamsService.createTeam({ name });
      setTeams((prev) => [...prev, newTeam]);
      return newTeam;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error al crear equipo';
      setError(message);
      throw new Error(message);
    }
  };

  const updateTeam = async (id: string, name: string) => {
    try {
      setError(null);
      const updatedTeam = await TeamsService.updateTeam(id, { name });
      setTeams((prev) =>
        prev.map((team) => (team.id === id ? updatedTeam : team))
      );
      return updatedTeam;
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error al actualizar equipo';
      setError(message);
      throw new Error(message);
    }
  };

  const deleteTeam = async (id: string) => {
    try {
      setError(null);
      await TeamsService.deleteTeam(id);
      setTeams((prev) => prev.filter((team) => team.id !== id));
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error al eliminar equipo';
      setError(message);
      throw new Error(message);
    }
  };

  return {
    teams,
    loading,
    error,
    refresh: fetchTeams,
    createTeam,
    updateTeam,
    deleteTeam,
  };
}
