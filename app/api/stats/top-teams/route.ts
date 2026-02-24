import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

/**
 * GET /api/stats/top-teams
 * Returns the top 5 teams with the most wins globally (all users).
 */
export async function GET() {
  try {
    const session = await getServerSession(authOptions);
    if (!session) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 401 });
    }

    const topTeams = await prisma.team.findMany({
      where: {
        gamesWon: { gt: 0 },
      },
      select: {
        id: true,
        name: true,
        gamesWon: true,
        gamesLost: true,
        gamesDrawn: true,
        totalGames: true,
      },
      orderBy: { gamesWon: 'desc' },
      take: 5,
    });

    return NextResponse.json(topTeams);
  } catch (error) {
    console.error('[GET /api/stats/top-teams]', error);
    return NextResponse.json(
      { error: 'Error interno del servidor' },
      { status: 500 }
    );
  }
}
