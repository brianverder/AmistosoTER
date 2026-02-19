import { getServerSession } from 'next-auth';
import { NextResponse } from 'next/server';
import { authOptions } from '@/lib/auth';
import { TeamsService } from '@/lib/services-server';
import { handleApiError } from '@/lib/errors';

// GET - Obtener todos los equipos del usuario
export async function GET() {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const teams = await TeamsService.getUserTeams(session.user.id);

    return NextResponse.json(teams);
  } catch (error) {
    console.error('Error obteniendo equipos:', error);
    const apiError = handleApiError(error);
    return NextResponse.json(
      { error: apiError.message },
      { status: apiError.statusCode }
    );
  }
}

// POST - Crear un nuevo equipo
export async function POST(request: Request) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const { name, instagram } = await request.json();

    const team = await TeamsService.createTeam({
      userId: session.user.id,
      name,
      instagram,
    });

    return NextResponse.json(team, { status: 201 });
  } catch (error) {
    console.error('Error creando equipo:', error);
    const apiError = handleApiError(error);
    return NextResponse.json(
      { error: apiError.message },
      { status: apiError.statusCode }
    );
  }
}
