/**
 * HELPERS DE SEGURIDAD Y VALIDACIÓN
 * 
 * Funciones para sanitización y validación de datos
 * Prevención de SQL injection, XSS y otros ataques
 */

import { z } from 'zod';

// ============================================
// VALIDACIÓN CON ZOD (Type-safe)
// ============================================

/**
 * Schema de validación para crear equipo
 */
export const createTeamSchema = z.object({
  name: z.string()
    .min(3, 'El nombre debe tener al menos 3 caracteres')
    .max(200, 'El nombre no puede exceder 200 caracteres')
    .trim()
    .refine(
      (name) => !/[<>{}]/g.test(name),
      'El nombre contiene caracteres no permitidos'
    ),
  description: z.string()
    .max(1000, 'La descripción no puede exceder 1000 caracteres')
    .optional(),
});

/**
 * Schema de validación para solicitud de partido
 */
export const createMatchRequestSchema = z.object({
  teamId: z.string().uuid('ID de equipo inválido'),
  footballType: z.enum(['5', '7', '8', '11', 'otro']).optional(),
  fieldAddress: z.string().max(500).optional(),
  fieldPrice: z.number().min(0).max(99999.99).optional(),
  matchDate: z.coerce.date().min(new Date(), 'La fecha debe ser futura').optional(),
  league: z.string().max(100).optional(),
  description: z.string().max(2000).optional(),
});

/**
 * Schema de validación para resultado
 */
export const createResultSchema = z.object({
  matchId: z.string().uuid('ID de partido inválido'),
  team1Score: z.number().int().min(0).max(99),
  team2Score: z.number().int().min(0).max(99),
  penalties: z.boolean().default(false),
  team1Penalties: z.number().int().min(0).max(99).optional(),
  team2Penalties: z.number().int().min(0).max(99).optional(),
  notes: z.string().max(500).optional(),
}).refine(
  (data) => {
    // Si hay penales, ambos scores de penales deben estar presentes
    if (data.penalties) {
      return data.team1Penalties !== undefined && data.team2Penalties !== undefined;
    }
    return true;
  },
  {
    message: 'Si hay penales, se deben indicar los scores de penales',
  }
);

/**
 * Validar datos con schema de Zod
 * @throws Error si la validación falla
 */
export function validateData<T>(schema: z.ZodSchema<T>, data: unknown): T {
  try {
    return schema.parse(data);
  } catch (error) {
    if (error instanceof z.ZodError) {
      const messages = error.errors.map(e => `${e.path.join('.')}: ${e.message}`);
      throw new Error(`Validación fallida: ${messages.join(', ')}`);
    }
    throw error;
  }
}

/**
 * Validar datos de forma segura (no lanza error)
 */
export function safeValidateData<T>(
  schema: z.ZodSchema<T>, 
  data: unknown
): { success: true; data: T } | { success: false; errors: string[] } {
  const result = schema.safeParse(data);
  
  if (result.success) {
    return { success: true, data: result.data };
  } else {
    const errors = result.error.errors.map(e => 
      `${e.path.join('.')}: ${e.message}`
    );
    return { success: false, errors };
  }
}

// ============================================
// SANITIZACIÓN DE STRINGS
// ============================================

/**
 * Escapar HTML para prevenir XSS
 */
export function escapeHtml(text: string): string {
  const map: Record<string, string> = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;',
  };
  
  return text.replace(/[&<>"']/g, (char) => map[char]);
}

/**
 * Limpiar string de caracteres peligrosos
 */
export function sanitizeString(input: string): string {
  return input
    .trim()
    .replace(/[<>{}]/g, '') // Remover caracteres peligrosos
    .replace(/\s+/g, ' '); // Normalizar espacios
}

/**
 * Validar UUID
 */
export function isValidUuid(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

/**
 * Validar email
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validar teléfono (formato internacional)
 */
export function isValidPhone(phone: string): boolean {
  const phoneRegex = /^\+?[1-9]\d{1,14}$/;
  return phoneRegex.test(phone.replace(/[\s-]/g, ''));
}

// ============================================
// RATE LIMITING (Simple)
// ============================================

/**
 * Rate limiter simple en memoria
 * NOTA: Para producción, usar Redis
 */
class SimpleRateLimiter {
  private requests: Map<string, number[]> = new Map();
  
  constructor(
    private maxRequests: number,
    private windowMs: number
  ) {}
  
  /**
   * Verificar si una IP/identificador excedió el límite
   */
  isRateLimited(identifier: string): boolean {
    const now = Date.now();
    const requests = this.requests.get(identifier) || [];
    
    // Filtrar requests dentro de la ventana de tiempo
    const recentRequests = requests.filter(
      timestamp => now - timestamp < this.windowMs
    );
    
    // Si excede el límite, retornar true (bloqueado)
    if (recentRequests.length >= this.maxRequests) {
      return true;
    }
    
    // Agregar nueva request
    recentRequests.push(now);
    this.requests.set(identifier, recentRequests);
    
    return false;
  }
  
  /**
   * Resetear contador para un identificador
   */
  reset(identifier: string): void {
    this.requests.delete(identifier);
  }
  
  /**
   * Limpiar requests antiguas (ejecutar periódicamente)
   */
  cleanup(): void {
    const now = Date.now();
    
    for (const [identifier, requests] of this.requests.entries()) {
      const recentRequests = requests.filter(
        timestamp => now - timestamp < this.windowMs
      );
      
      if (recentRequests.length === 0) {
        this.requests.delete(identifier);
      } else {
        this.requests.set(identifier, recentRequests);
      }
    }
  }
}

// Límites por endpoint
export const loginLimiter = new SimpleRateLimiter(5, 15 * 60 * 1000); // 5 requests/15min
export const apiLimiter = new SimpleRateLimiter(100, 60 * 1000); // 100 requests/min

// Limpiar cada 5 minutos
if (typeof window === 'undefined') {
  setInterval(() => {
    loginLimiter.cleanup();
    apiLimiter.cleanup();
  }, 5 * 60 * 1000);
}

// ============================================
// HELPERS DE AUTORIZACIÓN
// ============================================

/**
 * Verificar si el usuario es dueño del recurso
 */
export function isResourceOwner(
  resourceUserId: string,
  sessionUserId?: string
): boolean {
  return !!sessionUserId && resourceUserId === sessionUserId;
}

/**
 * Error personalizado para autorización
 */
export class UnauthorizedError extends Error {
  constructor(message: string = 'No autorizado') {
    super(message);
    this.name = 'UnauthorizedError';
  }
}

/**
 * Error personalizado para validación
 */
export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

// ============================================
// HELPER PARA MANEJO DE ERRORES EN API
// ============================================

/**
 * Manejo centralizado de errores para API Routes
 */
export function handleApiError(error: unknown): {
  message: string;
  status: number;
} {
  // Error de Prisma
  if (error && typeof error === 'object' && 'code' in error) {
    const prismaError = error as { code: string; meta?: any };
    
    switch (prismaError.code) {
      case 'P2002':
        return {
          message: 'El registro ya existe',
          status: 409,
        };
      case 'P2025':
        return {
          message: 'Registro no encontrado',
          status: 404,
        };
      case 'P2003':
        return {
          message: 'Referencia inválida',
          status: 400,
        };
      default:
        console.error('Error de Prisma:', prismaError);
        return {
          message: 'Error de base de datos',
          status: 500,
        };
    }
  }
  
  // Error de validación (Zod)
  if (error instanceof ValidationError) {
    return {
      message: error.message,
      status: 400,
    };
  }
  
  // Error de autorización
  if (error instanceof UnauthorizedError) {
    return {
      message: error.message,
      status: 403,
    };
  }
  
  // Error genérico
  if (error instanceof Error) {
    console.error('Error:', error);
    return {
      message: process.env.NODE_ENV === 'development' 
        ? error.message 
        : 'Error del servidor',
      status: 500,
    };
  }
  
  // Error desconocido
  console.error('Error desconocido:', error);
  return {
    message: 'Error del servidor',
    status: 500,
  };
}

// ============================================
// EJEMPLO DE USO COMPLETO
// ============================================

/**
 * Ejemplo de API Route con todas las validaciones
 */
/*
import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { 
  createTeamSchema, 
  validateData, 
  handleApiError,
  apiLimiter 
} from '@/lib/security';

export async function POST(request: Request) {
  try {
    // 1. Rate limiting
    const ip = request.headers.get('x-forwarded-for') || 'unknown';
    if (apiLimiter.isRateLimited(ip)) {
      return NextResponse.json(
        { error: 'Demasiadas peticiones' },
        { status: 429 }
      );
    }
    
    // 2. Autenticación
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json(
        { error: 'No autenticado' },
        { status: 401 }
      );
    }
    
    // 3. Parsear body
    const body = await request.json();
    
    // 4. Validación
    const validatedData = validateData(createTeamSchema, body);
    
    // 5. Operación de BD
    const team = await prisma.team.create({
      data: {
        ...validatedData,
        userId: session.user.id,
      },
    });
    
    // 6. Respuesta exitosa
    return NextResponse.json(team, { status: 201 });
    
  } catch (error) {
    // 7. Manejo de errores
    const { message, status } = handleApiError(error);
    return NextResponse.json({ error: message }, { status });
  }
}
*/
