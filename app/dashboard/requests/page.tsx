'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import Spinner from '@/components/Spinner';
import Toast, { ToastType } from '@/components/Toast';
import ConfirmModal from '@/components/ConfirmModal';
import LoadingState from '@/components/LoadingState';
import AdSenseBanner from '@/components/AdSenseBanner';
import { withBasePath } from '@/lib/utils/base-path';

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
  createdAt: string;
  team: {
    id: string;
    name: string;
  };
  user?: {
    name: string;
    phone: string | null;
  };
  match?: {
    id: string;
  };
}

export default function RequestsPage() {
  const [activeTab, setActiveTab] = useState<'available' | 'my'>('available');
  const [requests, setRequests] = useState<MatchRequest[]>([]);
  const [footballTypeFilter, setFootballTypeFilter] = useState('');
  const [countryFilter, setCountryFilter] = useState('');
  const [loading, setLoading] = useState(true);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [toast, setToast] = useState<{ message: string; type: ToastType } | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<string | null>(null);

  useEffect(() => {
    fetchRequests();
  }, [activeTab, footballTypeFilter, countryFilter]);

  const fetchRequests = async () => {
    setLoading(true);
    try {
      const mode = activeTab === 'my' ? 'my' : 'available';
      const params = new URLSearchParams({ mode });

      if (footballTypeFilter) {
        params.set('footballType', footballTypeFilter);
      }

      if (countryFilter.trim()) {
        params.set('country', countryFilter.trim());
      }

      const response = await fetch(withBasePath(`/api/requests?${params.toString()}`));
      if (response.ok) {
        const data = await response.json();
        // Si es modo "available", la respuesta tiene formato { requests: [...], pagination: {...} }
        // Si es modo "my", la respuesta es directamente un array
        if (mode === 'available' && data.requests) {
          setRequests(data.requests);
        } else if (Array.isArray(data)) {
          setRequests(data);
        } else {
          setRequests([]);
        }
      } else {
        setToast({ message: 'Error al cargar las solicitudes. Intenta nuevamente.', type: 'error' });
      }
    } catch (error) {
      console.error('Error fetching requests:', error);
      setToast({ message: 'Problema de conexión. Verifica tu internet e intenta nuevamente.', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    setDeletingId(id);

    try {
      const response = await fetch(withBasePath(`/api/requests/${id}`), {
        method: 'DELETE',
      });

      if (response.ok) {
        setToast({ message: 'Solicitud eliminada exitosamente', type: 'success' });
        fetchRequests();
      } else {
        const data = await response.json();
        setToast({ message: data.error || 'No se pudo eliminar la solicitud', type: 'error' });
      }
    } catch (error) {
      setToast({ message: 'Error de conexión al eliminar. Intenta nuevamente.', type: 'error' });
    } finally {
      setDeletingId(null);
      setConfirmDelete(null);
    }
  };

  const getStatusBadge = (status: string) => {
    const badges = {
      active: { text: 'Activa', class: 'bg-black text-white border border-black' },
      matched: { text: 'Match', class: 'bg-gray-300 text-black border border-black' },
      completed: { text: 'Completada', class: 'bg-gray-700 text-white border border-black' },
      cancelled: { text: 'Cancelada', class: 'bg-white text-black border border-black' },
    };

    const badge = badges[status as keyof typeof badges] || badges.active;

    return (
      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${badge.class}`}>
        {badge.text}
      </span>
    );
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-primary mb-2">Solicitudes de Partidos</h1>
          <p className="text-gray-600">Encuentra rivales o publica tus partidos</p>
        </div>
        <Link href="/dashboard/requests/new" className="btn-primary">
          ➕ Nueva Solicitud
        </Link>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 mb-6">
        <button
          onClick={() => setActiveTab('available')}
          className={`px-6 py-3 rounded-lg font-semibold transition-colors ${
            activeTab === 'available'
              ? 'bg-primary text-white'
              : 'bg-white border-2 border-gray-200 text-gray-700 hover:bg-gray-50'
          }`}
        >
          🔍 Disponibles
        </button>
        <button
          onClick={() => setActiveTab('my')}
          className={`px-6 py-3 rounded-lg font-semibold transition-colors ${
            activeTab === 'my'
              ? 'bg-primary text-white'
              : 'bg-white border-2 border-gray-200 text-gray-700 hover:bg-gray-50'
          }`}
        >
          📋 Mis Solicitudes
        </button>
      </div>

      <div className="card mb-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label htmlFor="footballTypeFilter" className="label">
              Tipo de Fútbol
            </label>
            <select
              id="footballTypeFilter"
              className="input"
              value={footballTypeFilter}
              onChange={(e) => setFootballTypeFilter(e.target.value)}
            >
              <option value="">Todos</option>
              <option value="5">Fútbol 5</option>
              <option value="7">Fútbol 7</option>
              <option value="8">Fútbol 8</option>
              <option value="11">Fútbol 11</option>
              <option value="futsal">Futsal</option>
            </select>
          </div>

          <div>
            <label htmlFor="countryFilter" className="label">
              País
            </label>
            <select
              id="countryFilter"
              className="input"
              value={countryFilter}
              onChange={(e) => setCountryFilter(e.target.value)}
            >
              <option value="">Todos</option>
              <option value="Uruguay">Uruguay</option>
              <option value="Argentina">Argentina</option>
              <option value="Brasil">Brasil</option>
            </select>
          </div>

          <div className="flex items-end">
            <button
              type="button"
              onClick={() => {
                setFootballTypeFilter('');
                setCountryFilter('');
              }}
              className="btn-secondary w-full"
            >
              Limpiar filtros
            </button>
          </div>
        </div>
      </div>

      <AdSenseBanner
        adSlot={process.env.NEXT_PUBLIC_ADSENSE_REQUESTS_INLINE_SLOT || ''}
        className="mb-6"
        minHeight={100}
        adFormat="horizontal"
      />

      {loading ? (
        <LoadingState 
          message={activeTab === 'my' ? 'Cargando tus solicitudes...' : 'Buscando partidos disponibles...'}
          icon="🔍"
        />
      ) : requests.length === 0 ? (
        <div className="card text-center py-12">
          <div className="text-6xl mb-4">
            {activeTab === 'my' ? '📋' : '🔍'}
          </div>
          <h2 className="text-2xl font-bold text-primary mb-2">
            {activeTab === 'my'
              ? 'No has creado solicitudes todavía'
              : 'No hay solicitudes disponibles'}
          </h2>
          <p className="text-gray-600 mb-6">
            {activeTab === 'my'
              ? 'Crea una solicitud para encontrar rivales'
              : 'Vuelve más tarde o crea tu propia solicitud'}
          </p>
          {activeTab === 'my' && (
            <Link href="/dashboard/requests/new" className="btn-primary inline-block">
              Crear Primera Solicitud
            </Link>
          )}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {requests.map((req) => (
            <div key={req.id} className="card hover:shadow-lg transition-shadow duration-200 overflow-hidden">
              {/* Header con información clave en banda superior */}
              <div className="bg-gradient-to-r from-gray-800 to-gray-900 text-white px-4 py-3 -mx-6 -mt-6 mb-4">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <span className="text-2xl">🌎</span>
                    <span className="font-bold text-lg">
                      {req.country || 'Sin país'}
                    </span>
                  </div>
                  {getStatusBadge(req.status)}
                </div>
                {req.state && (
                  <p className="text-sm text-gray-300 flex items-center gap-1 ml-8">
                    📍 {req.state}
                  </p>
                )}
              </div>

              {/* Información principal: Fecha y Tipo de Fútbol */}
              <div className="grid grid-cols-2 gap-3 mb-4 pb-4 border-b-2 border-gray-100">
                <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
                  <p className="text-xs text-gray-600 mb-1 font-semibold">📅 FECHA</p>
                  {req.matchDate ? (
                    <p className="text-sm font-bold text-gray-900">
                      {new Date(req.matchDate).toLocaleDateString('es', {
                        day: 'numeric',
                        month: 'short',
                      })}
                      <br />
                      <span className="text-xs text-gray-600">
                        {new Date(req.matchDate).toLocaleTimeString('es', {
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </span>
                    </p>
                  ) : (
                    <p className="text-xs text-gray-500">A coordinar</p>
                  )}
                </div>

                <div className="bg-green-50 border border-green-200 rounded-lg p-3">
                  <p className="text-xs text-gray-600 mb-1 font-semibold">⚽ TIPO</p>
                  <p className="text-lg font-bold text-gray-900">
                    {req.footballType ? (
                      <>
                        Fútbol {req.footballType === 'futsal' ? 'Futsal' : req.footballType}
                      </>
                    ) : (
                      <span className="text-sm text-gray-500">No especificado</span>
                    )}
                  </p>
                </div>
              </div>

              {/* Equipo solicitante */}
              <div className="mb-4">
                <h3 className="text-xl font-bold text-primary mb-1 flex items-center gap-2">
                  👥 {req.team.name}
                </h3>
                {activeTab === 'available' && req.user && (
                  <p className="text-sm text-gray-600">Organizado por {req.user.name}</p>
                )}
              </div>

              {/* Detalles adicionales en grid compacto */}
              <div className="space-y-2 mb-4 text-xs">
                {req.league && (
                  <div className="flex items-center gap-2 bg-yellow-50 border border-yellow-200 rounded px-2 py-1">
                    <span className="text-base">🏆</span>
                    <span className="text-gray-700">
                      <strong>Liga:</strong> {req.league}
                    </span>
                  </div>
                )}

                {req.fieldName && (
                  <div className="flex items-center gap-2 bg-purple-50 border border-purple-200 rounded px-2 py-1">
                    <span className="text-base">🏟️</span>
                    <span className="text-gray-700">
                      <strong>Cancha:</strong> {req.fieldName}
                    </span>
                  </div>
                )}

                {req.fieldAddress && (
                  <div className="flex items-center gap-2 bg-gray-50 border border-gray-200 rounded px-2 py-1">
                    <span className="text-base">📍</span>
                    <span className="text-gray-700 truncate">
                      {req.fieldAddress}
                    </span>
                  </div>
                )}

                {req.fieldPrice && (
                  <div className="flex items-center gap-2 bg-green-50 border border-green-200 rounded px-2 py-1">
                    <span className="text-base">💵</span>
                    <span className="text-gray-700">
                      <strong>Precio:</strong> ${req.fieldPrice}
                    </span>
                  </div>
                )}
              </div>

              {/* Descripción (si existe) */}
              {req.description && (
                <div className="bg-gray-50 border border-gray-200 rounded-lg p-3 mb-4">
                  <p className="text-xs text-gray-700 italic line-clamp-2">
                    "{req.description}"
                  </p>
                </div>
              )}

              {/* Botones de acción */}
              <div className="flex gap-2 mt-4">
                {activeTab === 'available' ? (
                  <Link
                    href={`/dashboard/requests/${req.id}`}
                    className="btn-accent flex-1 text-center text-sm font-bold"
                  >
                    🤝 HACER MATCH
                  </Link>
                ) : (
                  <>
                    {req.match ? (
                      <Link
                        href={`/dashboard/matches/${req.match.id}`}
                        className="btn-secondary flex-1 text-center text-sm"
                      >
                        Ver Match
                      </Link>
                    ) : (
                      <button
                        onClick={() => setConfirmDelete(req.id)}
                        disabled={deletingId === req.id}
                        className="btn-danger flex-1 text-sm flex items-center justify-center gap-2"
                      >
                        {deletingId === req.id && <Spinner size="sm" />}
                        {deletingId === req.id ? 'Eliminando...' : '🗑️ Eliminar'}
                      </button>
                    )}
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Toast de notificaciones */}
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}

      {/* Modal de confirmación de eliminación */}
      <ConfirmModal
        isOpen={!!confirmDelete}
        onClose={() => setConfirmDelete(null)}
        onConfirm={() => confirmDelete && handleDelete(confirmDelete)}
        title="¿Eliminar solicitud?"
        message="Esta acción no se puede deshacer. La solicitud se eliminará permanentemente."
        confirmText="Sí, eliminar"
        cancelText="Cancelar"
        type="danger"
        isLoading={!!deletingId}
      />

      <AdSenseBanner
        adSlot={process.env.NEXT_PUBLIC_ADSENSE_REQUESTS_MULTIPLEX_SLOT || ''}
        className="mt-8"
        minHeight={250}
        adFormat="auto"
      />
    </div>
  );
}
