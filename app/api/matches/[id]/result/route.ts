import { getServerSession } from 'next-auth';
import { NextResponse } from 'next/server';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

// POST - Registrar resultado de un match
export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const { team1Score, team2Score } = await request.json();

    if (team1Score === undefined || team2Score === undefined) {
      return NextResponse.json(
        { error: 'Los marcadores son requeridos' },
        { status: 400 }
      );
    }

    // Obtener el match con la solicitud original
    const match = await prisma.match.findUnique({
      where: { id: params.id },
      include: {
        matchResult: true,
        matchRequest: {
          select: {
            userId: true, // Usuario que creó la solicitud original
          },
        },
      },
    });

    if (!match) {
      return NextResponse.json(
        { error: 'Match no encontrado' },
        { status: 404 }
      );
    }

    // Verificar que el usuario es quien creó la solicitud original
    if (match.matchRequest.userId !== session.user.id) {
      return NextResponse.json(
        { error: 'Solo el usuario que creó la solicitud puede registrar el resultado' },
        { status: 403 }
      );
    }

    if (match.matchResult) {
      return NextResponse.json(
        { error: 'El resultado ya fue registrado' },
        { status: 400 }
      );
    }

    // Determinar el ganador
    let winnerId = null;
    if (team1Score > team2Score) {
      winnerId = match.team1Id;
    } else if (team2Score > team1Score) {
      winnerId = match.team2Id;
    }
    // Si son iguales, winnerId queda null (empate)

    // Registrar resultado y actualizar estadísticas
    await prisma.$transaction(async (tx) => {
      // Crear resultado
      await tx.matchResult.create({
        data: {
          matchId: params.id,
          team1Score: parseInt(team1Score),
          team2Score: parseInt(team2Score),
          winnerId,
        },
      });

      // Actualizar match status
      await tx.match.update({
        where: { id: params.id },
        data: { status: 'completed' },
      });

      // Actualizar solicitud
      await tx.matchRequest.update({
        where: { id: match.matchRequestId },
        data: { status: 'completed' },
      });

      // Actualizar estadísticas de los equipos
      if (winnerId === match.team1Id) {
        // Equipo 1 ganó
        await tx.team.update({
          where: { id: match.team1Id },
          data: {
            gamesWon: { increment: 1 },
            totalGames: { increment: 1 },
          },
        });
        await tx.team.update({
          where: { id: match.team2Id },
          data: {
            gamesLost: { increment: 1 },
            totalGames: { increment: 1 },
          },
        });
      } else if (winnerId === match.team2Id) {
        // Equipo 2 ganó
        await tx.team.update({
          where: { id: match.team2Id },
          data: {
            gamesWon: { increment: 1 },
            totalGames: { increment: 1 },
          },
        });
        await tx.team.update({
          where: { id: match.team1Id },
          data: {
            gamesLost: { increment: 1 },
            totalGames: { increment: 1 },
          },
        });
      } else {
        // Empate
        await tx.team.updateMany({
          where: {
            id: {
              in: [match.team1Id, match.team2Id],
            },
          },
          data: {
            gamesDrawn: { increment: 1 },
            totalGames: { increment: 1 },
          },
        });
      }
    });

    // Obtener el match actualizado
    const updatedMatch = await prisma.match.findUnique({
      where: { id: params.id },
      include: {
        team1: true,
        team2: true,
        matchResult: true,
      },
    });

    return NextResponse.json(updatedMatch);
  } catch (error) {
    console.error('Error registrando resultado:', error);
    return NextResponse.json(
      { error: 'Error al registrar resultado' },
      { status: 500 }
    );
  }
}
