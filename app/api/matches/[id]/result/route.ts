import { getServerSession } from 'next-auth';
import { NextResponse } from 'next/server';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { recalcTeamStats, recalcRanking } from '@/lib/db';

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

    const score1 = parseInt(team1Score);
    const score2 = parseInt(team2Score);

    if (isNaN(score1) || isNaN(score2) || score1 < 0 || score2 < 0) {
      return NextResponse.json(
        { error: 'Los marcadores deben ser números positivos' },
        { status: 400 }
      );
    }

    // Obtener el match con la solicitud original
    const match = await prisma.match.findUnique({
      where: { id: params.id },
      include: {
        matchResult: true,
        matchRequest: {
          select: { userId: true },
        },
      },
    });

    if (!match) {
      return NextResponse.json({ error: 'Match no encontrado' }, { status: 404 });
    }

    if (match.matchRequest.userId !== session.user.id && match.userId2 !== session.user.id) {
      return NextResponse.json(
        { error: 'Solo los participantes del partido pueden registrar el resultado' },
        { status: 403 }
      );
    }

    if (match.matchResult) {
      return NextResponse.json({ error: 'El resultado ya fue registrado' }, { status: 400 });
    }

    // Determinar ganador
    let winnerId: string | null = null;
    if (score1 > score2) winnerId = match.team1Id;
    else if (score2 > score1) winnerId = match.team2Id;

    // Registrar resultado, actualizar match y solicitud
    await prisma.$transaction(async (tx) => {
      await tx.matchResult.create({
        data: {
          matchId: params.id,
          team1Score: score1,
          team2Score: score2,
          winnerId,
          createdById: session.user.id,
        },
      });

      await tx.match.update({
        where: { id: params.id },
        data: { status: 'completed' },
      });

      await tx.matchRequest.update({
        where: { id: match.matchRequestId },
        data: { status: 'completed' },
      });
    });

    // Recalcular estadísticas completas de ambos equipos (incluye goles y puntos)
    await Promise.all([
      recalcTeamStats(match.team1Id),
      recalcTeamStats(match.team2Id),
    ]);

    // Actualizar ranking de la temporada actual
    const currentSeason = String(new Date().getFullYear());
    await recalcRanking({ season: currentSeason }).catch(() => {
      // No bloquear la respuesta si el ranking falla
      console.warn('Ranking recalc falló (no bloqueante)');
    });

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
    return NextResponse.json({ error: 'Error al registrar resultado' }, { status: 500 });
  }
}
