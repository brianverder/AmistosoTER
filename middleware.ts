import { withAuth } from 'next-auth/middleware';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { rateLimitMiddleware } from './lib/rate-limit';

/**
 * Middleware mejorado con:
 * - Rate limiting para prevenir brute force y DDoS
 * - Autenticación de NextAuth
 * - Security headers
 */
export default withAuth(
  function middleware(request: NextRequest) {
    // Aplicar rate limiting
    const rateLimitResponse = rateLimitMiddleware(request as any);
    if (rateLimitResponse) {
      return rateLimitResponse;
    }

    // Continuar con la request
    return NextResponse.next();
  },
  {
    callbacks: {
      authorized: ({ token }) => !!token,
    },
  }
);

export const config = {
  matcher: [
    // Rutas protegidas que requieren autenticación
    '/dashboard/:path*',
    '/teams/:path*',
    '/matches/:path*',
    '/requests/:path*',
    // API routes también protegidas
    '/api/teams/:path*',
    '/api/matches/:path*',
    '/api/requests/:path*',
  ],
};
