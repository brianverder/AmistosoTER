import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import Link from 'next/link';
import AdSenseBanner from '@/components/AdSenseBanner';

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);
  
  if (!session?.user) {
    return null;
  }

  // Obtener estadísticas del usuario
  const [teams, matchRequests, matches, recentRequests, activeMatches, userTeams, topTeams] = await Promise.all([
    prisma.team.count({
      where: { userId: session.user.id },
    }),
    prisma.matchRequest.count({
      where: { userId: session.user.id },
    }),
    prisma.match.count({
      where: {
        OR: [
          { userId1: session.user.id },
          { userId2: session.user.id },
        ],
      },
    }),
    // Últimas 3 solicitudes del usuario
    prisma.matchRequest.findMany({
      where: { userId: session.user.id },
      include: { team: true, match: true },
      orderBy: { createdAt: 'desc' },
      take: 3,
    }),
    // Matches activos (sin resultado)
    prisma.match.findMany({
      where: {
        OR: [
          { userId1: session.user.id },
          { userId2: session.user.id },
        ],
        matchResult: null,
      },
      include: {
        team1: true,
        team2: true,
      },
      orderBy: { createdAt: 'desc' },
      take: 3,
    }),
    // Equipos del usuario con estadísticas
    prisma.team.findMany({
      where: { userId: session.user.id },
      orderBy: { gamesWon: 'desc' },
      take: 1,
    }),
    // Top 5 equipos con más victorias de toda la aplicación
    prisma.team.findMany({
      where: {
        gamesWon: { gt: 0 }, // Solo equipos con al menos 1 victoria
      },
      include: {
        user: {
          select: {
            name: true,
          },
        },
      },
      orderBy: { gamesWon: 'desc' },
      take: 5,
    }),
  ]);

  const stats = [
    { label: 'Equipos', value: teams, icon: '⚽', href: '/dashboard/teams' },
    { label: 'Solicitudes', value: matchRequests, icon: '📋', href: '/dashboard/requests' },
    { label: 'Partidos', value: matches, icon: '🏆', href: '/dashboard/matches' },
  ];

  // Estadísticas del mejor equipo
  const bestTeam = userTeams[0];
  const totalGames = bestTeam?.totalGames || 0;
  const winRate = totalGames > 0 ? ((bestTeam.gamesWon / totalGames) * 100).toFixed(0) : 0;

  // Helper para obtener estado de solicitud
  const getStatusBadge = (status: string) => {
    const badges = {
      active: { text: 'Activa', class: 'bg-green-100 text-green-800 border-2 border-green-300' },
      matched: { text: 'Match', class: 'bg-blue-100 text-blue-800 border-2 border-blue-300' },
      completed: { text: 'Completada', class: 'bg-gray-100 text-gray-800 border-2 border-gray-300' },
      cancelled: { text: 'Cancelada', class: 'bg-red-100 text-red-800 border-2 border-red-300' },
    };
    const badge = badges[status as keyof typeof badges] || badges.active;
    return <span className={`px-3 py-1 text-xs font-bold rounded-full ${badge.class}`}>{badge.text}</span>;
  };

  return (
    <div className="space-y-8">
      {/* Hero Section - Bienvenida */}
      <div className="relative overflow-hidden bg-gradient-to-br from-green-50 via-white to-blue-50 rounded-2xl p-8 border-2 border-gray-200 shadow-sm">
        <div className="relative z-10">
          <div className="flex items-center gap-3 mb-3">
            <span className="text-5xl">👋</span>
            <div>
              <h1 className="text-4xl font-bold text-gray-900">
                ¡Hola, {session.user.name}!
              </h1>
              <p className="text-gray-600 text-lg">
                Listo para coordinar tu próximo partido
              </p>
            </div>
          </div>
        </div>
        <div className="absolute top-0 right-0 opacity-10 text-[200px]">⚽</div>
      </div>

      {/* Estadísticas Principales */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {stats.map((stat, index) => (
          <Link
            key={stat.label}
            href={stat.href}
            className="group relative overflow-hidden bg-white rounded-2xl p-6 border-2 border-gray-200 hover:border-green-500 hover:shadow-xl transition-all duration-300 transform hover:-translate-y-1"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-2">
                  {stat.label}
                </p>
                <p className="text-5xl font-bold text-gray-900">{stat.value}</p>
              </div>
              <div className="text-6xl opacity-20 group-hover:opacity-30 group-hover:scale-110 transition-all duration-300">
                {stat.icon}
              </div>
            </div>
            <div className="absolute bottom-0 left-0 w-full h-1 bg-gradient-to-r from-green-500 to-blue-500 transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300"></div>
          </Link>
        ))}
      </div>

      <AdSenseBanner
        adSlot={process.env.NEXT_PUBLIC_ADSENSE_DASHBOARD_INLINE_SLOT || ''}
        className="mb-2"
        minHeight={100}
        adFormat="horizontal"
      />

      <div className="grid grid-cols-1 lg:grid-cols-[1fr,380px] gap-6">
        {/* Columna Principal */}
        <div className="space-y-6">
          {/* Mejor Equipo */}
          {bestTeam && totalGames > 0 && (
            <div className="bg-gradient-to-br from-amber-50 to-orange-50 rounded-2xl p-6 border-2 border-amber-200 shadow-sm">
              <div className="flex items-start justify-between mb-6">
                <div className="flex items-center gap-3">
                  <span className="text-5xl">🏆</span>
                  <div>
                    <h2 className="text-2xl font-bold text-gray-900">
                      {bestTeam.name}
                    </h2>
                    <p className="text-sm text-gray-600">Tu equipo estrella</p>
                  </div>
                </div>
                <div className="text-center bg-white rounded-xl px-6 py-3 border-2 border-amber-300 shadow-sm">
                  <p className="text-4xl font-bold text-amber-600">{winRate}%</p>
                  <p className="text-xs text-gray-600 font-semibold uppercase">Efectividad</p>
                </div>
              </div>
              
              <div className="grid grid-cols-4 gap-3">
                <div className="bg-white rounded-xl p-4 text-center border-2 border-gray-200 shadow-sm">
                  <p className="text-3xl font-bold text-gray-900">{totalGames}</p>
                  <p className="text-xs text-gray-600 font-semibold uppercase mt-1">Jugados</p>
                </div>
                <div className="bg-green-500 rounded-xl p-4 text-center border-2 border-green-600 shadow-sm">
                  <p className="text-3xl font-bold text-white">{bestTeam.gamesWon}</p>
                  <p className="text-xs text-green-100 font-semibold uppercase mt-1">Ganados</p>
                </div>
                <div className="bg-gray-300 rounded-xl p-4 text-center border-2 border-gray-400 shadow-sm">
                  <p className="text-3xl font-bold text-gray-900">{bestTeam.gamesDrawn}</p>
                  <p className="text-xs text-gray-700 font-semibold uppercase mt-1">Empates</p>
                </div>
                <div className="bg-red-500 rounded-xl p-4 text-center border-2 border-red-600 shadow-sm">
                  <p className="text-3xl font-bold text-white">{bestTeam.gamesLost}</p>
                  <p className="text-xs text-red-100 font-semibold uppercase mt-1">Perdidos</p>
                </div>
              </div>
            </div>
          )}

          {/* Matches Activos */}
          {activeMatches.length > 0 && (
            <div className="bg-white rounded-2xl p-6 border-2 border-gray-200 shadow-sm">
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                  <span className="text-4xl">🤝</span>
                  <div>
                    <h2 className="text-2xl font-bold text-gray-900">Matches Pendientes</h2>
                    <p className="text-sm text-gray-600">Esperando resultado</p>
                  </div>
                </div>
                <Link 
                  href="/dashboard/matches" 
                  className="text-sm font-semibold text-green-600 hover:text-green-700 hover:underline"
                >
                  Ver todos →
                </Link>
              </div>
              
              <div className="space-y-3">
                {activeMatches.map((match: any) => {
                  const isUserTeam1 = match.userId1 === session.user.id;
                  const userTeam = isUserTeam1 ? match.team1 : match.team2;
                  const opponentTeam = isUserTeam1 ? match.team2 : match.team1;
                  
                  return (
                    <Link
                      key={match.id}
                      href={`/dashboard/matches/${match.id}`}
                      className="block bg-gradient-to-r from-blue-50 to-green-50 rounded-xl p-5 hover:shadow-md transition-all duration-200 border-2 border-gray-200 hover:border-green-400"
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4 flex-1">
                          <div className="text-center min-w-[100px]">
                            <p className="font-bold text-gray-900 truncate">{userTeam.name}</p>
                            <p className="text-xs text-gray-500">Tu equipo</p>
                          </div>
                          <span className="text-2xl text-gray-400">⚔️</span>
                          <div className="text-center min-w-[100px]">
                            <p className="font-bold text-gray-900 truncate">{opponentTeam.name}</p>
                            <p className="text-xs text-gray-500">Rival</p>
                          </div>
                        </div>
                        <span className="text-xs px-4 py-2 bg-yellow-100 text-yellow-800 rounded-full font-bold border-2 border-yellow-300">
                          ⏳ Pendiente
                        </span>
                      </div>
                    </Link>
                  );
                })}
              </div>
            </div>
          )}

          {/* Solicitudes Recientes */}
          {recentRequests.length > 0 && (
            <div className="bg-white rounded-2xl p-6 border-2 border-gray-200 shadow-sm">
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-3">
                  <span className="text-4xl">📋</span>
                  <div>
                    <h2 className="text-2xl font-bold text-gray-900">Mis Solicitudes</h2>
                    <p className="text-sm text-gray-600">Últimas publicaciones</p>
                  </div>
                </div>
                <Link 
                  href="/dashboard/requests" 
                  className="text-sm font-semibold text-green-600 hover:text-green-700 hover:underline"
                >
                  Ver todas →
                </Link>
              </div>
              
              <div className="space-y-3">
                {recentRequests.map((req: any) => (
                  <div key={req.id} className="bg-gray-50 rounded-xl p-5 border-2 border-gray-200 hover:border-green-300 transition-colors">
                    <div className="flex items-center justify-between mb-3">
                      <h3 className="font-bold text-gray-900 text-lg">{req.team.name}</h3>
                      {getStatusBadge(req.status)}
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm text-gray-600">
                      {req.footballType && (
                        <div className="flex items-center gap-2">
                          <span>⚽</span>
                          <span>Fútbol {req.footballType}</span>
                        </div>
                      )}
                      {req.matchDate && (
                        <div className="flex items-center gap-2">
                          <span>📅</span>
                          <span>{new Date(req.matchDate).toLocaleDateString('es', { day: 'numeric', month: 'short' })}</span>
                        </div>
                      )}
                      {req.fieldAddress && (
                        <div className="flex items-center gap-2 col-span-2">
                          <span>📍</span>
                          <span className="truncate">{req.fieldAddress}</span>
                        </div>
                      )}
                    </div>
                    {req.match && (
                      <Link
                        href={`/dashboard/matches/${req.match.id}`}
                        className="inline-flex items-center gap-1 mt-3 text-sm text-green-600 hover:text-green-700 font-semibold hover:underline"
                      >
                        Ver match →
                      </Link>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Acciones Rápidas */}
          <div className="bg-white rounded-2xl p-6 border-2 border-gray-200 shadow-sm">
            <div className="flex items-center gap-3 mb-6">
              <span className="text-4xl">⚡</span>
              <div>
                <h2 className="text-2xl font-bold text-gray-900">Acciones Rápidas</h2>
                <p className="text-sm text-gray-600">¿Qué quieres hacer?</p>
              </div>
            </div>
            
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <Link
                href="/dashboard/teams/new"
                className="group bg-gradient-to-br from-blue-50 to-blue-100 p-6 rounded-xl border-2 border-blue-200 hover:border-blue-400 hover:shadow-lg transition-all duration-300 text-center transform hover:-translate-y-1"
              >
                <div className="text-5xl mb-3 group-hover:scale-110 transition-transform">➕</div>
                <h3 className="text-sm font-bold text-gray-900 mb-1">
                  Crear Equipo
                </h3>
                <p className="text-xs text-gray-600">
                  Registra tu equipo
                </p>
              </Link>

              <Link
                href="/dashboard/requests/new"
                className="group bg-gradient-to-br from-green-50 to-green-100 p-6 rounded-xl border-2 border-green-200 hover:border-green-400 hover:shadow-lg transition-all duration-300 text-center transform hover:-translate-y-1"
              >
                <div className="text-5xl mb-3 group-hover:scale-110 transition-transform">📢</div>
                <h3 className="text-sm font-bold text-gray-900 mb-1">
                  Publicar Solicitud
                </h3>
                <p className="text-xs text-gray-600">
                  Busca un rival
                </p>
              </Link>

              <Link
                href="/dashboard/requests"
                className="group bg-gradient-to-br from-purple-50 to-purple-100 p-6 rounded-xl border-2 border-purple-200 hover:border-purple-400 hover:shadow-lg transition-all duration-300 text-center transform hover:-translate-y-1"
              >
                <div className="text-5xl mb-3 group-hover:scale-110 transition-transform">🔍</div>
                <h3 className="text-sm font-bold text-gray-900 mb-1">
                  Buscar Partidos
                </h3>
                <p className="text-xs text-gray-600">
                  Explora solicitudes
                </p>
              </Link>

              <Link
                href="/dashboard/stats"
                className="group bg-gradient-to-br from-orange-50 to-orange-100 p-6 rounded-xl border-2 border-orange-200 hover:border-orange-400 hover:shadow-lg transition-all duration-300 text-center transform hover:-translate-y-1"
              >
                <div className="text-5xl mb-3 group-hover:scale-110 transition-transform">📊</div>
                <h3 className="text-sm font-bold text-gray-900 mb-1">
                  Estadísticas
                </h3>
                <p className="text-xs text-gray-600">
                  Ve tu rendimiento
                </p>
              </Link>
            </div>
          </div>

          <AdSenseBanner
            adSlot={process.env.NEXT_PUBLIC_ADSENSE_DASHBOARD_MULTIPLEX_SLOT || ''}
            className="mt-2"
            minHeight={250}
            adFormat="auto"
          />
        </div>

        {/* Columna Derecha - TOP 5 Ganadores */}
        <div className="lg:sticky lg:top-6 lg:self-start">
          <div className="bg-gradient-to-br from-yellow-50 via-amber-50 to-orange-50 rounded-2xl p-6 border-2 border-amber-300 shadow-lg">
            <div className="text-center mb-6">
              <div className="text-6xl mb-3">🏆</div>
              <h3 className="text-2xl font-bold text-gray-900 uppercase tracking-wide">TOP 5</h3>
              <p className="text-sm text-gray-600 font-semibold">Los más ganadores</p>
            </div>

            {topTeams.length > 0 ? (
              <div className="space-y-3">
                {topTeams.map((team: any, index: number) => {
                  const isUserTeam = team.userId === session.user.id;
                  const positionColors = [
                    'from-yellow-400 to-yellow-500',
                    'from-gray-300 to-gray-400',
                    'from-orange-400 to-orange-500',
                    'from-blue-300 to-blue-400',
                    'from-green-300 to-green-400',
                  ];

                  return (
                    <div
                      key={team.id}
                      className={`relative bg-white rounded-xl p-4 border-2 ${
                        isUserTeam ? 'border-green-500 ring-2 ring-green-200' : 'border-gray-200'
                      } shadow-sm hover:shadow-md transition-shadow`}
                    >
                      {isUserTeam && (
                        <div className="absolute -top-2 -right-2 bg-green-500 text-white px-3 py-1 rounded-full text-xs font-bold shadow-md">
                          ¡Eres tú! 🎉
                        </div>
                      )}
                      
                      <div className="flex items-center gap-3">
                        {/* Posición */}
                        <div className={`bg-gradient-to-br ${positionColors[index]} w-12 h-12 flex items-center justify-center text-xl font-bold rounded-lg border-2 border-gray-900 text-white shadow-md flex-shrink-0`}>
                          {index + 1}
                        </div>
                        
                        {/* Info Equipo */}
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-bold text-gray-900 truncate">
                            {team.name}
                          </p>
                          <p className="text-xs text-gray-600 truncate">
                            {team.user.name}
                          </p>
                        </div>
                        
                        {/* Victorias */}
                        <div className="text-right flex-shrink-0">
                          <p className="text-2xl font-bold text-green-600 leading-none">
                            {team.gamesWon}
                          </p>
                          <p className="text-xs text-gray-500 font-semibold">WINS</p>
                        </div>
                      </div>

                      {/* Barra de progreso */}
                      <div className="mt-3 bg-gray-200 h-2 rounded-full overflow-hidden">
                        <div 
                          className="bg-gradient-to-r from-green-500 to-green-600 h-full rounded-full transition-all duration-500"
                          style={{ 
                            width: `${team.totalGames > 0 ? (team.gamesWon / team.totalGames) * 100 : 0}%` 
                          }}
                        />
                      </div>
                      
                      {/* Stats mini */}
                      <div className="flex justify-between mt-3 text-xs font-semibold">
                        <span className="text-gray-600">{team.totalGames} J</span>
                        <span className="text-green-600">{team.gamesWon} G</span>
                        <span className="text-gray-500">{team.gamesDrawn} E</span>
                        <span className="text-red-600">{team.gamesLost} P</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="text-center py-12 text-gray-400">
                <p className="text-6xl mb-3">🏆</p>
                <p className="text-sm font-semibold">No hay rankings todavía</p>
                <p className="text-xs mt-1">¡Sé el primero en ganar!</p>
              </div>
            )}
            
            {/* Footer */}
            <div className="mt-6 pt-4 border-t-2 border-amber-200 text-center">
              <p className="text-xs text-gray-600 font-semibold uppercase tracking-wide flex items-center justify-center gap-2">
                <span className="inline-block w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
                Actualizado en vivo
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
