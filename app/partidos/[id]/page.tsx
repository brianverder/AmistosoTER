'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { useSession } from 'next-auth/react';
import Spinner from '@/components/Spinner';
import Toast, { ToastType } from '@/components/Toast';
import LoadingState from '@/components/LoadingState';
import { withBasePath } from '@/lib/utils/base-path';

interface Team {
  id: string;
  name: string;
  instagram?: string | null;
  gamesPlayed?: number;
  gamesWon?: number;
  gamesLost?: number;
  gamesDraw?: number;
  userId?: string;
}

interface User {
  id: string;
  name: string;
  email?: string;
  phone?: string | null;
}

interface Match {
  id: string;
  teamA: Team;
  teamB: Team;
  userA: User;
  userB: User;
  matchDate: string | null;
  status: string;
}

interface MatchRequest {
  id: string;
  footballType: string | null;
  fieldAddress: string | null;
  fieldPrice: number | null;
  matchDate: string | null;
  league: string | null;
  description: string | null;
  status: string;
  team: Team;
  user: User;
  match?: Match;
}

export default function PublicRequestDetailPage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const { data: session } = useSession();
  const [request, setRequest] = useState<MatchRequest | null>(null);
  const [userTeams, setUserTeams] = useState<Team[]>([]);
  const [selectedTeam, setSelectedTeam] = useState('');
  const [loading, setLoading] = useState(true);
  const [matching, setMatching] = useState(false);
  const [error, setError] = useState('');
  const [showMatchModal, setShowMatchModal] = useState(false);
  const [toast, setToast] = useState<{message: string; type: ToastType} | null>(null);

  useEffect(() => {
    fetchData();
  }, [params.id, session]);

  const fetchData = async () => {
    try {
      const requestRes = await fetch(withBasePath(`/api/public/requests/${params.id}`));

      if (requestRes.ok) {
        const requestData = await requestRes.json();
        setRequest(requestData);
      } else {
        setError('Solicitud no encontrada');
      }

      // Si está autenticado, cargar sus equipos
      if (session) {
        const teamsRes = await fetch(withBasePath('/api/teams'));
        if (teamsRes.ok) {
          const teamsData = await teamsRes.json();
          setUserTeams(teamsData);
        }
      }
    } catch (error) {
      setError('Error de conexión. Verifica tu internet e intenta nuevamente.');
      setToast({ message: 'Error al cargar el partido. Por favor, intenta nuevamente.', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleAcceptMatch = () => {
    if (!session) {
      // Redirigir a login con returnUrl
      router.push(`/login?returnUrl=/partidos/${params.id}`);
      return;
    }

    if (userTeams.length === 0) {
      setToast({ message: 'Necesitas crear un equipo primero para aceptar partidos', type: 'warning' });
      return;
    }

    setError('');
    setShowMatchModal(true);
  };

  const handleConfirmMatch = async () => {
    if (!selectedTeam) {
      setToast({ message: 'Debes seleccionar un equipo', type: 'warning' });
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
        const errorMsg = data.error || 'Error al crear el match';
        setError(errorMsg);
        setToast({ message: errorMsg, type: 'error' });
        setMatching(false);
        return;
      }

      // Éxito: mostrar mensaje y recargar
      setToast({ message: '¡Match confirmado! Ya pueden coordinar los detalles del partido.', type: 'success' });
      setShowMatchModal(false);
      
      // Recargar datos para mostrar el match
      await fetchData();
    } catch (error) {
      const errorMsg = 'Error de conexión. Verifica tu internet e intenta nuevamente.';
      setError(errorMsg);
      setToast({ message: errorMsg, type: 'error' });
    } finally {
      setMatching(false);
    }
  };

  const getStatusInfo = (status: string) => {
    const statuses = {
      active: { text: 'Disponible', class: 'bg-black text-white border border-black', icon: '🟢' },
      matched: { text: 'Match Hecho', class: 'bg-gray-300 text-black border border-black', icon: '🤝' },
      completed: { text: 'Finalizado', class: 'bg-gray-700 text-white border border-black', icon: '✅' },
      cancelled: { text: 'Cancelado', class: 'bg-white text-black border border-black', icon: '❌' },
    };
    return statuses[status as keyof typeof statuses] || statuses.active;
  };

  if (loading) {
    return <LoadingState size="lg" message="Cargando información del partido..." icon="⚽" />;
  }

  if (error || !request) {
    return (
      <div className="min-h-screen bg-gray-50 py-12">
        <div className="container mx-auto px-4 max-w-2xl">
          <div className="card text-center py-12">
            <div className="text-6xl mb-4">❌</div>
            <h2 className="text-2xl font-bold text-primary mb-2">Error</h2>
            <p className="text-gray-600 mb-6">{error || 'Solicitud no encontrada'}</p>
            <Link href="/partidos" className="btn-primary inline-block">
              Volver a Partidos
            </Link>
          </div>
        </div>
      </div>
    );
  }

  const statusInfo = getStatusInfo(request.status);
  const isOwnRequest = session?.user?.id === request.user.id;
  const canAccept = request.status === 'active' && !isOwnRequest;
  const hasMatch = !!request.match;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-primary text-white py-4 shadow-md">
        <div className="container mx-auto px-4">
          <div className="flex items-center justify-between">
            <Link href="/partidos" className="flex items-center gap-3 hover:opacity-80">
              <Image
                src="https://tercer-tiempo.com/images/logo_tercertiempoNegro.png"
                alt="Tercer Tiempo"
                width={40}
                height={40}
                className="object-contain invert"
              />
              <span className="text-xl font-bold">Tercer Tiempo</span>
            </Link>
            {session ? (
              <Link href="/dashboard" className="btn-secondary bg-white text-primary text-sm">
                Mi Dashboard
              </Link>
            ) : (
              <Link href="/login" className="btn-secondary bg-white text-primary text-sm">
                Iniciar Sesión
              </Link>
            )}
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8 max-w-5xl">
        <div className="mb-6">
          <Link
            href="/partidos"
            className="text-primary hover:underline inline-flex items-center gap-2"
          >
            ← Volver a Partidos
          </Link>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Información Principal */}
          <div className="lg:col-span-2 space-y-6">
            <div className="card">
              <div className="flex items-center justify-between mb-6">
                <h1 className="text-3xl font-bold text-primary">
                  {request.team.name}
                </h1>
                <span className={`px-4 py-2 rounded-full text-sm font-semibold ${statusInfo.class} flex items-center gap-2`}>
                  <span>{statusInfo.icon}</span>
                  {statusInfo.text}
                </span>
              </div>

              <div className="space-y-4">
                {request.footballType && (
                  <div className="flex items-start">
                    <span className="text-2xl mr-3">⚽</span>
                    <div>
                      <p className="font-semibold text-gray-700">Tipo de Fútbol</p>
                      <p className="text-gray-600">Fútbol {request.footballType}</p>
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
                    <span className="text-2xl mr-3">📍</span>
                    <div>
                      <p className="font-semibold text-gray-700">Ubicación</p>
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
                        {new Date(request.matchDate).toLocaleString('es-AR', {
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

            {/* Información de Contacto (solo si hay match) */}
            {hasMatch && request.match && (
              <div className="card bg-green-50 border-2 border-accent">
                <h3 className="font-bold text-primary mb-4 text-xl flex items-center gap-2">
                  <span>🤝</span> Match Confirmado
                </h3>
                <div className="space-y-6">
                  <div>
                    <h4 className="font-semibold text-gray-700 mb-2">Equipo Solicitante:</h4>
                    <div className="bg-white p-4 rounded-lg">
                      <p className="font-bold text-primary mb-2">{request.match.teamA.name}</p>
                      <p className="text-sm text-gray-700">
                        <strong>Contacto:</strong> {request.match.userA.name}
                      </p>
                      {request.match.userA.email && (
                        <p className="text-sm text-gray-700">
                          <strong>Email:</strong> {request.match.userA.email}
                        </p>
                      )}
                      {request.match.userA.phone && (
                        <p className="text-sm text-gray-700">
                          <strong>Teléfono:</strong> {request.match.userA.phone}
                        </p>
                      )}
                      {request.match.teamA.instagram && (
                        <p className="text-sm text-gray-700">
                          <strong>Instagram:</strong> {request.match.teamA.instagram}
                        </p>
                      )}
                    </div>
                  </div>

                  <div>
                    <h4 className="font-semibold text-gray-700 mb-2">Equipo Aceptante:</h4>
                    <div className="bg-white p-4 rounded-lg">
                      <p className="font-bold text-primary mb-2">{request.match.teamB.name}</p>
                      <p className="text-sm text-gray-700">
                        <strong>Contacto:</strong> {request.match.userB.name}
                      </p>
                      {request.match.userB.email && (
                        <p className="text-sm text-gray-700">
                          <strong>Email:</strong> {request.match.userB.email}
                        </p>
                      )}
                      {request.match.userB.phone && (
                        <p className="text-sm text-gray-700">
                          <strong>Teléfono:</strong> {request.match.userB.phone}
                        </p>
                      )}
                      {request.match.teamB.instagram && (
                        <p className="text-sm text-gray-700">
                          <strong>Instagram:</strong> {request.match.teamB.instagram}
                        </p>
                      )}
                    </div>
                  </div>

                  <div className="bg-blue-50 border border-blue-200 p-4 rounded-lg">
                    <p className="text-sm text-gray-700">
                      💡 <strong>Siguiente paso:</strong> Coordinen entre ustedes los detalles finales del partido. ¡Que gane el mejor equipo! ⚽
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Acción Principal */}
            <div className="card">
              <h3 className="font-semibold text-primary mb-4">Acción</h3>
              
              {canAccept ? (
                <button
                  onClick={handleAcceptMatch}
                  className="btn-accent w-full mb-3 text-lg"
                >
                  🤝 Aceptar Partido
                </button>
              ) : isOwnRequest ? (
                <div className="bg-yellow-50 border border-yellow-200 p-4 rounded-lg text-sm text-gray-700">
                  ℹ️ Esta es tu propia solicitud
                </div>
              ) : !session ? (
                <div className="space-y-3">
                  <button
                    onClick={handleAcceptMatch}
                    className="btn-accent w-full"
                  >
                    🤝 Aceptar Partido
                  </button>
                  <p className="text-xs text-gray-500 text-center">
                    Necesitas iniciar sesión
                  </p>
                </div>
              ) : (
                <div className="bg-gray-50 border border-gray-200 p-4 rounded-lg text-sm text-gray-700">
                  {statusInfo.icon} {statusInfo.text}
                </div>
              )}

              {error && (
                <div className="mt-3 bg-red-50 border border-red-200 p-3 rounded-lg text-sm text-red-700">
                  ⚠️ {error}
                </div>
              )}
            </div>

            {/* Info del Equipo */}
            <div className="card bg-blue-50 border-blue-200">
              <h3 className="font-semibold text-primary mb-3">👥 Sobre el Equipo</h3>
              <div className="space-y-2 text-sm">
                <p><strong>Nombre:</strong> {request.team.name}</p>
                <p><strong>Organizador:</strong> {request.user.name}</p>
                {request.team.gamesPlayed !== undefined && request.team.gamesPlayed > 0 && (
                  <>
                    <p><strong>Partidos jugados:</strong> {request.team.gamesPlayed}</p>
                    <p><strong>Victorias:</strong> {request.team.gamesWon}</p>
                    <p><strong>Derrotas:</strong> {request.team.gamesLost}</p>
                    <p><strong>Empates:</strong> {request.team.gamesDraw}</p>
                  </>
                )}
              </div>
            </div>

            {/* Consejos */}
            <div className="card bg-yellow-50 border-yellow-200">
              <h3 className="font-semibold text-primary mb-3">💡 Consejos</h3>
              <ul className="text-sm text-gray-700 space-y-2">
                <li>• Verifica la ubicación y fecha antes de aceptar</li>
                <li>• Al hacer match podrás ver los datos de contacto</li>
                <li>• Coordina los detalles directamente con el organizador</li>
                <li>• Confirma el precio y forma de pago de la cancha</li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      {/* Modal de Selección de Equipo */}
      {showMatchModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-md w-full p-6">
            <h3 className="text-2xl font-bold text-primary mb-4">
              Selecciona tu Equipo
            </h3>
            <p className="text-gray-600 mb-4">
              Elige qué equipo enfrentará a <strong>{request.team.name}</strong>
            </p>

            <select
              value={selectedTeam}
              onChange={(e) => setSelectedTeam(e.target.value)}
              className="input mb-4"
            >
              <option value="">Selecciona un equipo</option>
              {userTeams.map((team) => (
                <option key={team.id} value={team.id}>
                  {team.name}
                  {team.gamesPlayed && team.gamesPlayed > 0
                    ? ` (${team.gamesWon}V - ${team.gamesPlayed - (team.gamesWon || 0)}D/E)`
                    : ''}
                </option>
              ))}
            </select>

            {userTeams.length === 0 && (
              <div className="bg-yellow-50 border border-yellow-200 p-4 rounded-lg mb-4">
                <p className="text-sm text-gray-700 mb-3">
                  No tienes equipos creados. Necesitas crear un equipo primero.
                </p>
                <Link
                  href="/dashboard/teams/new"
                  className="btn-accent text-sm inline-block"
                >
                  Crear Equipo
                </Link>
              </div>
            )}

            <div className="flex gap-3">
              <button
                onClick={() => setShowMatchModal(false)}
                className="btn-secondary flex-1"
                disabled={matching}
              >
                Cancelar
              </button>
              <button
                onClick={handleConfirmMatch}
                className="btn-accent flex-1 flex items-center justify-center gap-2"
                disabled={matching || !selectedTeam}
              >
                {matching && <Spinner size="sm" />}
                {matching ? 'Procesando...' : 'Confirmar Match'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast Notifications */}
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
