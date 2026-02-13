import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { redirect } from 'next/navigation';

export default async function StatsPage() {
  const session = await getServerSession(authOptions);

  if (!session?.user) {
    redirect('/login');
  }

  // Obtener todos los equipos del usuario con sus estadísticas
  const teams = await prisma.team.findMany({
    where: {
      userId: session.user.id,
    },
    orderBy: {
      gamesWon: 'desc',
    },
  });

  // Calcular estadísticas globales
  const totalStats = teams.reduce(
    (acc, team) => ({
      totalGames: acc.totalGames + team.totalGames,
      gamesWon: acc.gamesWon + team.gamesWon,
      gamesLost: acc.gamesLost + team.gamesLost,
      gamesDrawn: acc.gamesDrawn + team.gamesDrawn,
    }),
    { totalGames: 0, gamesWon: 0, gamesLost: 0, gamesDrawn: 0 }
  );

  const winRate = totalStats.totalGames > 0
    ? ((totalStats.gamesWon / totalStats.totalGames) * 100).toFixed(1)
    : 0;

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-primary mb-2">Estadísticas</h1>
        <p className="text-gray-600">
          Rendimiento global de todos tus equipos
        </p>
      </div>

      {teams.length === 0 ? (
        <div className="card text-center py-12">
          <div className="text-6xl mb-4">📊</div>
          <h2 className="text-2xl font-bold text-primary mb-2">
            No hay estadísticas todavía
          </h2>
          <p className="text-gray-600">
            Crea equipos y juega partidos para ver tus estadísticas
          </p>
        </div>
      ) : (
        <>
          {/* Estadísticas Globales */}
          <div className="card mb-8">
            <h2 className="text-2xl font-bold text-primary mb-6">
              📊 Resumen General
            </h2>

            <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-6">
              <div className="text-center p-4 bg-gray-100 rounded-lg">
                <p className="text-4xl font-bold text-primary mb-1">
                  {totalStats.totalGames}
                </p>
                <p className="text-sm text-gray-600">Total Partidos</p>
              </div>

              <div className="text-center p-4 bg-green-50 rounded-lg">
                <p className="text-4xl font-bold text-accent mb-1">
                  {totalStats.gamesWon}
                </p>
                <p className="text-sm text-gray-600">Victorias</p>
              </div>

              <div className="text-center p-4 bg-gray-50 rounded-lg">
                <p className="text-4xl font-bold text-gray-700 mb-1">
                  {totalStats.gamesDrawn}
                </p>
                <p className="text-sm text-gray-600">Empates</p>
              </div>

              <div className="text-center p-4 bg-red-50 rounded-lg">
                <p className="text-4xl font-bold text-accent-red mb-1">
                  {totalStats.gamesLost}
                </p>
                <p className="text-sm text-gray-600">Derrotas</p>
              </div>

              <div className="text-center p-4 bg-blue-50 rounded-lg">
                <p className="text-4xl font-bold text-blue-600 mb-1">
                  {winRate}%
                </p>
                <p className="text-sm text-gray-600">Efectividad</p>
              </div>
            </div>

            {totalStats.totalGames > 0 && (
              <div>
                <h3 className="font-semibold mb-3">Distribución de Resultados</h3>
                <div className="w-full bg-gray-200 rounded-full h-8 flex overflow-hidden">
                  {totalStats.gamesWon > 0 && (
                    <div
                      className="bg-accent h-8 flex items-center justify-center text-white text-sm font-semibold"
                      style={{
                        width: `${(totalStats.gamesWon / totalStats.totalGames) * 100}%`,
                      }}
                    >
                      {((totalStats.gamesWon / totalStats.totalGames) * 100).toFixed(0)}%
                    </div>
                  )}
                  {totalStats.gamesDrawn > 0 && (
                    <div
                      className="bg-gray-400 h-8 flex items-center justify-center text-white text-sm font-semibold"
                      style={{
                        width: `${(totalStats.gamesDrawn / totalStats.totalGames) * 100}%`,
                      }}
                    >
                      {((totalStats.gamesDrawn / totalStats.totalGames) * 100).toFixed(0)}%
                    </div>
                  )}
                  {totalStats.gamesLost > 0 && (
                    <div
                      className="bg-accent-red h-8 flex items-center justify-center text-white text-sm font-semibold"
                      style={{
                        width: `${(totalStats.gamesLost / totalStats.totalGames) * 100}%`,
                      }}
                    >
                      {((totalStats.gamesLost / totalStats.totalGames) * 100).toFixed(0)}%
                    </div>
                  )}
                </div>
                <div className="flex justify-between mt-2 text-sm text-gray-600">
                  <span>✅ Ganados</span>
                  <span>🤝 Empates</span>
                  <span>❌ Perdidos</span>
                </div>
              </div>
            )}
          </div>

          {/* Estadísticas por Equipo */}
          <div className="card">
            <h2 className="text-2xl font-bold text-primary mb-6">
              ⚽ Por Equipo
            </h2>

            <div className="space-y-4">
              {teams.map((team, index) => {
                const teamWinRate = team.totalGames > 0
                  ? ((team.gamesWon / team.totalGames) * 100).toFixed(1)
                  : 0;

                return (
                  <div
                    key={team.id}
                    className="border-2 border-gray-200 rounded-lg p-4 hover:border-primary transition-colors"
                  >
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center gap-3">
                        {index === 0 && team.gamesWon > 0 && (
                          <span className="text-2xl">🏆</span>
                        )}
                        <h3 className="text-lg font-bold text-primary">
                          {team.name}
                        </h3>
                      </div>
                      <span className="text-sm text-gray-600">
                        {team.totalGames} {team.totalGames === 1 ? 'partido' : 'partidos'}
                      </span>
                    </div>

                    <div className="grid grid-cols-4 gap-2 mb-3 text-center">
                      <div className="bg-green-50 rounded p-2">
                        <p className="text-2xl font-bold text-accent">
                          {team.gamesWon}
                        </p>
                        <p className="text-xs text-gray-600">Ganados</p>
                      </div>
                      <div className="bg-gray-50 rounded p-2">
                        <p className="text-2xl font-bold text-gray-700">
                          {team.gamesDrawn}
                        </p>
                        <p className="text-xs text-gray-600">Empates</p>
                      </div>
                      <div className="bg-red-50 rounded p-2">
                        <p className="text-2xl font-bold text-accent-red">
                          {team.gamesLost}
                        </p>
                        <p className="text-xs text-gray-600">Perdidos</p>
                      </div>
                      <div className="bg-blue-50 rounded p-2">
                        <p className="text-2xl font-bold text-blue-600">
                          {teamWinRate}%
                        </p>
                        <p className="text-xs text-gray-600">Efectividad</p>
                      </div>
                    </div>

                    {team.totalGames > 0 && (
                      <div className="w-full bg-gray-200 rounded-full h-4 flex overflow-hidden">
                        {team.gamesWon > 0 && (
                          <div
                            className="bg-accent h-4"
                            style={{
                              width: `${(team.gamesWon / team.totalGames) * 100}%`,
                            }}
                          />
                        )}
                        {team.gamesDrawn > 0 && (
                          <div
                            className="bg-gray-400 h-4"
                            style={{
                              width: `${(team.gamesDrawn / team.totalGames) * 100}%`,
                            }}
                          />
                        )}
                        {team.gamesLost > 0 && (
                          <div
                            className="bg-accent-red h-4"
                            style={{
                              width: `${(team.gamesLost / team.totalGames) * 100}%`,
                            }}
                          />
                        )}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
