'use client';

import { signOut, useSession } from 'next-auth/react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState } from 'react';
import Image from 'next/image';

export default function DashboardNav() {
  const { data: session } = useSession();
  const pathname = usePathname();
  const [showUserMenu, setShowUserMenu] = useState(false);

  const navItems = [
    { href: '/dashboard', label: 'Inicio', icon: '🏠' },
    { href: '/dashboard/teams', label: 'Equipos', icon: '⚽' },
    { href: '/dashboard/requests', label: 'Solicitudes', icon: '📋' },
    { href: '/dashboard/matches', label: 'Matches', icon: '🤝' },
    { href: '/dashboard/stats', label: 'Estadísticas', icon: '📊' },
    { href: '/partidos', label: 'Públicos', icon: '🌐' },
  ];

  const getInitials = (name?: string | null) => {
    if (!name) return 'U';
    return name
      .split(' ')
      .map(word => word[0])
      .join('')
      .toUpperCase()
      .substring(0, 2);
  };

  return (
    <nav className="bg-white shadow-md sticky top-0 z-50 border-b border-gray-200">
      <div className="container-custom">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link 
            href="/dashboard" 
            className="flex items-center space-x-3 group transition-transform hover:scale-105"
          >
            <div className="w-10 h-10 bg-white rounded-xl shadow-md flex items-center justify-center transform group-hover:rotate-3 transition-transform p-1.5">
              <Image
                src="/images/tercer-tiempo-logo.png"
                alt="Tercer Tiempo"
                width={40}
                height={40}
                className="object-contain"
              />
            </div>
            <div className="hidden sm:block">
              <span className="text-xl font-bold text-primary bg-gradient-to-r from-green-600 to-green-700 bg-clip-text text-transparent">
                Tercer Tiempo
              </span>
            </div>
          </Link>

          {/* Navigation */}
          <div className="hidden lg:flex items-center space-x-1">
            {navItems.map((item) => {
              const isActive = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`
                    relative px-4 py-2 rounded-lg transition-all duration-200 font-medium text-sm
                    flex items-center gap-2 group
                    ${
                      isActive
                        ? 'text-green-700 bg-green-50'
                        : 'text-gray-700 hover:text-green-600 hover:bg-gray-50'
                    }
                  `}
                >
                  <span className={`text-lg transform transition-transform group-hover:scale-110 ${isActive ? 'scale-110' : ''}`}>
                    {item.icon}
                  </span>
                  <span>{item.label}</span>
                  {isActive && (
                    <span className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-8 h-1 bg-gradient-to-r from-green-500 to-green-600 rounded-t-full" />
                  )}
                </Link>
              );
            })}
          </div>

          {/* User Menu */}
          <div className="flex items-center space-x-3">
            {/* Help Button - Desktop */}
            <Link
              href="/dashboard/help"
              className="hidden md:flex items-center justify-center w-10 h-10 rounded-full hover:bg-gray-100 text-gray-600 hover:text-green-600 transition-colors"
              title="Ayuda"
            >
              <span className="text-xl">💡</span>
            </Link>

            {/* User Avatar & Dropdown */}
            <div className="relative">
              <button
                onClick={() => setShowUserMenu(!showUserMenu)}
                className="flex items-center space-x-3 hover:bg-gray-50 rounded-xl px-2 sm:px-3 py-2 transition-colors group"
              >
                <div className="w-9 h-9 bg-gradient-to-br from-green-500 to-green-600 rounded-full flex items-center justify-center shadow-sm group-hover:shadow-md transition-shadow">
                  <span className="text-white text-sm font-bold">
                    {getInitials(session?.user?.name)}
                  </span>
                </div>
                <div className="text-left hidden sm:block">
                  <p className="text-sm font-semibold text-gray-800 leading-tight">
                    {session?.user?.name}
                  </p>
                  <p className="text-xs text-gray-500 leading-tight">Mi Perfil</p>
                </div>
                <svg 
                  className={`w-4 h-4 text-gray-400 transition-transform ${showUserMenu ? 'rotate-180' : ''}`} 
                  fill="none" 
                  stroke="currentColor" 
                  viewBox="0 0 24 24"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </button>

              {/* Dropdown Menu */}
              {showUserMenu && (
                <>
                  <div 
                    className="fixed inset-0 z-10" 
                    onClick={() => setShowUserMenu(false)}
                  />
                  <div className="absolute right-0 mt-2 w-64 bg-white rounded-xl shadow-xl border border-gray-200 py-2 z-20 animate-fadeIn">
                    <div className="px-4 py-3 border-b border-gray-100">
                      <p className="text-sm font-semibold text-gray-800">
                        {session?.user?.name}
                      </p>
                      <p className="text-xs text-gray-500 mt-1">
                        {session?.user?.email}
                      </p>
                    </div>
                    <button
                      onClick={() => signOut({ callbackUrl: '/login' })}
                      className="w-full text-left px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 transition-colors flex items-center gap-2"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                      </svg>
                      Cerrar Sesión
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Mobile Navigation */}
        <div className="lg:hidden pb-3 pt-2 flex overflow-x-auto space-x-2 scrollbar-hide">
          {navItems.map((item) => {
            const isActive = pathname === item.href;
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`
                  px-4 py-2 rounded-lg whitespace-nowrap transition-all font-medium text-sm
                  flex items-center gap-2 flex-shrink-0
                  ${
                    isActive
                      ? 'text-green-700 bg-green-50 shadow-sm'
                      : 'text-gray-600 bg-gray-50 hover:bg-gray-100'
                  }
                `}
              >
                <span className="text-base">{item.icon}</span>
                <span>{item.label}</span>
              </Link>
            );
          })}
          <Link
            href="/dashboard/help"
            className={`
              px-4 py-2 rounded-lg whitespace-nowrap transition-all font-medium text-sm
              flex items-center gap-2 flex-shrink-0
              ${
                pathname === '/dashboard/help'
                  ? 'text-green-700 bg-green-50 shadow-sm'
                  : 'text-gray-600 bg-gray-50 hover:bg-gray-100'
              }
            `}
          >
            <span className="text-base">💡</span>
            <span>Ayuda</span>
          </Link>
        </div>
      </div>
    </nav>
  );
}
