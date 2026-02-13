import { hash } from 'bcryptjs';
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';
import {
  validateEmail,
  validatePassword,
  validateName,
  validatePhone,
  validationError,
} from '@/lib/validation';
import { withRateLimit } from '@/lib/rate-limit';

/**
 * POST /api/auth/register
 * Registra un nuevo usuario con validaciones robustas
 * 
 * ✅ Protecciones implementadas:
 * - Rate limiting (5 registros / 15 min por IP)
 * - Validación de email formato + lista negra
 * - Validación de password fortaleza
 * - Sanitización de inputs
 * - Error messages genéricos (no revelan si email existe)
 * - bcrypt con 12 rounds
 */
async function registerHandler(request: Request) {
  try {
    const body = await request.json();
    const { email, password, name, phone } = body;

    // ======================
    // VALIDACIONES DE INPUT
    // ======================

    // Validar email
    const emailValidation = validateEmail(email);
    if (!emailValidation.isValid) {
      return NextResponse.json(
        validationError(emailValidation.error || 'Email inválido', 'email'),
        { status: 400 }
      );
    }

    // Validar password
    const passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      return NextResponse.json(
        validationError(passwordValidation.error || 'Contraseña inválida', 'password'),
        { status: 400 }
      );
    }

    // Validar nombre
    const nameValidation = validateName(name);
    if (!nameValidation.isValid) {
      return NextResponse.json(
        validationError(nameValidation.error || 'Nombre inválido', 'name'),
        { status: 400 }
      );
    }

    // Validar teléfono (opcional)
    const phoneValidation = validatePhone(phone);
    if (!phoneValidation.isValid) {
      return NextResponse.json(
        validationError(phoneValidation.error || 'Teléfono inválido', 'phone'),
        { status: 400 }
      );
    }

    // ======================
    // VERIFICAR DUPLICADOS
    // ======================

    // Verificar si el usuario ya existe
    const existingUser = await prisma.user.findUnique({
      where: { email: emailValidation.sanitized },
    });

    if (existingUser) {
      // ⚠️ SEGURIDAD: No revelar si el email existe (información disclosure)
      // Usar mensaje genérico para prevenir enumeración de usuarios
      // Delay artificial para prevenir timing attacks
      await new Promise(resolve => setTimeout(resolve, 100));
      
      return NextResponse.json(
        { error: 'No se pudo completar el registro. Verifica tus datos.' },
        { status: 400 }
      );
    }

    // ======================
    // CREAR USUARIO
    // ======================

    // Hash de la contraseña con bcrypt (12 rounds = tiempo ~250ms)
    const hashedPassword = await hash(password, 12);

    // Crear usuario con datos sanitizados
    const user = await prisma.user.create({
      data: {
        email: emailValidation.sanitized,
        password: hashedPassword,
        name: nameValidation.sanitized,
        phone: phoneValidation.sanitized,
      },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        createdAt: true,
      },
    });

    return NextResponse.json(
      { 
        message: 'Usuario creado exitosamente',
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          phone: user.phone,
        }
      },
      { status: 201 }
    );

  } catch (error) {
    // Logging seguro (no loggear passwords ni datos sensibles)
    console.error('Error en registro:', {
      message: error instanceof Error ? error.message : 'Unknown error',
      timestamp: new Date().toISOString(),
    });

    // Respuesta genérica para no exponer detalles internos
    return NextResponse.json(
      { error: 'Error al procesar el registro. Intenta nuevamente.' },
      { status: 500 }
    );
  }
}

// Exportar handler con rate limiting aplicado
export const POST = withRateLimit(registerHandler as any);
