'use client';

import { useEffect, useState } from 'react';
import { useSession } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Spinner from '@/components/Spinner';
import Toast, { ToastType } from '@/components/Toast';
import LoadingState from '@/components/LoadingState';

interface Match {
  id: string;
  team1Id: string;
  team2Id: string;
  userId1: string;
  userId2: string;
  status: string;
  finalDate: string | null;
  finalAddress: string | null;
  finalPrice: number | null;
  createdAt: string;
  team1: {
    id: string;
    name: string;
    instagram?: string | null;
  };
  team2: {
    id: string;
    name: string;
    instagram?: string | null;
  };
  user1: {
    id: string;
    name: string;
    email: string;
    phone: string | null;
  };
  user2: {
    id: string;
    name: string;
    email: string;
    phone: string | null;
  };
  matchRequest: {
    id: string;
    userId: string;
    footballType: string | null;
    fieldName: string | null;
    fieldAddress: string | null;
    country: string | null;
    state: string | null;
    fieldPrice: number | null;
    matchDate: string | null;
    description: string | null;
    league: string | null;
  };
  matchResult: {
    id: string;
    team1Score: number;
    team2Score: number;
    winnerId: string | null;
  } | null;
}

export default function MatchDetailPage({ params }: { params: { id: string } }) {
  const { data: session } = useSession();
  const router = useRouter();
  const [match, setMatch] = useState<Match | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [toast, setToast] = useState<{ message: string; type: ToastType } | null>(null);
  const [scores, setScores] = useState({
    team1Score: '',
    team2Score: '',
  });

  useEffect(() => {
    fetchMatch();
  }, [params.id]);

  const fetchMatch = async () => {
    try {
      const response = await fetch(`/api/matches/${params.id}`);
      if (response.ok) {
        const data = await response.json();
        setMatch(data);
        setError('');
      } else {
        setError('Match no encontrado');
      }
    } catch (error) {
      setError('Error de conexión. Intenta nuevamente.');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmitResult = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!scores.team1Score || !scores.team2Score) {
      setToast({ message: 'Debes ingresar ambos marcadores para registrar el resultado', type: 'warning' });
      return;
    }

    const team1Score = parseInt(scores.team1Score);
    const team2Score = parseInt(scores.team2Score);

    if (team1Score < 0 || team2Score < 0) {
      setToast({ message: 'Los marcadores no pueden ser negativos', type: 'warning' });
      return;
    }

    setSubmitting(true);

    try {
      const response = await fetch(`/api/matches/${params.id}/result`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          team1Score,
          team2Score,
        }),
      });

      if (!response.ok) {
        const data = await response.json();
        setToast({ message: data.error || 'Error al registrar el resultado', type: 'error' });
        setSubmitting(false);
        return;
      }

      setToast({ message: '¡Resultado registrado exitosamente! Las estadísticas se han actualizado.', type: 'success' });
      // Recargar el match
      fetchMatch();
      setScores({ team1Score: '', team2Score: '' });
    } catch (error) {
      setToast({ message: 'Error de conexión. Verifica tu internet e intenta nuevamente.', type: 'error' });
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return <LoadingState message="Cargando información del partido..." icon="⚽" size="lg" />;
  }

  if (error || !match) {
    return (
      <div className="card text-center py-12">
        <div className="text-6xl mb-4">❌</div>
        <h2 className="text-2xl font-bold text-primary mb-2">Error</h2>
        <p className="text-gray-600 mb-6">{error || 'Match no encontrado'}</p>
        <Link href="/dashboard/matches" className="btn-primary inline-block">
          Volver a Matches
        </Link>
      </div>
    );
  }

  const isUserTeam1 = match.userId1 === session?.user?.id;
  const isRequestCreator = match.matchRequest.userId === session?.user?.id;
  const userTeam = isUserTeam1 ? match.team1 : match.team2;
  const opponentTeam = isUserTeam1 ? match.team2 : match.team1;
  const opponentUser = isUserTeam1 ? match.user2 : match.user1;
  const opponentInstagram = opponentTeam.instagram?.trim().replace(/^@/, '');

  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-8">
        <Link
          href="/dashboard/matches"
          className="text-primary hover:underline mb-4 inline-block"
        >
          ← Volver a Matches
        </Link>
        <h1 className="text-3xl font-bold text-primary mb-2">
          Detalles del Match
        </h1>
      </div>

      {/* Resultado o vs */}
      <div className="card mb-6 text-center">
        <div className="flex items-center justify-center gap-8 py-6">
          <div className="text-center">
            <div className="text-4xl mb-2">⚽</div>
            <p className="text-2xl font-bold text-primary mb-1">{userTeam.name}</p>
            <p className="text-sm text-gray-500">Tu equipo</p>
          </div>

          <div className="text-center px-8">
            {match.matchResult ? (
              <div>
                <div className="flex items-center gap-4 mb-2">
                  <span className="text-5xl font-bold text-primary">
                    {isUserTeam1 ? match.matchResult.team1Score : match.matchResult.team2Score}
                  </span>
                  <span className="text-3xl text-gray-400">-</span>
                  <span className="text-5xl font-bold text-primary">
                    {isUserTeam1 ? match.matchResult.team2Score : match.matchResult.team1Score}
                  </span>
                </div>
                {match.matchResult.winnerId === userTeam.id ? (
                  <span className="inline-flex items-center text-accent font-semibold">
                    🏆 ¡Victoria!
                  </span>
                ) : match.matchResult.winnerId === opponentTeam.id ? (
                  <span className="inline-flex items-center text-accent-red font-semibold">
                    ❌ Derrota
                  </span>
                ) : (
                  <span className="inline-flex items-center text-gray-600 font-semibold">
                    🤝 Empate
                  </span>
                )}
              </div>
            ) : (
              <span className="text-5xl text-gray-400">vs</span>
            )}
          </div>

          <div className="text-center">
            <div className="text-4xl mb-2">⚽</div>
            <p className="text-2xl font-bold text-primary mb-1">{opponentTeam.name}</p>
            <p className="text-sm text-gray-500">Rival</p>
          </div>
        </div>
      </div>

      {/* Resultado completado */}
      {match.matchResult && (
        <div className="card bg-green-50 border-2 border-accent mb-6">
          <div className="flex items-start gap-4">
            <span className="text-4xl">✅</span>
            <div className="flex-1">
              <h3 className="text-xl font-bold text-primary mb-2">
                Partido Finalizado
              </h3>
              <div className="space-y-2 text-sm text-gray-700">
                <p>
                  <strong>Resultado final:</strong> {match.team1.name} {match.matchResult.team1Score} - {match.matchResult.team2Score} {match.team2.name}
                </p>
                <p>
                  <strong>Ganador:</strong>{' '}
                  {match.matchResult.winnerId === match.team1.id
                    ? `🏆 ${match.team1.name}`
                    : match.matchResult.winnerId === match.team2.id
                    ? `🏆 ${match.team2.name}`
                    : '🤝 Empate'}
                </p>
                <p className="text-xs text-gray-600 mt-3 pt-3 border-t border-green-200">
                  ✓ Las estadísticas de ambos equipos han sido actualizadas
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Información del partido */}
        <div className="lg:col-span-2 space-y-6">
          <div className="card">
            <h2 className="text-xl font-bold text-primary mb-4">
              📋 Información del Partido
            </h2>

            <div className="space-y-3 text-sm">
              {match.matchRequest.footballType && (
                <p>
                  <span className="font-semibold">⚽ Tipo:</span> Fútbol {match.matchRequest.footballType}
                </p>
              )}

              {match.matchRequest.fieldName && (
                <p>
                  <span className="font-semibold">🏟️ Cancha:</span> {match.matchRequest.fieldName}
                </p>
              )}

              {match.matchRequest.country && (
                <p>
                  <span className="font-semibold">🌎 País:</span> {match.matchRequest.country}
                </p>
              )}

              {match.matchRequest.state && (
                <p>
                  <span className="font-semibold">📍 Depto/Prov:</span> {match.matchRequest.state}
                </p>
              )}

              {match.matchRequest.league && (
                <p>
                  <span className="font-semibold">🏆 Liga:</span> {match.matchRequest.league}
                </p>
              )}

              {(match.finalAddress || match.matchRequest.fieldAddress) && (
                <p>
                  <span className="font-semibold">🗺️ Dirección:</span>{' '}
                  {match.finalAddress || match.matchRequest.fieldAddress}
                </p>
              )}

              {(match.finalDate || match.matchRequest.matchDate) && (
                <p>
                  <span className="font-semibold">📅 Fecha:</span>{' '}
                  {new Date(match.finalDate || match.matchRequest.matchDate!).toLocaleString('es', {
                    dateStyle: 'full',
                    timeStyle: 'short',
                  })}
                </p>
              )}

              {(match.finalPrice || match.matchRequest.fieldPrice) && (
                <p>
                  <span className="font-semibold">💵 Precio:</span> $
                  {match.finalPrice || match.matchRequest.fieldPrice}
                </p>
              )}

              {match.matchRequest.description && (
                <p className="italic text-gray-600 pt-2 border-t">
                  "{match.matchRequest.description}"
                </p>
              )}
            </div>
          </div>

          {/* Información de contacto */}
          <div className="card bg-blue-50 border-blue-200">
            <h3 className="font-semibold text-primary mb-3">
              👤 Contacto del Rival
            </h3>
            <div className="space-y-2 text-sm">
              <p>
                <span className="font-semibold">Nombre:</span> {opponentUser.name}
              </p>
              <p>
                <span className="font-semibold">Email:</span> {opponentUser.email}
              </p>
              {opponentUser.phone && (
                <p>
                  <span className="font-semibold">Teléfono:</span> {opponentUser.phone}
                </p>
              )}
              {opponentInstagram && (
                <p>
                  <span className="font-semibold">Instagram:</span>{' '}
                  <a
                    href={`https://instagram.com/${opponentInstagram}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-primary hover:underline"
                  >
                    @{opponentInstagram}
                  </a>
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Registrar Resultado */}
        {!match.matchResult && (
          <div className="card">
            <h2 className="text-xl font-bold text-primary mb-4">
              📝 Registrar Resultado
            </h2>

            {!isRequestCreator ? (
              <div className="bg-yellow-50 border-2 border-yellow-300 rounded-lg p-4">
                <div className="flex items-start gap-3">
                  <span className="text-2xl">ℹ️</span>
                  <div>
                    <p className="font-semibold text-gray-800 mb-2">
                      Solo el organizador puede registrar el resultado
                    </p>
                    <p className="text-sm text-gray-700">
                      El usuario que creó la solicitud original debe ingresar el resultado del partido.
                    </p>
                  </div>
                </div>
              </div>
            ) : (
              <>
                {error && (
                  <div className="bg-red-50 border-2 border-accent-red text-accent-red px-4 py-3 rounded-lg mb-4 text-sm">
                    {error}
                  </div>
                )}

                <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 mb-4">
                  <p className="text-sm text-gray-700">
                    <span className="font-semibold">👤 Organizador:</span> Tú creaste esta solicitud, por lo que puedes registrar el resultado.
                  </p>
                </div>

                <form onSubmit={handleSubmitResult} className="space-y-4">
                  <div>
                    <label htmlFor="team1Score" className="label text-sm">
                      {match.team1.name}
                    </label>
                    <input
                      id="team1Score"
                      type="number"
                      min="0"
                      required
                      className="input"
                      placeholder="0"
                      value={scores.team1Score}
                      onChange={(e) =>
                        setScores({ ...scores, team1Score: e.target.value })
                      }
                    />
                  </div>

                  <div>
                    <label htmlFor="team2Score" className="label text-sm">
                      {match.team2.name}
                    </label>
                    <input
                      id="team2Score"
                      type="number"
                      min="0"
                      required
                      className="input"
                      placeholder="0"
                      value={scores.team2Score}
                      onChange={(e) =>
                        setScores({ ...scores, team2Score: e.target.value })
                      }
                    />
                  </div>

                  <button
                    type="submit"
                    disabled={submitting}
                    className="btn-primary w-full flex items-center justify-center gap-2"
                  >
                    {submitting && <Spinner size="sm" />}
                    {submitting ? 'Guardando...' : '✅ Guardar Resultado'}
                  </button>

                  <div className="bg-green-50 border border-green-200 rounded-lg p-3">
                    <p className="text-xs text-gray-700">
                      <strong>📊 Actualización automática:</strong>
                    </p>
                    <ul className="text-xs text-gray-700 mt-2 space-y-1">
                      <li>• Estadísticas de ambos equipos</li>
                      <li>• Historial de partidos</li>
                      <li>• Estado del match a "Finalizado"</li>
                    </ul>
                  </div>
                </form>
              </>
            )}
          </div>
        )}
      </div>

      {/* Toast de notificaciones */}
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  );
}
