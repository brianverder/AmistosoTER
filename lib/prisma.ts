/**
 * Prisma Client Singleton para evitar múltiples instancias
 * Optimizado para MySQL en producción
 * 
 * @see https://www.prisma.io/docs/guides/performance-and-optimization/connection-management
 */
import { PrismaClient } from '@prisma/client';

// Declaración global para TypeScript
declare global {
  var prisma: PrismaClient | undefined;
}

/**
 * Configuración de Prisma Client optimizada para MySQL
 */
const prismaClientOptions = {
  // Logs solo en desarrollo
  log: process.env.NODE_ENV === 'development' 
    ? ['query', 'error', 'warn'] as const
    : ['error'] as const,
  
  // Configuración de pool de conexiones para MySQL
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
};

/**
 * Instancia Singleton de Prisma Client
 * - En desarrollo: reutiliza la conexión en hot-reload
 * - En producción: crea una nueva instancia
 */
export const prisma = globalThis.prisma ?? new PrismaClient(prismaClientOptions);

// En desarrollo, guardar en global para evitar múltiples instancias
if (process.env.NODE_ENV !== 'production') {
  globalThis.prisma = prisma;
}

/**
 * Graceful shutdown: Desconectar Prisma al cerrar la aplicación
 */
if (typeof window === 'undefined') {
  // Solo en servidor
  const cleanup = async () => {
    await prisma.$disconnect();
  };

  process.on('beforeExit', cleanup);
  process.on('SIGINT', cleanup);
  process.on('SIGTERM', cleanup);
}

/**
 * Helper para ejecutar queries en transacciones
 * @example
 * ```ts
 * await executeTransaction(async (tx) => {
 *   await tx.user.create({ data: {...} });
 *   await tx.team.create({ data: {...} });
 * });
 * ```
 */
export async function executeTransaction<T>(
  callback: (prisma: Omit<PrismaClient, '$connect' | '$disconnect' | '$on' | '$transaction' | '$use'>) => Promise<T>
): Promise<T> {
  return await prisma.$transaction(callback);
}

/**
 * Helper para verificar conexión a la base de datos
 * @returns true si la conexión es exitosa
 */
export async function checkDatabaseConnection(): Promise<boolean> {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return true;
  } catch (error) {
    console.error('❌ Error de conexión a la base de datos:', error);
    return false;
  }
}

/**
 * Helper para obtener estadísticas de conexión
 */
export async function getDatabaseStats() {
  try {
    const stats = await prisma.$queryRaw<Array<{
      table_name: string;
      table_rows: number;
      data_length: number;
      index_length: number;
    }>>`
      SELECT 
        table_name,
        table_rows,
        data_length,
        index_length
      FROM information_schema.tables
      WHERE table_schema = DATABASE()
      ORDER BY data_length DESC
    `;
    
    return stats;
  } catch (error) {
    console.error('Error obteniendo estadísticas:', error);
    return [];
  }
}
