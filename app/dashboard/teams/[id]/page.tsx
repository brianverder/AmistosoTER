'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Spinner from '@/components/Spinner';
import Toast, { ToastType } from '@/components/Toast';
import ConfirmModal from '@/components/ConfirmModal';
import LoadingState from '@/components/LoadingState';
import { withBasePath } from '@/lib/utils/base-path';

interface Team {
  id: string;
  name: string;
  gamesWon: number;
  gamesLost: number;
  gamesDrawn: number;
  totalGames: number;
  createdAt: string;
}

export default function TeamDetailPage({ params }: { params: { id: string } }) {
  const router = useRouter();
  const [team, setTeam] = useState<Team | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [editName, setEditName] = useState('');
  const [error, setError] = useState('');
  const [updating, setUpdating] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: ToastType } | null>(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);

  useEffect(() => {
    fetchTeam();
  }, [params.id]);

  const fetchTeam = async () => {
    try {
      const response = await fetch(withBasePath(`/api/teams/${params.id}`));
      if (response.ok) {
        const data = await response.json();
        setTeam(data);
        setEditName(data.name);
        setError('');
      } else {
        setError('Equipo no encontrado');
      }
    } catch (error) {
      setError('Error de conexión. Intenta nuevamente.');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!editName.trim()) {
      setToast({ message: 'El nombre del equipo no puede estar vacío', type: 'warning' });
      return;
    }

    setError('');
    setUpdating(true);

    try {
      const response = await fetch(withBasePath(`/api/teams/${params.id}`), {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name: editName }),
      });

      if (response.ok) {
        setEditing(false);
        setToast({ message: 'Equipo actualizado exitosamente', type: 'success' });
        fetchTeam();
      } else {
        const data = await response.json();
        setToast({ message: data.error || 'Error al actualizar el equipo', type: 'error' });
      }
    } catch (error) {
      setToast({ message: 'Error de conexión. Verifica tu internet e intenta nuevamente.', type: 'error' });
    } finally {
      setUpdating(false);
    }
  };

  const handleDelete = async () => {
    setDeleting(true);

    try {
      const response = await fetch(withBasePath(`/api/teams/${params.id}`), {
        method: 'DELETE',
      });

      if (response.ok) {
        setToast({ message: 'Equipo eliminado exitosamente', type: 'success' });
        setTimeout(() => {
          router.push('/dashboard/teams');
          router.refresh();
        }, 1000);
      } else {
        const data = await response.json();
        setToast({ message: data.error || 'No se pudo eliminar el equipo', type: 'error' });
        setDeleting(false);
      }
    } catch (error) {
      setToast({ message: 'Error de conexión al eliminar. Intenta nuevamente.', type: 'error' });
      setDeleting(false);
    } finally {
      setShowDeleteModal(false);
    }
  };

  if (loading) {
    return <LoadingState message="Cargando datos del equipo..." icon="⚽" size="lg" />;
  }

  if (error || !team) {
    return (
      <div className="card text-center py-12">
        <div className="text-6xl mb-4">❌</div>
        <h2 className="text-2xl font-bold text-primary mb-2">Error</h2>
        <p className="text-gray-600 mb-6">{error || 'Equipo no encontrado'}</p>
        <Link href="/dashboard/teams" className="btn-primary inline-block">
          Volver a Mis Equipos
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-8">
        <Link
          href="/dashboard/teams"
          className="text-primary hover:underline mb-4 inline-block"
        >
          ← Volver a Mis Equipos
        </Link>
      </div>

      <div className="card mb-6">
        <div className="flex items-center justify-between mb-6">
          {editing ? (
            <form onSubmit={handleUpdate} className="flex-1">
              <input
                type="text"
                value={editName}
                onChange={(e) => setEditName(e.target.value)}
                className="input text-2xl font-bold"
                autoFocus
              />
              <div className="flex gap-2 mt-4">
                <button type="submit" disabled={updating} className="btn-primary text-sm flex items-center gap-2">
                  {updating && <Spinner size="sm" />}
                  {updating ? 'Guardando...' : 'Guardar'}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setEditing(false);
                    setEditName(team.name);
                  }}
                  className="btn-secondary text-sm"
                >
                  Cancelar
                </button>
              </div>
            </form>
          ) : (
            <>
              <div>
                <h1 className="text-3xl font-bold text-primary mb-2">{team.name}</h1>
                <p className="text-gray-600">
                  Creado el {new Date(team.createdAt).toLocaleDateString()}
                </p>
              </div>
              <div className="text-5xl">⚽</div>
            </>
          )}
        </div>

        {!editing && (
          <div className="flex gap-2">
            <Link href={`/dashboard/teams/${team.id}/stats`} className="btn-primary">
              📊 Ver Estadísticas Completas
            </Link>
            <button onClick={() => setEditing(true)} className="btn-secondary">
              ✏️ Editar Nombre
            </button>
            <button onClick={() => setShowDeleteModal(true)} disabled={deleting} className="btn-danger flex items-center gap-2">
              {deleting && <Spinner size="sm" />}
              {deleting ? 'Eliminando...' : '🗑️ Eliminar Equipo'}
            </button>
          </div>
        )}
      </div>

      {/* Estadísticas */}
      <div className="card">
        <h2 className="text-2xl font-bold text-primary mb-6">Estadísticas</h2>
        
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div className="text-center p-4 bg-gray-800 text-white border-2 border-black">
            <p className="text-4xl font-bold mb-1">{team.gamesWon}</p>
            <p className="text-sm">Partidos Ganados</p>
          </div>
          <div className="text-center p-4 bg-gray-200 border-2 border-black">
            <p className="text-4xl font-bold text-black mb-1">{team.gamesDrawn}</p>
            <p className="text-sm text-black">Empates</p>
          </div>
          <div className="text-center p-4 bg-white border-2 border-black">
            <p className="text-4xl font-bold text-black mb-1">{team.gamesLost}</p>
            <p className="text-sm text-black">Partidos Perdidos</p>
          </div>
          <div className="text-center p-4 bg-black text-white border-2 border-black">
            <p className="text-4xl font-bold mb-1">{team.totalGames}</p>
            <p className="text-sm">Total Jugados</p>
          </div>
        </div>

        {team.totalGames > 0 && (
          <div className="mt-6">
            <h3 className="font-semibold mb-3">Rendimiento</h3>
            <div className="w-full bg-gray-200 rounded-full h-6 flex overflow-hidden">
              {team.gamesWon > 0 && (
                <div
                  className="bg-gray-800 h-6 flex items-center justify-center text-white text-xs font-semibold"
                  style={{
                    width: `${(team.gamesWon / team.totalGames) * 100}%`,
                  }}
                >
                  {Math.round((team.gamesWon / team.totalGames) * 100)}%
                </div>
              )}
              {team.gamesDrawn > 0 && (
                <div
                  className="bg-gray-400 h-6 flex items-center justify-center text-white text-xs font-semibold"
                  style={{
                    width: `${(team.gamesDrawn / team.totalGames) * 100}%`,
                  }}
                >
                  {Math.round((team.gamesDrawn / team.totalGames) * 100)}%
                </div>
              )}
              {team.gamesLost > 0 && (
                <div
                  className="bg-gray-300 h-6 flex items-center justify-center text-black text-xs font-semibold"
                  style={{
                    width: `${(team.gamesLost / team.totalGames) * 100}%`,
                  }}
                >
                  {Math.round((team.gamesLost / team.totalGames) * 100)}%
                </div>
              )}
            </div>
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

      {/* Modal de confirmación de eliminación */}
      <ConfirmModal
        isOpen={showDeleteModal}
        onClose={() => setShowDeleteModal(false)}
        onConfirm={handleDelete}
        title="¿Eliminar equipo?"
        message={`Estás a punto de eliminar "${team?.name}". Esta acción no se puede deshacer y se perderán todas las estadísticas asociadas.`}
        confirmText="Sí, eliminar equipo"
        cancelText="Cancelar"
        type="danger"
        isLoading={deleting}
      />
    </div>
  );
}
