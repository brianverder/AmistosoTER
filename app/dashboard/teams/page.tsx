import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import Link from 'next/link';
import { redirect } from 'next/navigation';

export default async function TeamsPage() {
  const session = await getServerSession(authOptions);

  if (!session?.user) {
    redirect('/login');
  }

  const teams = await prisma.team.findMany({
    where: {
      userId: session.user.id,
    },
    orderBy: {
      createdAt: 'desc',
    },
  });

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-black text-black uppercase tracking-tight mb-2">Mis Equipos</h1>
          <p className="text-gray-600 font-medium">Administra tus equipos de fútbol</p>
        </div>
        <Link href="/dashboard/teams/new" className="btn-primary">
          ➕ Nuevo Equipo
        </Link>
      </div>

      {teams.length === 0 ? (
        <div className="card text-center py-12">
          <div className="text-6xl mb-4">⚽</div>
          <h2 className="text-2xl font-bold text-primary mb-2">
            No tienes equipos todavía
          </h2>
          <p className="text-gray-600 mb-6">
            Crea tu primer equipo para empezar a buscar partidos
          </p>
          <Link href="/dashboard/teams/new" className="btn-primary inline-block">
            Crear Primer Equipo
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {teams.map((team) => (
            <div key={team.id} className="card">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="text-xl font-bold text-primary mb-1">
                    {team.name}
                  </h3>
                  <p className="text-sm text-gray-500">
                    Creado el {new Date(team.createdAt).toLocaleDateString()}
                  </p>
                </div>
                <div className="text-3xl">⚽</div>
              </div>

              {/* Estadísticas */}
              <div className="grid grid-cols-3 gap-2 mb-4 text-center">
                <div className="bg-gray-800 text-white border border-black p-2">
                  <p className="text-2xl font-bold">{team.gamesWon}</p>
                  <p className="text-xs">Ganados</p>
                </div>
                <div className="bg-gray-200 border border-black p-2">
                  <p className="text-2xl font-bold text-black">{team.gamesDrawn}</p>
                  <p className="text-xs">Empates</p>
                </div>
                <div className="bg-white border border-black p-2">
                  <p className="text-2xl font-bold text-black">{team.gamesLost}</p>
                  <p className="text-xs">Perdidos</p>
                </div>
              </div>

              <p className="text-sm text-gray-600 mb-4">
                Total de partidos: <span className="font-semibold">{team.totalGames}</span>
              </p>

              <div className="flex gap-2">
                <Link
                  href={`/dashboard/teams/${team.id}`}
                  className="btn-secondary flex-1 text-center text-sm"
                >
                  Ver Detalles
                </Link>
                <Link
                  href={`/dashboard/teams/${team.id}/stats`}
                  className="btn-primary flex-1 text-center text-sm"
                  title="Ver estadísticas completas"
                >
                  📊
                </Link>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
