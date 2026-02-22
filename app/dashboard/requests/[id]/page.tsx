'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { withBasePath } from '@/lib/utils/base-path';

interface Team {
  id: string;
  name: string;
}

interface MatchRequest {
  id: string;
  footballType: string | null;
  fieldName: string | null;
  fieldAddress: string | null;
  country: string | null;
  state: string | null;
  fieldPrice: number | null;
  matchDate: string | null;
  league: string | null;
  description: string | null;
  status: string;
  team: {
    id: string;
    name: string;
  };
  user: {
    id: string;
    name: string;
    email: string;
    phone: string | null;
  };
}

export default function RequestDetailPage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const [request, setRequest] = useState<MatchRequest | null>(null);
  const [teams, setTeams] = useState<Team[]>([]);
  const [selectedTeam, setSelectedTeam] = useState('');
  const [loading, setLoading] = useState(true);
  const [matching, setMatching] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchData();
  }, [params.id]);

  const fetchData = async () => {
    try {
      const [requestRes, teamsRes] = await Promise.all([
        fetch(withBasePath(`/api/requests/${params.id}`)),
        fetch(withBasePath('/api/teams')),
      ]);

      if (requestRes.ok) {
        const requestData = await requestRes.json();
        setRequest(requestData);
      } else {
        setError('Solicitud no encontrada');
      }

      if (teamsRes.ok) {
        const teamsData = await teamsRes.json();
        setTeams(teamsData);
      }
    } catch (error) {
      setError('Error al cargar datos');
    } finally {
      setLoading(false);
    }
  };

  const handleMatch = async () => {
    if (!selectedTeam) {
      setError('Debes seleccionar un equipo');
      return;
    }

    setError('');
    setMatching(true);

    try {
      const response = await fetch(withBasePath(`/api/requests/${params.id}/match`), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ teamId: selectedTeam }),
      });

      if (!response.ok) {
        const data = await response.json();
        setError(data.error || 'Error al crear match');
        return;
      }

      const match = await response.json();
      router.push(`/dashboard/matches/${match.id}`);
      router.refresh();
    } catch (error) {
      setError('Error al crear match');
    } finally {
      setMatching(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-center">
          <div className="text-4xl mb-2">⚽</div>
          <p className="text-gray-600">Cargando...</p>
        </div>
      </div>
    );
  }

  if (error || !request) {
    return (
      <div className="card text-center py-12">
        <div className="text-6xl mb-4">❌</div>
        <h2 className="text-2xl font-bold text-primary mb-2">Error</h2>
        <p className="text-gray-600 mb-6">{error || 'Solicitud no encontrada'}</p>
        <Link href="/dashboard/requests" className="btn-primary inline-block">
          Volver a Solicitudes
        </Link>
      </div>
    );
  }

  if (request.status !== 'active') {
    return (
      <div className="card text-center py-12">
        <div className="text-6xl mb-4">⚠️</div>
        <h2 className="text-2xl font-bold text-primary mb-2">
          Solicitud No Disponible
        </h2>
        <p className="text-gray-600 mb-6">
          Esta solicitud ya no está activa
        </p>
        <Link href="/dashboard/requests" className="btn-primary inline-block">
          Volver a Solicitudes
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-8">
        <Link
          href="/dashboard/requests"
          className="text-primary hover:underline mb-4 inline-block"
        >
          ← Volver a Solicitudes
        </Link>
        <h1 className="text-3xl font-bold text-primary mb-2">
          Detalles de la Solicitud
        </h1>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Detalles de la solicitud */}
        <div className="lg:col-span-2 space-y-6">
          <div className="card">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-primary">
                {request.team.name}
              </h2>
              <span className="px-4 py-2 bg-green-100 text-green-800 rounded-full text-sm font-semibold">
                Disponible
              </span>
            </div>

            <div className="space-y-4">
              {request.footballType && (
                <div className="flex items-start">
                  <span className="text-2xl mr-3">⚽</span>
                  <div>
                    <p className="font-semibold text-gray-700">Tipo de Fútbol</p>
                    <p className="text-gray-600">Fútbol {request.footballType === '11' ? '11' : request.footballType === '8' ? '8' : request.footballType === '7' ? '7' : request.footballType === '5' ? '5' : request.footballType}</p>
                  </div>
                </div>
              )}

              {request.fieldName && (
                <div className="flex items-start">
                  <span className="text-2xl mr-3">🏟️</span>
                  <div>
                    <p className="font-semibold text-gray-700">Nombre de la Cancha</p>
                    <p className="text-gray-600">{request.fieldName}</p>
                  </div>
                </div>
              )}

              {request.country && (
                <div className="flex items-start">
                  <span className="text-2xl mr-3">🌎</span>
                  <div>
                    <p className="font-semibold text-gray-700">País</p>
                    <p className="text-gray-600">{request.country}</p>
                  </div>
                </div>
              )}

              {request.state && (
                <div className="flex items-start">
                  <span className="text-2xl mr-3">📍</span>
                  <div>
                    <p className="font-semibold text-gray-700">Departamento/Provincia</p>
                    <p className="text-gray-600">{request.state}</p>
                  </div>
                </div>
              )}

              {request.league && (
                <div className="flex items-start">
                  <span className="text-2xl mr-3">🏆</span>
                  <div>
                    <p className="font-semibold text-gray-700">Liga</p>
                    <p className="text-gray-600">{request.league}</p>
                  </div>
                </div>
              )}

              {request.fieldAddress && (
                <div className="flex items-start">
                  <span className="text-2xl mr-3">🗺️</span>
                  <div>
                    <p className="font-semibold text-gray-700">Dirección</p>
                    <p className="text-gray-600">{request.fieldAddress}</p>
                  </div>
                </div>
              )}

              {request.matchDate && (
                <div className="flex items-start">
                  <span className="text-2xl mr-3">📅</span>
                  <div>
                    <p className="font-semibold text-gray-700">Fecha y Hora</p>
                    <p className="text-gray-600">
                      {new Date(request.matchDate).toLocaleString('es', {
                        dateStyle: 'full',
                        timeStyle: 'short',
                      })}
                    </p>
                  </div>
                </div>
              )}

              {request.fieldPrice && (
                <div className="flex items-start">
                  <span className="text-2xl mr-3">💵</span>
                  <div>
                    <p className="font-semibold text-gray-700">Precio de la Cancha</p>
                    <p className="text-gray-600">${request.fieldPrice}</p>
                  </div>
                </div>
              )}

              {request.description && (
                <div className="flex items-start">
                  <span className="text-2xl mr-3">📝</span>
                  <div>
                    <p className="font-semibold text-gray-700">Descripción</p>
                    <p className="text-gray-600 italic">"{request.description}"</p>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Match Form */}
        <div className="lg:col-span-1">
          <div className="card sticky top-4">
            <h3 className="text-xl font-bold text-primary mb-4">
              🤝 Hacer Match
            </h3>

            {error && (
              <div className="bg-red-50 border-2 border-accent-red text-accent-red px-4 py-3 rounded-lg mb-4 text-sm">
                {error}
              </div>
            )}

            {teams.length === 0 ? (
              <div>
                <p className="text-sm text-gray-600 mb-4">
                  Necesitas crear un equipo para hacer match
                </p>
                <Link href="/dashboard/teams/new" className="btn-primary w-full text-center block">
                  Crear Equipo
                </Link>
              </div>
            ) : (
              <div className="space-y-4">
                <div>
                  <label htmlFor="team" className="label">
                    Selecciona tu equipo
                  </label>
                  <select
                    id="team"
                    className="input"
                    value={selectedTeam}
                    onChange={(e) => setSelectedTeam(e.target.value)}
                  >
                    <option value="">Elige un equipo</option>
                    {teams.map((team) => (
                      <option key={team.id} value={team.id}>
                        {team.name}
                      </option>
                    ))}
                  </select>
                </div>

                <button
                  onClick={handleMatch}
                  disabled={matching || !selectedTeam}
                  className="btn-accent w-full"
                >
                  {matching ? 'Creando match...' : '🤝 Confirmar Match'}
                </button>

                <p className="text-xs text-gray-600 text-center">
                  Al hacer match, ambos equipos podrán coordinar el partido
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
