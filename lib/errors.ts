/**
 * ============================================
 * CUSTOM ERRORS
 * ============================================
 * 
 * Errores personalizados para la aplicación.
 * Facilitan el manejo de errores y respuestas HTTP.
 */

export class AppError extends Error {
  public statusCode: number;
  public isOperational: boolean;

  constructor(message: string, statusCode: number = 500, isOperational: boolean = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;

    // Mantiene el stack trace correcto
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Error de validación (400)
 */
export class ValidationError extends AppError {
  constructor(message: string) {
    super(message, 400);
    this.name = 'ValidationError';
  }
}

/**
 * Error de autenticación (401)
 */
export class UnauthorizedError extends AppError {
  constructor(message: string = 'No autenticado') {
    super(message, 401);
    this.name = 'UnauthorizedError';
  }
}

/**
 * Error de autorización (403)
 */
export class ForbiddenError extends AppError {
  constructor(message: string = 'No autorizado') {
    super(message, 403);
    this.name = 'ForbiddenError';
  }
}

/**
 * Error de recurso no encontrado (404)
 */
export class NotFoundError extends AppError {
  constructor(message: string = 'Recurso no encontrado') {
    super(message, 404);
    this.name = 'NotFoundError';
  }
}

/**
 * Error de conflicto (409)
 */
export class ConflictError extends AppError {
  constructor(message: string) {
    super(message, 409);
    this.name = 'ConflictError';
  }
}

/**
 * Error de regla de negocio (422)
 */
export class BusinessRuleError extends AppError {
  constructor(message: string) {
    super(message, 422);
    this.name = 'BusinessRuleError';
  }
}

/**
 * Error de rate limiting (429)
 */
export class TooManyRequestsError extends AppError {
  constructor(message: string = 'Demasiadas solicitudes') {
    super(message, 429);
    this.name = 'TooManyRequestsError';
  }
}

/**
 * Error interno del servidor (500)
 */
export class InternalServerError extends AppError {
  constructor(message: string = 'Error interno del servidor') {
    super(message, 500);
    this.name = 'InternalServerError';
  }
}

/**
 * Handler de errores para API Routes
 */
export function handleApiError(error: unknown): {
  message: string;
  statusCode: number;
  stack?: string;
} {
  // Error de la aplicación
  if (error instanceof AppError) {
    return {
      message: error.message,
      statusCode: error.statusCode,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined,
    };
  }

  // Error de Prisma
  if (error && typeof error === 'object' && 'code' in error) {
    const prismaError = error as any;

    switch (prismaError.code) {
      case 'P2002':
        return {
          message: 'Este registro ya existe (violación de constraint único)',
          statusCode: 409,
        };
      case 'P2025':
        return {
          message: 'Registro no encontrado',
          statusCode: 404,
        };
      case 'P2003':
        return {
          message: 'Referencia inválida (foreign key)',
          statusCode: 400,
        };
      case 'P2014':
        return {
          message: 'Violación de relación requerida',
          statusCode: 400,
        };
      default:
        return {
          message: 'Error de base de datos',
          statusCode: 500,
        };
    }
  }

  // Error genérico
  const genericError = error as Error;
  return {
    message: genericError.message || 'Error desconocido',
    statusCode: 500,
    stack: process.env.NODE_ENV === 'development' ? genericError.stack : undefined,
  };
}
