/**
 * useMatches Hook
 * Hook personalizado para gestión de partidos
 */

import { useState, useEffect, useCallback } from 'react';
import { MatchWithDetails } from '@/lib/types';
import { MatchesService } from '@/lib/services/matches.service';

export function useMatches() {
  const [matches, setMatches] = useState<MatchWithDetails[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchMatches = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await MatchesService.getUserMatches();
      setMatches(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error al cargar matches');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchMatches();
  }, [fetchMatches]);

  const saveResult = async (matchId: string, team1Score: number, team2Score: number) => {
    try {
      setError(null);
      await MatchesService.createMatchResult(matchId, { team1Score, team2Score });
      await fetchMatches(); // Refresh después de guardar
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error al guardar resultado';
      setError(message);
      throw new Error(message);
    }
  };

  return {
    matches,
    loading,
    error,
    refresh: fetchMatches,
    saveResult,
  };
}
