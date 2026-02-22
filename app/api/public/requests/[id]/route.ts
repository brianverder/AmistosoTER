import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';

/**
 * GET /api/public/requests/[id]
 * Obtener detalle de una solicitud específica (vista pública)
 */
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    const isAuthenticated = !!session?.user;

    const matchRequest = await prisma.matchRequest.findUnique({
      where: { id: params.id },
      include: {
        team: {
          select: {
            id: true,
            name: true,
            totalGames: true,
            gamesWon: true,
            gamesLost: true,
            gamesDrawn: true,
          },
        },
        user: {
          select: {
            id: true,
            name: true,
            // Solo mostrar contacto si está autenticado Y es el match creado
            email: isAuthenticated,
            phone: isAuthenticated,
          },
        },
        match: {
          include: {
            team1: {
              select: {
                id: true,
                name: true,
                instagram: true,
                userId: true,
              },
            },
            team2: {
              select: {
                id: true,
                name: true,
                instagram: true,
                userId: true,
              },
            },
            user1: {
              select: {
                id: true,
                name: true,
                email: true,
                phone: true,
              },
            },
            user2: {
              select: {
                id: true,
                name: true,
                email: true,
                phone: true,
              },
            },
          },
        },
      },
    });

    if (!matchRequest) {
      return NextResponse.json(
        { error: 'Solicitud no encontrada' },
        { status: 404 }
      );
    }

    // Si hay match, solo mostrar contactos completos a los participantes
    if (matchRequest.match && isAuthenticated) {
      const isParticipant =
        matchRequest.match.user1.id === session.user.id ||
        matchRequest.match.user2.id === session.user.id;

      if (!isParticipant) {
        // Ocultar información de contacto si no es participante
        matchRequest.match.user1.email = '';
        matchRequest.match.user1.phone = null;
        matchRequest.match.user2.email = '';
        matchRequest.match.user2.phone = null;
        matchRequest.match.team1.instagram = null;
        matchRequest.match.team2.instagram = null;
      }
    }

    const response = {
      ...matchRequest,
      team: {
        ...matchRequest.team,
        gamesPlayed: matchRequest.team.totalGames,
        gamesDraw: matchRequest.team.gamesDrawn,
      },
      ...(matchRequest.match
        ? {
            match: {
              ...matchRequest.match,
              teamA: matchRequest.match.team1,
              teamB: matchRequest.match.team2,
              userA: matchRequest.match.user1,
              userB: matchRequest.match.user2,
            },
          }
        : {}),
    };

    return NextResponse.json(response);
  } catch (error) {
    console.error('Error fetching request:', error);
    return NextResponse.json(
      { error: 'Error al cargar solicitud' },
      { status: 500 }
    );
  }
}
