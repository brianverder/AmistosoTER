'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import Spinner from '@/components/Spinner';

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
  const [loading, setLoading] = useState(true);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  useEffect(() => {
    fetchRequests();
  }, [activeTab]);

  const fetchRequests = async () => {
    setLoading(true);
    try {
      const mode = activeTab === 'my' ? 'my' : 'available';
      const response = await fetch(`/api/requests?mode=${mode}`);
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
      }
    } catch (error) {
      console.error('Error fetching requests:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('¿Estás seguro de eliminar esta solicitud?')) {
      return;
    }

    setDeletingId(id);

    try {
      const response = await fetch(`/api/requests/${id}`, {
        method: 'DELETE',
      });

      if (response.ok) {
        fetchRequests();
      } else {
        alert('Error al eliminar solicitud');
      }
    } catch (error) {
      alert('Error al eliminar solicitud');
    } finally {
      setDeletingId(null);
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

      {loading ? (
        <div className="text-center py-12">
          <div className="text-4xl mb-2">⚽</div>
          <p className="text-gray-600">Cargando...</p>
        </div>
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
            <div key={req.id} className="card">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="text-xl font-bold text-primary mb-1">
                    {req.team.name}
                  </h3>
                  {activeTab === 'available' && req.user && (
                    <p className="text-sm text-gray-600">por {req.user.name}</p>
                  )}
                </div>
                {getStatusBadge(req.status)}
              </div>

              <div className="space-y-2 mb-4 text-sm">
                {req.footballType && (
                  <p className="flex items-center text-gray-700">
                    <span className="font-semibold mr-2">⚽ Tipo:</span>
                    Fútbol {req.footballType === '11' ? '11' : req.footballType === '8' ? '8' : req.footballType === '7' ? '7' : req.footballType === '5' ? '5' : req.footballType}
                  </p>
                )}
                {req.fieldName && (
                  <p className="flex items-center text-gray-700">
                    <span className="font-semibold mr-2">🏟️ Cancha:</span>
                    {req.fieldName}
                  </p>
                )}
                {req.country && (
                  <p className="flex items-center text-gray-700">
                    <span className="font-semibold mr-2">🌎 País:</span>
                    {req.country}
                  </p>
                )}
                {req.state && (
                  <p className="flex items-center text-gray-700">
                    <span className="font-semibold mr-2">📍 Depto/Prov:</span>
                    {req.state}
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
                    <span className="font-semibold mr-2">📍 Dirección:</span>
                    {req.fieldAddress}
                  </p>
                )}
                {req.matchDate && (
                  <p className="flex items-center text-gray-700">
                    <span className="font-semibold mr-2">📅 Fecha:</span>
                    {new Date(req.matchDate).toLocaleDateString('es', {
                      day: 'numeric',
                      month: 'short',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </p>
                )}
                {req.fieldPrice && (
                  <p className="flex items-center text-gray-700">
                    <span className="font-semibold mr-2">💵 Precio:</span>
                    ${req.fieldPrice}
                  </p>
                )}
                {req.description && (
                  <p className="text-gray-600 text-sm mt-3 italic">
                    "{req.description}"
                  </p>
                )}
              </div>

              <div className="flex gap-2 mt-4">
                {activeTab === 'available' ? (
                  <Link
                    href={`/dashboard/requests/${req.id}`}
                    className="btn-accent flex-1 text-center text-sm"
                  >
                    🤝 Hacer Match
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
                        onClick={() => handleDelete(req.id)}
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
    </div>
  );
}
