import { getServerSession } from 'next-auth';
import { NextResponse } from 'next/server';
import { authOptions } from '@/lib/auth';
import { MatchesService } from '@/lib/services-server';
import { handleApiError } from '@/lib/errors';

// GET - Obtener todos los matches del usuario
export async function GET(request: Request) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const status = searchParams.get('status') || undefined;

    const matches = await MatchesService.getUserMatches(
      session.user.id,
      status
    );

    return NextResponse.json(matches);
  } catch (error) {
    console.error('Error obteniendo matches:', error);
    const apiError = handleApiError(error);
    return NextResponse.json(
      { error: apiError.message },
      { status: apiError.statusCode }
    );
  }
}
