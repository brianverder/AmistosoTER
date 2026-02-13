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
            gamesPlayed: true,
            gamesWon: true,
            gamesLost: true,
            gamesDraw: true,
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
            teamA: {
              select: {
                id: true,
                name: true,
                userId: true,
              },
            },
            teamB: {
              select: {
                id: true,
                name: true,
                userId: true,
              },
            },
            userA: {
              select: {
                id: true,
                name: true,
                email: true,
                phone: true,
              },
            },
            userB: {
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
        matchRequest.match.userA.id === session.user.id ||
        matchRequest.match.userB.id === session.user.id;

      if (!isParticipant) {
        // Ocultar información de contacto si no es participante
        matchRequest.match.userA.email = '';
        matchRequest.match.userA.phone = null;
        matchRequest.match.userB.email = '';
        matchRequest.match.userB.phone = null;
      }
    }

    return NextResponse.json(matchRequest);
  } catch (error) {
    console.error('Error fetching request:', error);
    return NextResponse.json(
      { error: 'Error al cargar solicitud' },
      { status: 500 }
    );
  }
}
