/**
 * Prisma Client Singleton para evitar múltiples instancias
 * Optimizado para MySQL en producción
 * 
 * @see https://www.prisma.io/docs/guides/performance-and-optimization/connection-management
 */
import { Prisma, PrismaClient } from '@prisma/client';

// Declaración global para TypeScript
declare global {
  var prisma: PrismaClient | undefined;
}

/**
 * Configuración de Prisma Client optimizada para MySQL
 */
const prismaClientOptions: Prisma.PrismaClientOptions = {
  // Logs solo en desarrollo
  log: process.env.NODE_ENV === 'development' 
    ? ['query', 'error', 'warn']
    : ['error'],
  
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
  callback: (tx: Prisma.TransactionClient) => Promise<T>
): Promise<T> {
  return prisma.$transaction((tx) => callback(tx));
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
      table_rows: bigint | number;
      data_length: bigint | number;
      index_length: bigint | number;
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

    // MySQL devuelve BigInt para columnas BIGINT — convertir a Number para JSON
    return stats.map((row) => ({
      table_name: row.table_name,
      table_rows: Number(row.table_rows),
      data_length: Number(row.data_length),
      index_length: Number(row.index_length),
    }));
  } catch (error) {
    console.error('Error obteniendo estadísticas:', error);
    return [];
  }
}
