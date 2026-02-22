'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Spinner from '@/components/Spinner';
import Toast, { ToastType } from '@/components/Toast';
import { withBasePath } from '@/lib/utils/base-path';

export default function NewTeamPage() {
  const router = useRouter();
  const [teamName, setTeamName] = useState('');
  const [instagram, setInstagram] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState<{message: string; type: ToastType} | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!teamName.trim()) {
      setError('El nombre del equipo es requerido');
      setToast({ message: 'Por favor, ingresa un nombre para el equipo', type: 'warning' });
      return;
    }

    if (teamName.trim().length < 3) {
      setError('El nombre debe tener al menos 3 caracteres');
      setToast({ message: 'El nombre del equipo es demasiado corto', type: 'warning' });
      return;
    }

    setLoading(true);

    try {
      const payload: { name: string; instagram?: string } = {
        name: teamName,
      };

      if (instagram.trim()) {
        payload.instagram = instagram.trim();
      }

      const response = await fetch(withBasePath('/api/teams'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        const data = await response.json();
        const errorMsg = data.error || 'Error al crear el equipo';
        setError(errorMsg);
        setToast({ message: errorMsg, type: 'error' });
        return;
      }

      // Éxito
      setToast({ message: '¡Equipo creado exitosamente!', type: 'success' });
      
      // Redirigir después de un breve delay para mostrar el toast
      setTimeout(() => {
        router.push('/dashboard/teams');
        router.refresh();
      }, 1000);
    } catch (error) {
      const errorMsg = 'Error de conexión. Verifica tu internet e intenta nuevamente.';
      setError(errorMsg);
      setToast({ message: errorMsg, type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <Link
          href="/dashboard/teams"
          className="text-primary hover:underline mb-4 inline-block"
        >
          ← Volver a Mis Equipos
        </Link>
        <h1 className="text-3xl font-bold text-primary mb-2">Crear Nuevo Equipo</h1>
        <p className="text-gray-600">
          Registra un equipo para empezar a buscar partidos amistosos
        </p>
      </div>

      <div className="card">
        {error && (
          <div className="bg-red-50 border-2 border-accent-red text-accent-red px-4 py-3 rounded-lg mb-6">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="teamName" className="label">
              Nombre del Equipo
            </label>
            <input
              id="teamName"
              type="text"
              required
              className="input"
              placeholder="Ej: Los Cracks FC"
              value={teamName}
              onChange={(e) => setTeamName(e.target.value)}
              maxLength={100}
            />
            <p className="text-sm text-gray-500 mt-2">
              Elige un nombre que identifique a tu equipo
            </p>
          </div>

          <div>
            <label htmlFor="instagram" className="label">
              Instagram (opcional)
            </label>
            <input
              id="instagram"
              type="text"
              className="input"
              placeholder="Ej: @loscracksfc"
              value={instagram}
              onChange={(e) => setInstagram(e.target.value)}
              maxLength={100}
            />
            <p className="text-sm text-gray-500 mt-2">
              Se mostrará como dato de contacto cuando hagas match
            </p>
          </div>

          <div className="flex gap-4">
            <button
              type="submit"
              disabled={loading}
              className="btn-primary flex-1 flex items-center justify-center gap-2"
            >
              {loading && <Spinner size="sm" />}
              {loading ? 'Creando...' : 'Crear Equipo'}
            </button>
            <Link href="/dashboard/teams" className="btn-secondary flex-1 text-center">
              Cancelar
            </Link>
          </div>
        </form>
      </div>

      <div className="card mt-6 bg-blue-50 border-blue-200">
        <h3 className="font-semibold text-primary mb-2">💡 Consejo</h3>
        <p className="text-sm text-gray-700">
          Puedes crear múltiples equipos. Esto es útil si organizas partidos con diferentes
          grupos de amigos o si tienes varios equipos bajo tu gestión.
        </p>
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
