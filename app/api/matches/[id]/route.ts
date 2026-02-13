import { getServerSession } from 'next-auth';
import { NextResponse } from 'next/server';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

// GET - Obtener un match específico
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const match = await prisma.match.findUnique({
      where: { id: params.id },
      include: {
        team1: true,
        team2: true,
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
        matchRequest: {
          select: {
            id: true,
            userId: true,
            footballType: true,
            fieldAddress: true,
            fieldPrice: true,
            matchDate: true,
            description: true,
            league: true,
          },
        },
        matchResult: true,
      },
    });

    if (!match) {
      return NextResponse.json(
        { error: 'Match no encontrado' },
        { status: 404 }
      );
    }

    // Verificar que el usuario participa en el match
    if (match.userId1 !== session.user.id && match.userId2 !== session.user.id) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
    }

    return NextResponse.json(match);
  } catch (error) {
    console.error('Error obteniendo match:', error);
    return NextResponse.json(
      { error: 'Error al obtener match' },
      { status: 500 }
    );
  }
}
