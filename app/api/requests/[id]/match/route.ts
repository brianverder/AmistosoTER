import { getServerSession } from 'next-auth';
import { NextResponse } from 'next/server';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

// POST - Crear un match (aceptar una solicitud)
export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const { teamId } = await request.json();

    if (!teamId) {
      return NextResponse.json(
        { error: 'Debes seleccionar un equipo' },
        { status: 400 }
      );
    }

    // Verificar que el equipo pertenece al usuario
    const team = await prisma.team.findUnique({
      where: { id: teamId },
    });

    if (!team || team.userId !== session.user.id) {
      return NextResponse.json(
        { error: 'Equipo no válido' },
        { status: 400 }
      );
    }

    // Obtener la solicitud
    const matchRequest = await prisma.matchRequest.findUnique({
      where: { id: params.id },
      include: {
        team: true,
      },
    });

    if (!matchRequest) {
      return NextResponse.json(
        { error: 'Solicitud no encontrada' },
        { status: 404 }
      );
    }

    if (matchRequest.status !== 'active') {
      return NextResponse.json(
        { error: 'Esta solicitud ya no está disponible' },
        { status: 400 }
      );
    }

    if (matchRequest.userId === session.user.id) {
      return NextResponse.json(
        { error: 'No puedes hacer match con tu propia solicitud' },
        { status: 400 }
      );
    }

    // Crear el match y actualizar la solicitud
    const match = await prisma.$transaction(async (tx) => {
      // Actualizar solicitud
      await tx.matchRequest.update({
        where: { id: params.id },
        data: { status: 'matched' },
      });

      // Crear match
      return tx.match.create({
        data: {
          matchRequestId: params.id,
          team1Id: matchRequest.teamId,
          team2Id: teamId,
          userId1: matchRequest.userId,
          userId2: session.user.id,
          status: 'pending',
          finalDate: matchRequest.matchDate,
          finalAddress: matchRequest.fieldAddress,
          finalPrice: matchRequest.fieldPrice,
        },
        include: {
          team1: true,
          team2: true,
          matchRequest: true,
        },
      });
    });

    return NextResponse.json(match, { status: 201 });
  } catch (error) {
    console.error('Error creando match:', error);
    return NextResponse.json(
      { error: 'Error al crear match' },
      { status: 500 }
    );
  }
}
