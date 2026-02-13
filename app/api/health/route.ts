/**
 * HEALTH CHECK ENDPOINT
 * Verificar estado de la conexión a MySQL
 * 
 * URL: GET /api/health
 */
import { NextResponse } from 'next/server';
import { checkDatabaseConnection, getDatabaseStats } from '@/lib/prisma';

export async function GET() {
  try {
    // Verificar conexión
    const isConnected = await checkDatabaseConnection();
    
    if (!isConnected) {
      return NextResponse.json(
        { 
          status: 'error', 
          database: 'disconnected',
          timestamp: new Date().toISOString(),
        },
        { status: 500 }
      );
    }
    
    // Obtener estadísticas (opcional)
    let stats = null;
    if (process.env.NODE_ENV === 'development') {
      stats = await getDatabaseStats();
    }
    
    return NextResponse.json({
      status: 'ok',
      database: 'connected',
      environment: process.env.NODE_ENV,
      timestamp: new Date().toISOString(),
      stats: stats || undefined,
    });
  } catch (error) {
    console.error('Error en health check:', error);
    
    return NextResponse.json(
      {
        status: 'error',
        database: 'error',
        message: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}
