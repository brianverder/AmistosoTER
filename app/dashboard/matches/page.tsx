import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import Link from 'next/link';
import { redirect } from 'next/navigation';

export default async function MatchesPage() {
  const session = await getServerSession(authOptions);

  if (!session?.user) {
    redirect('/login');
  }

  const matches = await prisma.match.findMany({
    where: {
      OR: [
        { userId1: session.user.id },
        { userId2: session.user.id },
      ],
    },
    include: {
      team1: true,
      team2: true,
      matchRequest: {
        select: {
          footballType: true,
          userId: true,
        },
      },
      matchResult: true,
    },
    orderBy: {
      createdAt: 'desc',
    },
  });

  const getStatusInfo = (match: any) => {
    if (match.matchResult) {
      return { 
        text: '✅ Finalizado', 
        class: 'bg-gray-800 text-white border border-black',
        icon: '✅'
      };
    } else if (match.status === 'confirmed') {
      return { 
        text: 'Confirmado', 
        class: 'bg-gray-300 text-black border border-black',
        icon: '🤝'
      };
    } else {
      return { 
        text: 'Pendiente', 
        class: 'bg-white text-black border border-black',
        icon: '⏳'
      };
    }
  };

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-primary mb-2">Mis Matches</h1>
        <p className="text-gray-600">
          Partidos coordinados con otros equipos
        </p>
      </div>

      {matches.length === 0 ? (
        <div className="card text-center py-12">
          <div className="text-6xl mb-4">🤝</div>
          <h2 className="text-2xl font-bold text-primary mb-2">
            No tienes matches todavía
          </h2>
          <p className="text-gray-600 mb-6">
            Busca solicitudes disponibles y haz match para coordinar un partido
          </p>
          <Link
            href="/dashboard/requests"
            className="btn-primary inline-block"
          >
            Buscar Partidos
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          {matches.map((match) => {
            const statusInfo = getStatusInfo(match);
            const isUserTeam1 = match.userId1 === session.user.id;
            const userTeam = isUserTeam1 ? match.team1 : match.team2;
            const opponentTeam = isUserTeam1 ? match.team2 : match.team1;

            return (
              <div key={match.id} className="card">
                <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-3">
                      <span
                        className={`px-3 py-1 rounded-full text-xs font-semibold ${statusInfo.class} flex items-center gap-1`}
                      >
                        <span>{statusInfo.icon}</span>
                        {statusInfo.text}
                      </span>
                      {match.matchRequest.footballType && (
                        <span className="text-sm text-gray-600">
                          ⚽ Fútbol {match.matchRequest.footballType}
                        </span>
                      )}
                      {!match.matchResult && (
                        <span className="text-xs text-gray-500 italic">
                          {match.matchRequest.userId === session.user.id 
                            ? '(Puedes registrar resultado)' 
                            : '(Esperando resultado)'}
                        </span>
                      )}
                    </div>

                    <div className="flex items-center gap-4 text-lg">
                      <div className="text-center">
                        <p className="font-bold text-primary">{userTeam.name}</p>
                        <p className="text-xs text-gray-500">Tu equipo</p>
                      </div>

                      <div className="text-center px-6">
                        {match.matchResult ? (
                          <div className="flex items-center gap-2">
                            <span className="text-2xl font-bold">
                              {isUserTeam1
                                ? match.matchResult.team1Score
                                : match.matchResult.team2Score}
                            </span>
                            <span className="text-gray-400">-</span>
                            <span className="text-2xl font-bold">
                              {isUserTeam1
                                ? match.matchResult.team2Score
                                : match.matchResult.team1Score}
                            </span>
                          </div>
                        ) : (
                          <span className="text-2xl text-gray-400">vs</span>
                        )}
                      </div>

                      <div className="text-center">
                        <p className="font-bold text-primary">{opponentTeam.name}</p>
                        <p className="text-xs text-gray-500">Rival</p>
                      </div>
                    </div>

                    {match.matchResult && (
                      <div className="mt-3">
                        {match.matchResult.winnerId === userTeam.id ? (
                          <span className="inline-flex items-center text-accent font-semibold text-sm">
                            🏆 ¡Victoria!
                          </span>
                        ) : match.matchResult.winnerId === opponentTeam.id ? (
                          <span className="inline-flex items-center text-accent-red font-semibold text-sm">
                            ❌ Derrota
                          </span>
                        ) : (
                          <span className="inline-flex items-center text-gray-600 font-semibold text-sm">
                            🤝 Empate
                          </span>
                        )}
                      </div>
                    )}

                    {match.finalDate && (
                      <p className="text-sm text-gray-600 mt-2">
                        📅 {new Date(match.finalDate).toLocaleDateString('es', {
                          day: 'numeric',
                          month: 'short',
                          year: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </p>
                    )}
                  </div>

                  <div>
                    <Link
                      href={`/dashboard/matches/${match.id}`}
                      className="btn-secondary text-sm"
                    >
                      Ver Detalles
                    </Link>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
