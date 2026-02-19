'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { useSession } from 'next-auth/react';
import LoadingState from '@/components/LoadingState';
import Toast, { ToastType } from '@/components/Toast';

interface MatchRequest {
  id: string;
  footballType: string | null;
  fieldAddress: string | null;
  fieldPrice: number | null;
  matchDate: string | null;
  league: string | null;
  description: string | null;
  status: string;
  createdAt: string;
  team: {
    id: string;
    name: string;
    gamesPlayed: number;
    gamesWon: number;
  };
  user: {
    id: string;
    name: string;
  };
  match?: {
    id: string;
  };
}

export default function PublicRequestsPage() {
  const { data: session } = useSession();
  const [activeTab, setActiveTab] = useState<'active' | 'historical'>('active');
  const [requests, setRequests] = useState<MatchRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<{message: string; type: ToastType} | null>(null);

  useEffect(() => {
    fetchRequests();
  }, [activeTab]);

  const fetchRequests = async () => {
    setLoading(true);
    try {
      const status = activeTab === 'active' ? 'active' : 'historical';
      const response = await fetch(`/api/public/requests?status=${status}`);
      if (response.ok) {
        const data = await response.json();
        setRequests(data);
      } else {
        setToast({ message: 'Error al cargar partidos. Intenta nuevamente.', type: 'error' });
      }
    } catch (error) {
      setToast({ message: 'Error de conexión. Verifica tu internet.', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const badges = {
      active: { text: 'Disponible', class: 'bg-black text-white border border-black', icon: '🟢' },
      matched: { text: 'Match Hecho', class: 'bg-gray-300 text-black border border-black', icon: '🤝' },
      completed: { text: 'Finalizado', class: 'bg-gray-700 text-white border border-black', icon: '✅' },
      cancelled: { text: 'Cancelado', class: 'bg-white text-black border border-black', icon: '❌' },
    };

    const badge = badges[status as keyof typeof badges] || badges.active;

    return (
      <span className={`px-3 py-1 text-xs font-semibold ${badge.class} flex items-center gap-1`}>
        <span>{badge.icon}</span>
        {badge.text}
      </span>
    );
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('es-AR', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <div className="min-h-screen bg-white">
      {/* Header Público */}
      <header className="bg-black text-white py-6 border-b-4 border-black">
        <div className="container mx-auto px-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Image
                src="https://tercer-tiempo.com/images/logo_tercertiempoNegro.png"
                alt="Tercer Tiempo"
                width={50}
                height={50}
                className="object-contain invert"
              />
              <div>
                <h1 className="text-3xl font-black uppercase tracking-wider">Tercer Tiempo</h1>
                <p className="text-gray-300 text-sm font-medium">
                  Encuentra tu próximo partido amistoso
                </p>
              </div>
            </div>
            <div className="flex gap-3">
              {session ? (
                <Link href="/dashboard" className="bg-white text-black border-2 border-white px-6 py-3 font-bold uppercase text-sm tracking-wide hover:bg-gray-200 transition-colors">
                  Mi Dashboard
                </Link>
              ) : (
                <>
                  <Link href="/login" className="bg-white text-black border-2 border-white px-6 py-3 font-bold uppercase text-sm tracking-wide hover:bg-gray-200 transition-colors">
                    Iniciar Sesión
                  </Link>
                  <Link href="/register" className="bg-gray-800 text-white border-2 border-white px-6 py-3 font-bold uppercase text-sm tracking-wide hover:bg-gray-700 transition-colors">
                    Registrarse
                  </Link>
                </>
              )}
            </div>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-primary mb-2">
            Partidos Amistosos {activeTab === 'active' ? 'Disponibles' : 'Históricos'}
          </h2>
          <p className="text-gray-600">
            {activeTab === 'active'
              ? 'Encuentra equipos que buscan rival para jugar'
              : 'Revisa partidos anteriores y matches realizados'}
          </p>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 mb-8">
          <button
            onClick={() => setActiveTab('active')}
            className={`px-6 py-3 font-bold uppercase text-sm tracking-wide transition-colors border-2 ${
              activeTab === 'active'
                ? 'bg-black text-white border-black'
                : 'bg-white border-black text-black hover:bg-gray-100'
            }`}
          >
            🟢 Partidos Disponibles
          </button>
          <button
            onClick={() => setActiveTab('historical')}
            className={`px-6 py-3 font-bold uppercase text-sm tracking-wide transition-colors border-2 ${
              activeTab === 'historical'
                ? 'bg-black text-white border-black'
                : 'bg-white border-black text-black hover:bg-gray-100'
            }`}
          >
            📚 Historial
          </button>
        </div>

        {loading ? (
          <LoadingState 
            message={activeTab === 'active' ? 'Buscando partidos disponibles...' : 'Cargando histórico de partidos...'} 
            icon="⚽" 
          />
        ) : requests.length === 0 ? (
          <div className="card text-center py-16">
            <div className="text-7xl mb-4">
              {activeTab === 'active' ? '🔍' : '📚'}
            </div>
            <h3 className="text-2xl font-bold text-primary mb-3">
              {activeTab === 'active'
                ? 'No hay partidos disponibles'
                : 'No hay partidos en el historial'}
            </h3>
            <p className="text-gray-600 mb-6">
              {activeTab === 'active'
                ? 'Vuelve más tarde o crea tu propia solicitud'
                : 'Cuando se realicen matches aparecerán aquí'}
            </p>
            {!session && (
              <div className="space-y-3">
                <p className="text-sm text-gray-500">
                  ¿Quieres publicar un partido?
                </p>
                <Link
                  href="/register"
                  className="btn-accent inline-block"
                >
                  Crear Cuenta Gratis
                </Link>
              </div>
            )}
            {session && (
              <Link
                href="/dashboard/requests/new"
                className="btn-primary inline-block"
              >
                Publicar Partido
              </Link>
            )}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {requests.map((req) => (
              <div key={req.id} className="card hover:shadow-lg transition-shadow">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <h3 className="text-xl font-bold text-primary mb-1">
                      {req.team.name}
                    </h3>
                    <p className="text-sm text-gray-600">
                      por {req.user.name}
                    </p>
                    {req.team.gamesPlayed > 0 && (
                      <p className="text-xs text-gray-500 mt-1">
                        📊 {req.team.gamesWon}V - {req.team.gamesPlayed - req.team.gamesWon}D/E
                      </p>
                    )}
                  </div>
                  {getStatusBadge(req.status)}
                </div>

                <div className="space-y-2 mb-4 text-sm">
                  {req.footballType && (
                    <p className="flex items-center text-gray-700">
                      <span className="font-semibold mr-2">⚽ Tipo:</span>
                      Fútbol {req.footballType}
                    </p>
                  )}
                  {req.league && (
                    <p className="flex items-center text-gray-700">
                      <span className="font-semibold mr-2">🏆 Liga:</span>
                      {req.league}
                    </p>
                  )}
                  {req.fieldAddress && (
                    <p className="flex items-center text-gray-700">
                      <span className="font-semibold mr-2">📍 Lugar:</span>
                      {req.fieldAddress.length > 30
                        ? req.fieldAddress.substring(0, 30) + '...'
                        : req.fieldAddress}
                    </p>
                  )}
                  {req.matchDate && (
                    <p className="flex items-center text-gray-700">
                      <span className="font-semibold mr-2">📅 Fecha:</span>
                      {formatDate(req.matchDate)}
                    </p>
                  )}
                  {req.fieldPrice && (
                    <p className="flex items-center text-gray-700">
                      <span className="font-semibold mr-2">💵 Precio:</span>
                      ${req.fieldPrice}
                    </p>
                  )}
                </div>

                {req.description && (
                  <p className="text-gray-600 text-sm mb-4 italic line-clamp-2">
                    "{req.description}"
                  </p>
                )}

                <div className="border-t pt-4">
                  <Link
                    href={`/partidos/${req.id}`}
                    className={`block text-center py-2 rounded-lg font-semibold transition-colors ${
                      req.status === 'active'
                        ? 'bg-accent text-white hover:bg-green-600'
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    }`}
                  >
                    {req.status === 'active' ? '👀 Ver Detalles y Aceptar' : '👀 Ver Detalles'}
                  </Link>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Info adicional */}
        {!session && requests.length > 0 && (
          <div className="card mt-8 bg-blue-50 border-blue-200">
            <div className="flex items-start gap-4">
              <div className="text-4xl">ℹ️</div>
              <div>
                <h3 className="font-bold text-primary mb-2">
                  ¿Quieres aceptar un partido?
                </h3>
                <p className="text-gray-700 mb-4">
                  Para aceptar partidos y conectar con otros equipos necesitas crear una cuenta.
                  Es <strong>100% gratis</strong> y solo toma un minuto.
                </p>
                <div className="flex gap-3">
                  <Link href="/register" className="btn-accent">
                    Crear Cuenta Gratis
                  </Link>
                  <Link href="/login" className="btn-secondary">
                    Ya tengo cuenta
                  </Link>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

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
