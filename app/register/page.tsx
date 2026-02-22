'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { signIn } from 'next-auth/react';
import Link from 'next/link';
import Image from 'next/image';
import Spinner from '@/components/Spinner';
import { withBasePath } from '@/lib/utils/base-path';

export default function RegisterPage() {
  const router = useRouter();
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    name: '',
    phone: '',
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    // Validaciones
    if (formData.password !== formData.confirmPassword) {
      setError('Las contraseñas no coinciden');
      return;
    }

    if (formData.password.length < 6) {
      setError('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setLoading(true);

    try {
      const response = await fetch(withBasePath('/api/auth/register'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: formData.email,
          password: formData.password,
          name: formData.name,
          phone: formData.phone,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        setError(data.error || 'Error al registrarse');
        setLoading(false);
      } else {
        // Mostrar mensaje de éxito
        setSuccess(true);
        
        // Iniciar sesión automáticamente
        const result = await signIn('credentials', {
          redirect: false,
          email: formData.email,
          password: formData.password,
        });

        if (result?.error) {
          // Si falla el login automático, redirigir a login
          setTimeout(() => {
            router.push('/login?registered=true');
          }, 1500);
        } else {
          // Login exitoso, redirigir al dashboard
          setTimeout(() => {
            router.push('/dashboard');
            router.refresh();
          }, 1500);
        }
      }
    } catch (error) {
      setError('Error al crear la cuenta');
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-50 to-gray-100 px-4 py-8">
      <div className="max-w-md w-full">
        {/* Logo/Header */}
        <div className="text-center mb-8">
          <div className="inline-block p-4 bg-white rounded-2xl mb-4 shadow-md">
            <Image
              src="/images/tercer-tiempo-logo.png"
              alt="Tercer Tiempo"
              width={64}
              height={64}
              className="object-contain"
            />
          </div>
          <h1 className="text-4xl font-bold text-primary mb-2">Tercer Tiempo</h1>
          <p className="text-gray-600">Crea tu cuenta</p>
        </div>

        {/* Formulario */}
        <div className="card">
          <h2 className="text-2xl font-bold text-primary mb-6">Registro</h2>

          {success && (
            <div className="bg-green-50 border-2 border-green-600 text-green-900 px-4 py-3 mb-4 rounded-lg animate-fadeIn">
              <div className="flex items-center gap-2">
                <span className="text-2xl">✅</span>
                <div>
                  <p className="font-semibold">¡Cuenta creada exitosamente!</p>
                  <p className="text-sm">Iniciando sesión...</p>
                </div>
              </div>
            </div>
          )}

          {error && (
            <div className="bg-red-50 border-2 border-red-600 text-red-900 px-4 py-3 mb-4">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label htmlFor="name" className="label">
                Nombre Completo
              </label>
              <input
                id="name"
                type="text"
                required
                disabled={loading || success}
                className="input"
                placeholder="Juan Pérez"
                value={formData.name}
                onChange={(e) =>
                  setFormData({ ...formData, name: e.target.value })
                }
              />
            </div>

            <div>
              <label htmlFor="email" className="label">
                Email
              </label>
              <input
                id="email"
                type="email"
                required
                disabled={loading || success}
                className="input"
                placeholder="tu@email.com"
                value={formData.email}
                onChange={(e) =>
                  setFormData({ ...formData, email: e.target.value })
                }
              />
            </div>

            <div>
              <label htmlFor="phone" className="label">
                Teléfono
              </label>
              <input
                id="phone"
                type="tel"
                required
                disabled={loading || success}
                className="input"
                placeholder="00000"
                value={formData.phone}
                onChange={(e) =>
                  setFormData({ ...formData, phone: e.target.value })
                }
              />
            </div>

            <div>
              <label htmlFor="password" className="label">
                Contraseña
              </label>
              <input
                id="password"
                type="password"
                required
                disabled={loading || success}
                className="input"
                placeholder="••••••••"
                value={formData.password}
                onChange={(e) =>
                  setFormData({ ...formData, password: e.target.value })
                }
              />
            </div>

            <div>
              <label htmlFor="confirmPassword" className="label">
                Confirmar Contraseña
              </label>
              <input
                id="confirmPassword"
                type="password"
                required
                disabled={loading || success}
                className="input"
                placeholder="••••••••"
                value={formData.confirmPassword}
                onChange={(e) =>
                  setFormData({ ...formData, confirmPassword: e.target.value })
                }
              />
            </div>

            <button
              type="submit"
              disabled={loading || success}
              className="btn-primary w-full flex items-center justify-center gap-2"
            >
              {loading && <Spinner size="sm" />}
              {success ? '✅ ¡Cuenta creada!' : loading ? 'Creando cuenta...' : 'Crear Cuenta'}
            </button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-gray-600">
              ¿Ya tienes cuenta?{' '}
              <Link
                href="/login"
                className="text-primary font-semibold hover:underline"
              >
                Inicia sesión
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
