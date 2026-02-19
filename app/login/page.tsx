'use client';

import { useEffect, useState } from 'react';
import { signIn } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import Spinner from '@/components/Spinner';

export default function LoginPage() {
  const router = useRouter();
  const [formData, setFormData] = useState({
    email: '',
    password: '',
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [usersCount, setUsersCount] = useState('');

  useEffect(() => {
    const fetchUsersCount = async () => {
      try {
        const response = await fetch('/api/public/users-count', { cache: 'no-store' });
        if (!response.ok) return;

        const data = await response.json();
        if (typeof data.count === 'number') {
          setUsersCount(String(data.count));
        }
      } catch {
      }
    };

    fetchUsersCount();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const result = await signIn('credentials', {
        redirect: false,
        email: formData.email,
        password: formData.password,
      });

      if (result?.error) {
        setError('Credenciales inválidas');
      } else {
        // Verificar si hay returnUrl en query params
        const searchParams = new URLSearchParams(window.location.search);
        const returnUrl = searchParams.get('returnUrl') || '/dashboard';
        router.push(returnUrl);
        router.refresh();
      }
    } catch (error) {
      setError('Error al iniciar sesión');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-gray-50 to-gray-100 px-4">
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
          <p className="text-gray-600">Coordina partidos amistosos</p>
        </div>

        {/* Formulario */}
        <div className="card" data-registered-users={usersCount || '0'}>
          <h2 className="text-2xl font-bold text-primary mb-6">Iniciar Sesión</h2>

          {error && (
            <div className="bg-red-50 border-2 border-red-600 text-red-900 px-4 py-3 mb-4">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <input
              type="hidden"
              name="registeredUsersCount"
              value={usersCount}
              readOnly
            />

            <div>
              <label htmlFor="email" className="label">
                Email
              </label>
              <input
                id="email"
                type="email"
                required
                className="input"
                placeholder="tu@email.com"
                value={formData.email}
                onChange={(e) =>
                  setFormData({ ...formData, email: e.target.value })
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
                className="input"
                placeholder="••••••••"
                value={formData.password}
                onChange={(e) =>
                  setFormData({ ...formData, password: e.target.value })
                }
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="btn-primary w-full flex items-center justify-center gap-2"
            >
              {loading && <Spinner size="sm" />}
              {loading ? 'Ingresando...' : 'Ingresar'}
            </button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-gray-600">
              ¿No tienes cuenta?{' '}
              <Link
                href="/register"
                className="text-primary font-semibold hover:underline"
              >
                Regístrate
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
