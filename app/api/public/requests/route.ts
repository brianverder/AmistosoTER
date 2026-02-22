import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

/**
 * GET /api/public/requests
 * API pública para listar solicitudes de partidos
 * Parámetros query:
 * - status: 'active' | 'matched' | 'completed' | 'cancelled' | 'all'
 */
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status') || 'active';

    let whereClause: any = {};

    if (status === 'all') {
      // Mostrar todas las solicitudes
      whereClause = {};
    } else if (status === 'historical') {
      // Solicitudes históricas (no activas)
      whereClause = {
        status: { in: ['matched', 'completed', 'cancelled'] },
      };
    } else {
      // Filtrar por estado específico
      whereClause = { status };
    }

    const requests = await prisma.matchRequest.findMany({
      where: whereClause,
      include: {
        team: {
          select: {
            id: true,
            name: true,
            totalGames: true,
            gamesWon: true,
            gamesDrawn: true,
          },
        },
        user: {
          select: {
            id: true,
            name: true,
            // No incluir email/phone en vista pública
          },
        },
        match: {
          select: {
            id: true,
            teamAId: true,
            teamBId: true,
            matchDate: true,
            status: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: 100, // Limitar resultados
    });

    const normalizedRequests = requests.map((request) => ({
      ...request,
      team: {
        ...request.team,
        gamesPlayed: request.team.totalGames,
        gamesDraw: request.team.gamesDrawn,
      },
    }));

    return NextResponse.json(normalizedRequests);
  } catch (error) {
    console.error('Error fetching public requests:', error);
    return NextResponse.json(
      { error: 'Error al cargar solicitudes' },
      { status: 500 }
    );
  }
}
