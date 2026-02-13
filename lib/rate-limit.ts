/**
 * Rate Limiting middleware para proteger contra brute force y DDoS
 * Basado en IP + ruta
 */

import { NextRequest, NextResponse } from 'next/server';

interface RateLimitConfig {
  windowMs: number; // Ventana de tiempo en milisegundos
  maxRequests: number; // Número máximo de requests en la ventana
}

interface RateLimitEntry {
  count: number;
  resetTime: number;
}

// Store en memoria (en producción usar Redis)
const rateLimitStore = new Map<string, RateLimitEntry>();

// Configuración por endpoint
const RATE_LIMIT_CONFIGS: Record<string, RateLimitConfig> = {
  // Auth endpoints - muy restrictivos
  '/api/auth/register': {
    windowMs: 15 * 60 * 1000, // 15 minutos
    maxRequests: 5, // Solo 5 registros por IP cada 15 min
  },
  '/api/auth/signin': {
    windowMs: 15 * 60 * 1000, // 15 minutos
    maxRequests: 10, // 10 intentos de login cada 15 min
  },

  // API endpoints - moderadamente restrictivos
  '/api/teams': {
    windowMs: 15 * 60 * 1000,
    maxRequests: 100,
  },
  '/api/matches': {
    windowMs: 15 * 60 * 1000,
    maxRequests: 100,
  },
  '/api/requests': {
    windowMs: 15 * 60 * 1000,
    maxRequests: 100,
  },

  // Default para todos los demás
  default: {
    windowMs: 15 * 60 * 1000,
    maxRequests: 200,
  },
};

/**
 * Obtiene IP del cliente considerando proxies
 */
function getClientIp(request: NextRequest): string {
  // Intentar obtener IP real detrás de proxies/CDN
  const forwarded = request.headers.get('x-forwarded-for');
  const real = request.headers.get('x-real-ip');
  const cf = request.headers.get('cf-connecting-ip'); // Cloudflare
  
  if (forwarded) {
    // x-forwarded-for puede contener múltiples IPs
    return forwarded.split(',')[0].trim();
  }
  
  if (real) {
    return real;
  }
  
  if (cf) {
    return cf;
  }
  
  // Fallback (no debería ocurrir en producción con proxy)
  return 'unknown';
}

/**
 * Limpia entradas expiradas del store (garbage collection)
 */
function cleanupExpiredEntries() {
  const now = Date.now();
  for (const [key, entry] of rateLimitStore.entries()) {
    if (entry.resetTime < now) {
      rateLimitStore.delete(key);
    }
  }
}

// Ejecutar limpieza cada 5 minutos
if (typeof setInterval !== 'undefined') {
  setInterval(cleanupExpiredEntries, 5 * 60 * 1000);
}

/**
 * Obtiene configuración de rate limit para una ruta
 */
function getConfigForPath(pathname: string): RateLimitConfig {
  // Buscar coincidencia exacta
  if (RATE_LIMIT_CONFIGS[pathname]) {
    return RATE_LIMIT_CONFIGS[pathname];
  }

  // Buscar coincidencia parcial (ej: /api/teams/123 -> /api/teams)
  for (const [path, config] of Object.entries(RATE_LIMIT_CONFIGS)) {
    if (pathname.startsWith(path)) {
      return config;
    }
  }

  // Default
  return RATE_LIMIT_CONFIGS.default;
}

/**
 * Verifica rate limit para una request
 */
export function checkRateLimit(request: NextRequest): {
  allowed: boolean;
  limit: number;
  remaining: number;
  resetTime: number;
} {
  const ip = getClientIp(request);
  const pathname = new URL(request.url).pathname;
  const config = getConfigForPath(pathname);
  
  // Clave única: IP + pathname
  const key = `${ip}:${pathname}`;
  const now = Date.now();
  
  // Obtener entrada existente
  let entry = rateLimitStore.get(key);
  
  if (!entry || entry.resetTime < now) {
    // Nueva ventana
    entry = {
      count: 1,
      resetTime: now + config.windowMs,
    };
    rateLimitStore.set(key, entry);
    
    return {
      allowed: true,
      limit: config.maxRequests,
      remaining: config.maxRequests - 1,
      resetTime: entry.resetTime,
    };
  }
  
  // Incrementar contador
  entry.count++;
  
  if (entry.count > config.maxRequests) {
    // Límite excedido
    return {
      allowed: false,
      limit: config.maxRequests,
      remaining: 0,
      resetTime: entry.resetTime,
    };
  }
  
  return {
    allowed: true,
    limit: config.maxRequests,
    remaining: config.maxRequests - entry.count,
    resetTime: entry.resetTime,
  };
}

/**
 * Middleware helper que aplica rate limiting y retorna response si excede límite
 */
export function rateLimitMiddleware(request: NextRequest): NextResponse | null {
  const result = checkRateLimit(request);
  
  // Headers de rate limit (estándar de facto)
  const headers = new Headers({
    'X-RateLimit-Limit': result.limit.toString(),
    'X-RateLimit-Remaining': result.remaining.toString(),
    'X-RateLimit-Reset': new Date(result.resetTime).toISOString(),
  });
  
  if (!result.allowed) {
    // Retornar 429 Too Many Requests
    const resetInSeconds = Math.ceil((result.resetTime - Date.now()) / 1000);
    
    return NextResponse.json(
      {
        error: 'Demasiadas solicitudes. Por favor intenta más tarde.',
        retryAfter: resetInSeconds,
        resetAt: new Date(result.resetTime).toISOString(),
      },
      {
        status: 429,
        headers: {
          ...Object.fromEntries(headers),
          'Retry-After': resetInSeconds.toString(),
        },
      }
    );
  }
  
  // Permitir request pero agregar headers informativos
  return null; // null significa "continuar con la request"
}

/**
 * Helper para agregar headers de rate limit a una response exitosa
 */
export function addRateLimitHeaders(
  response: NextResponse,
  request: NextRequest
): NextResponse {
  const result = checkRateLimit(request);
  
  response.headers.set('X-RateLimit-Limit', result.limit.toString());
  response.headers.set('X-RateLimit-Remaining', result.remaining.toString());
  response.headers.set('X-RateLimit-Reset', new Date(result.resetTime).toISOString());
  
  return response;
}

/**
 * Decorator para API routes que necesitan rate limiting
 */
export function withRateLimit(
  handler: (request: NextRequest) => Promise<NextResponse>
) {
  return async (request: NextRequest): Promise<NextResponse> => {
    // Verificar rate limit
    const rateLimitResponse = rateLimitMiddleware(request);
    
    if (rateLimitResponse) {
      // Límite excedido, retornar 429
      return rateLimitResponse;
    }
    
    // Ejecutar handler original
    const response = await handler(request);
    
    // Agregar headers de rate limit
    return addRateLimitHeaders(response, request);
  };
}

/**
 * Resetea el contador para una IP y ruta específica
 * Útil para tests o para resetear después de verificación exitosa
 */
export function resetRateLimit(ip: string, pathname: string): void {
  const key = `${ip}:${pathname}`;
  rateLimitStore.delete(key);
}

/**
 * Obtiene estadísticas de rate limiting
 * Útil para monitoring
 */
export function getRateLimitStats(): {
  totalEntries: number;
  topConsumers: Array<{ key: string; count: number; resetTime: number }>;
} {
  const entries = Array.from(rateLimitStore.entries())
    .map(([key, entry]) => ({ key, ...entry }))
    .sort((a, b) => b.count - a.count);
  
  return {
    totalEntries: rateLimitStore.size,
    topConsumers: entries.slice(0, 10), // Top 10
  };
}
