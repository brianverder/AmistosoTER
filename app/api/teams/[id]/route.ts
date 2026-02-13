import { getServerSession } from 'next-auth';
import { NextResponse } from 'next/server';
import { authOptions } from '@/lib/auth';
import { TeamsService } from '@/lib/services-server';
import { handleApiError } from '@/lib/errors';

// GET - Obtener un equipo específico
export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const team = await TeamsService.getTeamById(params.id, session.user.id);

    return NextResponse.json(team);
  } catch (error) {
    console.error('Error obteniendo equipo:', error);
    const apiError = handleApiError(error);
    return NextResponse.json(
      { error: apiError.message },
      { status: apiError.statusCode }
    );
  }
}

// PATCH - Actualizar un equipo
export async function PATCH(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const { name } = await request.json();

    const team = await TeamsService.updateTeam(
      params.id,
      session.user.id,
      { name }
    );

    return NextResponse.json(team);
  } catch (error) {
    console.error('Error actualizando equipo:', error);
    const apiError = handleApiError(error);
    return NextResponse.json(
      { error: apiError.message },
      { status: apiError.statusCode }
    );
  }
}

// DELETE - Eliminar un equipo
export async function DELETE(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    await TeamsService.deleteTeam(params.id, session.user.id);

    return NextResponse.json({ message: 'Equipo eliminado exitosamente' });
  } catch (error) {
    console.error('Error eliminando equipo:', error);
    const apiError = handleApiError(error);
    return NextResponse.json(
      { error: apiError.message },
      { status: apiError.statusCode }
    );
  }
}
