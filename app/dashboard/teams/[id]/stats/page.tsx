'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { withBasePath } from '@/lib/utils/base-path';

interface TeamStats {
  id: string;
  name: string;
  gamesWon: number;
  gamesLost: number;
  gamesDrawn: number;
  totalGames: number;
}

interface MatchHistoryItem {
  id: string;
  opponent: string;
  ownScore: number;
  opponentScore: number;
  result: 'won' | 'lost' | 'draw';
  footballType: string | null;
  matchDate: string | null;
  createdAt: string;
}

interface StatsData {
  team: TeamStats;
  matchHistory: MatchHistoryItem[];
}

export default function TeamStatsPage({ params }: { params: { id: string } }) {
  const [data, setData] = useState<StatsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchStats();
  }, [params.id]);

  const fetchStats = async () => {
    try {
      const response = await fetch(withBasePath(`/api/teams/${params.id}/stats`));
      if (response.ok) {
        const statsData = await response.json();
        setData(statsData);
      } else {
        setError('No se pudieron cargar las estadísticas');
      }
    } catch (error) {
      setError('Error al cargar estadísticas');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <div className="text-4xl mb-2">📊</div>
          <p className="text-gray-600">Cargando estadísticas...</p>
        </div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="card text-center py-12">
        <div className="text-6xl mb-4">❌</div>
        <h2 className="text-2xl font-bold text-primary mb-2">Error</h2>
        <p className="text-gray-600 mb-6">{error || 'Estadísticas no disponibles'}</p>
        <Link href={`/dashboard/teams/${params.id}`} className="btn-primary inline-block">
          Volver al Equipo
        </Link>
      </div>
    );
  }

  const { team, matchHistory } = data;

  // Calcular porcentajes
  const winRate = team.totalGames > 0 
    ? ((team.gamesWon / team.totalGames) * 100).toFixed(1)
    : '0.0';

  const getResultBadge = (result: 'won' | 'lost' | 'draw') => {
    switch (result) {
      case 'won':
        return (
          <span className="px-3 py-1 bg-gray-800 text-white border border-black text-xs font-semibold">
            🏆 Victoria
          </span>
        );
      case 'lost':
        return (
          <span className="px-3 py-1 bg-white text-black border border-black text-xs font-semibold">
            ❌ Derrota
          </span>
        );
      case 'draw':
        return (
          <span className="px-3 py-1 bg-gray-300 text-black border border-black text-xs font-semibold">
            🤝 Empate
          </span>
        );
    }
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('es-ES', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    });
  };

  return (
    <div className="max-w-6xl mx-auto">
      <div className="mb-8">
        <Link
          href={`/dashboard/teams/${params.id}`}
          className="text-primary hover:underline mb-4 inline-block"
        >
          ← Volver a {team.name}
        </Link>
        <h1 className="text-3xl font-bold text-primary mb-2">
          📊 Estadísticas de {team.name}
        </h1>
        <p className="text-gray-600">Resumen de rendimiento e historial de encuentros</p>
      </div>

      {/* Resumen de Estadísticas */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div className="card text-center">
          <div className="text-3xl font-bold text-primary mb-1">
            {team.totalGames}
          </div>
          <div className="text-sm text-gray-600">Partidos Jugados</div>
        </div>

        <div className="card text-center">
          <div className="text-3xl font-bold text-black mb-1">
            {team.gamesWon}
          </div>
          <div className="text-sm text-gray-600">Victorias</div>
          <div className="text-xs text-gray-500 mt-1">{winRate}% efectividad</div>
        </div>

        <div className="card text-center">
          <div className="text-3xl font-bold text-red-600 mb-1">
            {team.gamesLost}
          </div>
          <div className="text-sm text-gray-600">Derrotas</div>
        </div>

        <div className="card text-center">
          <div className="text-3xl font-bold text-gray-600 mb-1">
            {team.gamesDrawn}
          </div>
          <div className="text-sm text-gray-600">Empates</div>
        </div>
      </div>

      {/* Historial de Encuentros */}
      <div className="card">
        <h2 className="text-xl font-bold text-primary mb-4">
          🏟️ Historial de Encuentros
        </h2>

        {matchHistory.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-5xl mb-3">📋</div>
            <p className="text-gray-600 mb-2">No hay partidos finalizados aún</p>
            <p className="text-sm text-gray-500">
              Los partidos aparecerán aquí una vez que se registren los resultados
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">
                    Fecha
                  </th>
                  <th className="text-left py-3 px-4 text-sm font-semibold text-gray-700">
                    Oponente
                  </th>
                  <th className="text-center py-3 px-4 text-sm font-semibold text-gray-700">
                    Resultado
                  </th>
                  <th className="text-center py-3 px-4 text-sm font-semibold text-gray-700">
                    Tipo
                  </th>
                  <th className="text-center py-3 px-4 text-sm font-semibold text-gray-700">
                    Estado
                  </th>
                </tr>
              </thead>
              <tbody>
                {matchHistory.map((match) => (
                  <tr
                    key={match.id}
                    className="border-b border-gray-100 hover:bg-gray-50 transition-colors"
                  >
                    <td className="py-4 px-4 text-sm text-gray-600">
                      {formatDate(match.matchDate || match.createdAt)}
                    </td>
                    <td className="py-4 px-4">
                      <div className="font-medium text-gray-900">
                        {match.opponent}
                      </div>
                    </td>
                    <td className="py-4 px-4 text-center">
                      <div className="font-bold text-lg">
                        <span
                          className={
                            match.result === 'won'
                              ? 'text-black font-extrabold'
                              : match.result === 'lost'
                              ? 'text-gray-400'
                              : 'text-black'
                          }
                        >
                          {match.ownScore}
                        </span>
                        <span className="text-gray-400 mx-2">-</span>
                        <span
                          className={
                            match.result === 'lost'
                              ? 'text-black font-extrabold'
                              : match.result === 'won'
                              ? 'text-gray-400'
                              : 'text-black'
                          }
                        >
                          {match.opponentScore}
                        </span>
                      </div>
                    </td>
                    <td className="py-4 px-4 text-center text-sm text-gray-600">
                      {match.footballType ? `⚽ Fútbol ${match.footballType}` : '-'}
                    </td>
                    <td className="py-4 px-4 text-center">
                      {getResultBadge(match.result)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Botón para volver */}
      <div className="mt-8 text-center">
        <Link
          href={`/dashboard/teams/${params.id}`}
          className="btn-secondary inline-block"
        >
          Volver al Equipo
        </Link>
      </div>
    </div>
  );
}
