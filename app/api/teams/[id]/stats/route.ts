import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);

    if (!session) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 401 });
    }

    // Verificar que el equipo pertenece al usuario
    const team = await prisma.team.findFirst({
      where: {
        id: params.id,
        userId: session.user.id,
      },
      select: {
        id: true,
        name: true,
        gamesWon: true,
        gamesLost: true,
        gamesDrawn: true,
        totalGames: true,
      },
    });

    if (!team) {
      return NextResponse.json(
        { error: 'Equipo no encontrado' },
        { status: 404 }
      );
    }

    // Obtener historial de matches del equipo
    const matches = await prisma.match.findMany({
      where: {
        OR: [
          { team1Id: params.id },
          { team2Id: params.id },
        ],
        status: 'completed', // Solo mostrar matches finalizados
      },
      include: {
        team1: {
          select: {
            id: true,
            name: true,
          },
        },
        team2: {
          select: {
            id: true,
            name: true,
          },
        },
        matchResult: {
          select: {
            team1Score: true,
            team2Score: true,
            winnerId: true,
          },
        },
        matchRequest: {
          select: {
            footballType: true,
            matchDate: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    // Formatear historial de matches
    const matchHistory = matches.map((match: any) => {
      const isTeam1 = match.team1Id === params.id;
      const opponent = isTeam1 ? match.team2 : match.team1;
      const ownScore = isTeam1
        ? match.matchResult?.team1Score
        : match.matchResult?.team2Score;
      const opponentScore = isTeam1
        ? match.matchResult?.team2Score
        : match.matchResult?.team1Score;

      let result: 'won' | 'lost' | 'draw' = 'draw';
      if (match.matchResult?.winnerId) {
        if (match.matchResult.winnerId === params.id) {
          result = 'won';
        } else {
          result = 'lost';
        }
      }

      return {
        id: match.id,
        opponent: opponent.name,
        ownScore,
        opponentScore,
        result,
        footballType: match.matchRequest.footballType,
        matchDate: match.matchRequest.matchDate,
        createdAt: match.createdAt,
      };
    });

    return NextResponse.json({
      team,
      matchHistory,
    });
  } catch (error) {
    console.error('Error fetching team stats:', error);
    return NextResponse.json(
      { error: 'Error al cargar estadísticas' },
      { status: 500 }
    );
  }
}
