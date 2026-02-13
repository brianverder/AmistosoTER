import { getServerSession } from 'next-auth';
import { NextResponse } from 'next/server';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

// GET - Obtener una solicitud específica
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const matchRequest = await prisma.matchRequest.findUnique({
      where: { id: params.id },
      include: {
        team: true,
        user: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
          },
        },
        match: true,
      },
    });

    if (!matchRequest) {
      return NextResponse.json(
        { error: 'Solicitud no encontrada' },
        { status: 404 }
      );
    }

    return NextResponse.json(matchRequest);
  } catch (error) {
    console.error('Error obteniendo solicitud:', error);
    return NextResponse.json(
      { error: 'Error al obtener solicitud' },
      { status: 500 }
    );
  }
}

// DELETE - Eliminar solicitud
export async function DELETE(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const matchRequest = await prisma.matchRequest.findUnique({
      where: { id: params.id },
    });

    if (!matchRequest) {
      return NextResponse.json(
        { error: 'Solicitud no encontrada' },
        { status: 404 }
      );
    }

    if (matchRequest.userId !== session.user.id) {
      return NextResponse.json({ error: 'No autorizado' }, { status: 403 });
    }

    if (matchRequest.status === 'matched') {
      return NextResponse.json(
        { error: 'No se puede eliminar una solicitud con match' },
        { status: 400 }
      );
    }

    await prisma.matchRequest.delete({
      where: { id: params.id },
    });

    return NextResponse.json({ message: 'Solicitud eliminada exitosamente' });
  } catch (error) {
    console.error('Error eliminando solicitud:', error);
    return NextResponse.json(
      { error: 'Error al eliminar solicitud' },
      { status: 500 }
    );
  }
}
