import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

/**
 * GET /api/public/users-count
 * Retorna la cantidad total de usuarios registrados
 */
export async function GET() {
  try {
    const count = await prisma.user.count();

    return NextResponse.json({ count });
  } catch (error) {
    console.error('Error obteniendo cantidad de usuarios:', error);
    return NextResponse.json(
      { error: 'Error al obtener cantidad de usuarios' },
      { status: 500 }
    );
  }
}
