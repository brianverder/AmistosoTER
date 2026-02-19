import { getServerSession } from 'next-auth';
import { NextResponse } from 'next/server';
import { authOptions } from '@/lib/auth';
import { MatchRequestsService } from '@/lib/services-server';
import { handleApiError } from '@/lib/errors';

// GET - Obtener todas las solicitudes (del usuario o disponibles)
export async function GET(request: Request) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const mode = searchParams.get('mode'); // 'my' o 'available'
    const page = parseInt(searchParams.get('page') || '1');
    const pageSize = parseInt(searchParams.get('pageSize') || '20');
    const footballType = searchParams.get('footballType') || undefined;
    const rawCountry = searchParams.get('country')?.trim();
    const allowedCountries = ['Uruguay', 'Argentina', 'Brasil'];
    const country = rawCountry && allowedCountries.includes(rawCountry)
      ? rawCountry
      : undefined;

    let result;

    if (mode === 'my') {
      // Solicitudes del usuario
      const matchRequests = await MatchRequestsService.getUserRequests(
        session.user.id,
        undefined,
        {
          footballType,
          country,
        }
      );
      result = matchRequests;
    } else {
      // Solicitudes disponibles
      result = await MatchRequestsService.getAvailableRequests({
        excludeUserId: session.user.id,
        footballType,
        country,
        page,
        pageSize
      });
    }

    return NextResponse.json(result);
  } catch (error) {
    console.error('Error obteniendo solicitudes:', error);
    const apiError = handleApiError(error);
    return NextResponse.json(
      { error: apiError.message },
      { status: apiError.statusCode }
    );
  }
}

// POST - Crear una nueva solicitud de partido
export async function POST(request: Request) {
  try {
    const session = await getServerSession(authOptions);

    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const data = await request.json();

    // Parsear la fecha si viene como string
    const matchDate = data.matchDate ? new Date(data.matchDate) : undefined;

    // Parsear fieldPrice a número si existe
    const fieldPrice = data.fieldPrice 
      ? parseFloat(data.fieldPrice) 
      : undefined;

    const matchRequest = await MatchRequestsService.createRequest({
      userId: session.user.id,
      teamId: data.teamId,
      footballType: data.footballType,
      fieldName: data.fieldName,
      fieldAddress: data.fieldAddress,
      country: data.country,
      state: data.state,
      date: matchDate,
      fieldPrice: fieldPrice,
      league: data.league,
      description: data.description,
    });

    return NextResponse.json(matchRequest, { status: 201 });
  } catch (error) {
    console.error('Error creando solicitud:', error);
    const apiError = handleApiError(error);
    return NextResponse.json(
      { error: apiError.message },
      { status: apiError.statusCode }
    );
  }
}
