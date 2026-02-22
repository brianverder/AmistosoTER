'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import Spinner from '@/components/Spinner';
import Toast, { ToastType } from '@/components/Toast';
import LoadingState from '@/components/LoadingState';
import { withBasePath } from '@/lib/utils/base-path';

interface Team {
  id: string;
  name: string;
}

export default function NewRequestPage() {
  const router = useRouter();
  const [teams, setTeams] = useState<Team[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadingTeams, setLoadingTeams] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [toast, setToast] = useState<{message: string; type: ToastType} | null>(null);
  const [formData, setFormData] = useState({
    teamId: '',
    footballType: '',
    fieldName: '',
    fieldAddress: '',
    country: '',
    state: '',
    fieldPrice: '',
    matchDate: '',
    league: '',
    description: '',
  });

  useEffect(() => {
    fetchTeams();
  }, []);

  const fetchTeams = async () => {
    try {
      const response = await fetch(withBasePath('/api/teams'));
      if (response.ok) {
        const data = await response.json();
        setTeams(data);
      } else {
        setToast({ message: 'Error al cargar tus equipos', type: 'error' });
      }
    } catch (error) {
      setToast({ message: 'Error de conexión al cargar equipos', type: 'error' });
    } finally {
      setLoadingTeams(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!formData.teamId) {
      setError('Debes seleccionar un equipo');
      setToast({ message: 'Por favor, selecciona un equipo', type: 'warning' });
      return;
    }

    // Validación adicional de precio
    if (formData.fieldPrice && parseFloat(formData.fieldPrice) < 0) {
      setError('El precio no puede ser negativo');
      setToast({ message: 'El precio de la cancha debe ser mayor o igual a 0', type: 'warning' });
      return;
    }

    setLoading(true);

    try {
      // Preparar datos con tipos correctos
      const requestData = {
        teamId: formData.teamId,
        footballType: formData.footballType || undefined,
        fieldName: formData.fieldName || undefined,
        fieldAddress: formData.fieldAddress || undefined,
        country: formData.country || undefined,
        state: formData.state || undefined,
        fieldPrice: formData.fieldPrice ? parseFloat(formData.fieldPrice) : undefined,
        matchDate: formData.matchDate || undefined,
        league: formData.league || undefined,
        description: formData.description || undefined,
      };

      const response = await fetch(withBasePath('/api/requests'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestData),
      });

      if (!response.ok) {
        const data = await response.json();
        const errorMsg = data.error || 'Error al crear la solicitud';
        setError(errorMsg);
        setToast({ message: errorMsg, type: 'error' });
        return;
      }

      // Mostrar mensaje de éxito
      setSuccess(true);
      setToast({ message: '¡Solicitud creada exitosamente! Redirigiendo...', type: 'success' });
      
      // Redirigir después de 1.5 segundos
      setTimeout(() => {
        router.push('/dashboard/requests');
        router.refresh();
      }, 1500);
    } catch (error) {
      const errorMsg = 'Error de conexión. Verifica tu internet e intenta nuevamente.';
      setError(errorMsg);
      setToast({ message: errorMsg, type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto">
      {loadingTeams ? (
        <LoadingState message="Cargando tus equipos..." icon="⚽" />
      ) : (
        <>
          <div className="mb-8">
            <Link
              href="/dashboard/requests"
              className="text-primary hover:underline mb-4 inline-block"
            >
              ← Volver a Solicitudes
            </Link>
            <div className="flex items-center gap-4 mb-4">
              <Image
                src="https://tercer-tiempo.com/images/logo_tercertiempoNegro.png"
                alt="Tercer Tiempo"
                width={60}
                height={60}
                className="object-contain"
              />
              <div>
                <h1 className="text-3xl font-bold text-primary">
                  Nueva Solicitud de Partido
                </h1>
                <p className="text-gray-600">
                  Publica los detalles de tu partido para encontrar un rival
                </p>
              </div>
            </div>
          </div>

      {/* Mensaje de éxito */}
      {success && (
        <div className="card bg-green-50 border-2 border-accent mb-6 animate-pulse">
          <div className="flex items-center gap-3">
            <span className="text-3xl">✅</span>
            <div>
              <h3 className="font-bold text-accent text-lg">¡Solicitud Creada!</h3>
              <p className="text-gray-700">Tu solicitud ha sido publicada exitosamente. Redirigiendo...</p>
            </div>
          </div>
        </div>
      )}

      {teams.length === 0 && (
        <div className="card bg-yellow-50 border-yellow-200 mb-6">
          <h3 className="font-semibold text-primary mb-2">⚠️ No tienes equipos</h3>
          <p className="text-sm text-gray-700 mb-4">
            Necesitas crear al menos un equipo antes de publicar una solicitud.
          </p>
          <Link href="/dashboard/teams/new" className="btn-primary inline-block text-sm">
            Crear Equipo
          </Link>
        </div>
      )}

      <div className="card">
        {error && (
          <div className="bg-red-50 border-2 border-accent-red text-accent-red px-4 py-3 rounded-lg mb-6">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="teamId" className="label">
              Equipo * <span className="text-gray-500 font-normal">(requerido)</span>
            </label>
            <select
              id="teamId"
              required
              className="input"
              value={formData.teamId}
              onChange={(e) =>
                setFormData({ ...formData, teamId: e.target.value })
              }
            >
              <option value="">Selecciona tu equipo</option>
              {teams.map((team) => (
                <option key={team.id} value={team.id}>
                  {team.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label htmlFor="footballType" className="label">
              Tipo de Fútbol
            </label>
            <select
              id="footballType"
              className="input"
              value={formData.footballType}
              onChange={(e) =>
                setFormData({ ...formData, footballType: e.target.value })
              }
            >
              <option value="">Selecciona tipo (opcional)</option>
              <option value="11">Fútbol 11</option>
              <option value="8">Fútbol 8</option>
              <option value="7">Fútbol 7</option>
              <option value="5">Fútbol 5</option>
              <option value="futsal">Futsal</option>
            </select>
          </div>

          <div>
            <label htmlFor="fieldName" className="label">
              Nombre de la Cancha
            </label>
            <input
              id="fieldName"
              type="text"
              className="input"
              placeholder="Ej: Complejo Deportivo Charrúa"
              value={formData.fieldName}
              onChange={(e) =>
                setFormData({ ...formData, fieldName: e.target.value })
              }
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="country" className="label">
                País
              </label>
              <select
                id="country"
                className="input"
                value={formData.country}
                onChange={(e) =>
                  setFormData({ ...formData, country: e.target.value })
                }
              >
                <option value="">Selecciona país (opcional)</option>
                <option value="Uruguay">Uruguay</option>
                <option value="Argentina">Argentina</option>
                <option value="Brasil">Brasil</option>
              </select>
            </div>

            <div>
              <label htmlFor="state" className="label">
                Departamento/Provincia
              </label>
              <input
                id="state"
                type="text"
                className="input"
                placeholder="Ej: Montevideo, Canelones, Maldonado"
                value={formData.state}
                onChange={(e) =>
                  setFormData({ ...formData, state: e.target.value })
                }
              />
            </div>
          </div>

          <div>
            <label htmlFor="fieldAddress" className="label">
              Dirección de la Cancha
            </label>
            <input
              id="fieldAddress"
              type="text"
              className="input"
              placeholder="Ej: Av. Italia 2580, Montevideo"
              value={formData.fieldAddress}
              onChange={(e) =>
                setFormData({ ...formData, fieldAddress: e.target.value })
              }
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label htmlFor="matchDate" className="label">
                Fecha y Hora
              </label>
              <input
                id="matchDate"
                type="datetime-local"
                className="input"
                value={formData.matchDate}
                onChange={(e) =>
                  setFormData({ ...formData, matchDate: e.target.value })
                }
              />
            </div>

            <div>
              <label htmlFor="fieldPrice" className="label">
                Precio de la Cancha
              </label>
              <input
                id="fieldPrice"
                type="number"
                step="0.01"
                min="0"
                className="input"
                placeholder="Ej: 2500"
                value={formData.fieldPrice}
                onChange={(e) =>
                  setFormData({ ...formData, fieldPrice: e.target.value })
                }
              />
            </div>
          </div>

          <div>
            <label htmlFor="league" className="label">
              Liga del Equipo
            </label>
            <input
              id="league"
              type="text"
              className="input"
              placeholder="Ej: Liga Universitaria, OFI, Liga Amateur"
              value={formData.league}
              onChange={(e) =>
                setFormData({ ...formData, league: e.target.value })
              }
            />
            <p className="text-sm text-gray-500 mt-2">
              Indica en qué liga juega tu equipo (opcional)
            </p>
          </div>

          <div>
            <label htmlFor="description" className="label">
              Descripción / Notas
            </label>
            <textarea
              id="description"
              rows={4}
              className="input"
              placeholder="Información adicional sobre el partido..."
              value={formData.description}
              onChange={(e) =>
                setFormData({ ...formData, description: e.target.value })
              }
            />
          </div>

          <div className="flex gap-4">
            <button
              type="submit"
              disabled={loading}
              className="btn-primary flex-1 flex items-center justify-center gap-2"
            >
              {loading && <Spinner size="sm" />}
              {loading ? 'Publicando...' : '📢 Publicar Solicitud'}
            </button>
            <Link
              href="/dashboard/requests"
              className="btn-secondary flex-1 text-center"
            >
              Cancelar
            </Link>
          </div>
        </form>
      </div>

      <div className="card mt-6 bg-blue-50 border-blue-200">
        <h3 className="font-semibold text-primary mb-2 flex items-center gap-2">
          <Image
            src="https://tercer-tiempo.com/images/logo_tercertiempoNegro.png"
            alt="Tercer Tiempo"
            width={24}
            height={24}
            className="object-contain"
          />
          💡 Consejos para tu solicitud
        </h3>
        <ul className="text-sm text-gray-700 space-y-2">
          <li>✓ <strong>Equipo:</strong> Es el único campo obligatorio</li>
          <li>✓ <strong>Detalles completos:</strong> Cuanta más información proporciones, más fácil será encontrar rival</li>
          <li>✓ <strong>Liga:</strong> Ayuda a encontrar equipos de nivel similar</li>
          <li>✓ <strong>Contacto:</strong> Otros usuarios verán tu email y teléfono al hacer match</li>
          <li>✓ <strong>Estado:</strong> Tu solicitud se publicará como "Activa" automáticamente</li>
        </ul>
      </div>
        </>
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
