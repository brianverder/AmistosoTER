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
  const [showPassword, setShowPassword] = useState(false);

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
    <div className="relative min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 p-4 sm:p-6">
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute top-8 left-8 h-40 w-40 rounded-full bg-primary/5 blur-2xl" />
        <div className="absolute bottom-10 right-10 h-44 w-44 rounded-full bg-accent/10 blur-2xl" />
      </div>

      <div className="relative mx-auto flex min-h-[calc(100vh-2rem)] w-full max-w-2xl items-center justify-center">
        <section className="w-full rounded-3xl border border-slate-200 bg-white p-8 shadow-xl sm:p-10" data-registered-users={usersCount || '0'}>
          <div className="mb-8 text-center">
            <div className="mb-5 inline-flex items-center gap-4 rounded-2xl border border-slate-200 bg-slate-50 px-6 py-4">
              <Image
                src="/images/tercer-tiempo-logo.png"
                alt="Tercer Tiempo"
                width={104}
                height={104}
                className="object-contain"
              />
              <span className="text-3xl font-bold text-primary leading-none">Tercer Tiempo</span>
            </div>
            <h2 className="text-3xl font-bold text-slate-900">Iniciar sesión</h2>
            <p className="mt-2 text-sm text-slate-600">Coordina tu próximo partido</p>
          </div>

          {error && (
            <div className="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <input type="hidden" name="registeredUsersCount" value={usersCount} readOnly />

            <div>
              <label htmlFor="email" className="label text-slate-700">
                Email
              </label>
              <input
                id="email"
                type="email"
                required
                autoComplete="email"
                className="input border-slate-300 focus:border-primary"
                placeholder="tu@email.com"
                value={formData.email}
                onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              />
            </div>

            <div>
              <label htmlFor="password" className="label text-slate-700">
                Contraseña
              </label>
              <div className="relative">
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  required
                  autoComplete="current-password"
                  className="input pr-20 border-slate-300 focus:border-primary"
                  placeholder="••••••••"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                />
                <button
                  type="button"
                  className="absolute inset-y-0 right-3 my-auto text-xs font-semibold text-slate-600 hover:text-primary"
                  onClick={() => setShowPassword((prev) => !prev)}
                  aria-label={showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}
                >
                  {showPassword ? 'Ocultar' : 'Mostrar'}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="btn-primary mt-2 w-full flex items-center justify-center gap-2"
            >
              {loading && <Spinner size="sm" />}
              {loading ? 'Ingresando...' : 'Ingresar'}
            </button>
          </form>

          <div className="mt-6 text-center text-sm text-slate-600">
            ¿No tienes cuenta?{' '}
            <Link href="/register" className="font-semibold text-primary hover:underline">
              Regístrate
            </Link>
          </div>
        </section>
      </div>
    </div>
  );
}
