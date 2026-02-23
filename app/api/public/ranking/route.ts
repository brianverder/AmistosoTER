export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { RankingRepository } from '@/lib/repositories';
import { handleApiError } from '@/lib/errors';

/**
 * GET /api/public/ranking
 *
 * Devuelve el ranking público (no requiere autenticación)
 *
 * Query params:
 *  - season        string  (default: año actual)
 *  - footballType  string  (opcional: "11","7","5","8")
 *  - country       string  (opcional: "Uruguay","Argentina","Brasil")
 *  - page          number  (default: 1)
 *  - pageSize      number  (default: 50, max: 100)
 */
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);

    const season       = searchParams.get('season') || String(new Date().getFullYear());
    const footballType = searchParams.get('footballType') || undefined;
    const country      = searchParams.get('country') || undefined;
    const page         = Math.max(1, parseInt(searchParams.get('page') || '1'));
    const pageSize     = Math.min(100, Math.max(1, parseInt(searchParams.get('pageSize') || '50')));

    const result = await RankingRepository.getLeaderboard({
      season,
      footballType,
      country,
      page,
      pageSize,
    });

    // Cache público de 60 segundos
    return NextResponse.json(result, {
      headers: { 'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300' },
    });
  } catch (error) {
    const apiError = handleApiError(error);
    return NextResponse.json({ error: apiError.message }, { status: apiError.statusCode });
  }
}
