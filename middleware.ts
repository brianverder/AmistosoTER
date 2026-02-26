import { withAuth } from 'next-auth/middleware';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { rateLimitMiddleware } from './lib/rate-limit';

function addCorsHeaders(response: NextResponse, request: NextRequest) {
  const origin = request.headers.get('origin') || '';
  // Orígenes permitidos: desarrollo + producción
  const allowedOrigins = [
    'https://tercer-tiempo.com',
    'https://www.tercer-tiempo.com',
  ];
  const allowedOrigin = allowedOrigins.includes(origin)
    ? origin
    : origin.includes('localhost') ? origin : '';
  if (!allowedOrigin) return response;
  response.headers.set('Access-Control-Allow-Origin', allowedOrigin);
  response.headers.set('Access-Control-Allow-Credentials', 'true');
  response.headers.set('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS,PATCH');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With');
  return response;
}

// Middleware CORS para rutas de auth (no requieren token)
export function middleware(request: NextRequest) {
  if (request.method === 'OPTIONS') {
    const res = new NextResponse(null, { status: 204 });
    return addCorsHeaders(res, request);
  }
  const response = NextResponse.next();
  return addCorsHeaders(response, request);
}

export const config = {
  matcher: [
    '/api/:path*',
    '/dashboard/:path*',
  ],
};
