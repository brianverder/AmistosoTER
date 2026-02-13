/**
 * Conexión directa a MySQL usando mysql2
 * 
 * USAR SOLO cuando Prisma no sea suficiente (queries muy complejas, bulk operations, etc.)
 * Para operaciones CRUD normales, usar Prisma (lib/prisma.ts)
 * 
 * @see https://github.com/sidorares/node-mysql2
 */
import mysql from 'mysql2/promise';

// Configuración del pool de conexiones
const poolConfig: mysql.PoolOptions = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  
  // Pool de conexiones
  connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT || '10'),
  queueLimit: 0,
  
  // Timeouts
  connectTimeout: 10000, // 10 segundos
  
  // Charset
  charset: 'utf8mb4',
  
  // Configuración SSL para producción
  ssl: process.env.NODE_ENV === 'production' && process.env.DB_SSL === 'true'
    ? {
        rejectUnauthorized: true,
      }
    : undefined,
  
  // Opciones adicionales
  waitForConnections: true,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
};

/**
 * Pool de conexiones MySQL
 * Singleton que se reutiliza en toda la aplicación
 */
let pool: mysql.Pool | null = null;

/**
 * Obtener pool de conexiones MySQL
 * Crea el pool la primera vez y lo reutiliza en siguientes llamadas
 */
export function getPool(): mysql.Pool {
  if (!pool) {
    pool = mysql.createPool(poolConfig);
    
    // Log en desarrollo
    if (process.env.NODE_ENV === 'development') {
      console.log('✅ Pool de conexiones MySQL creado');
    }
  }
  
  return pool;
}

/**
 * Ejecutar query SQL con parámetros preparados (previene SQL injection)
 * 
 * @example
 * ```ts
 * const users = await query<User[]>('SELECT * FROM users WHERE email = ?', ['user@example.com']);
 * ```
 */
export async function query<T = any>(
  sql: string,
  params?: any[]
): Promise<T> {
  const connection = getPool();
  
  try {
    const [rows] = await connection.execute(sql, params);
    return rows as T;
  } catch (error) {
    console.error('❌ Error en query MySQL:', error);
    console.error('SQL:', sql);
    console.error('Params:', params);
    throw error;
  }
}

/**
 * Ejecutar query y retornar solo la primera fila
 * 
 * @example
 * ```ts
 * const user = await queryOne<User>('SELECT * FROM users WHERE id = ?', [userId]);
 * ```
 */
export async function queryOne<T = any>(
  sql: string,
  params?: any[]
): Promise<T | null> {
  const results = await query<T[]>(sql, params);
  return results.length > 0 ? results[0] : null;
}

/**
 * Ejecutar múltiples queries en una transacción
 * Si alguna falla, se hace rollback automático
 * 
 * @example
 * ```ts
 * await transaction(async (conn) => {
 *   await conn.execute('INSERT INTO users ...');
 *   await conn.execute('INSERT INTO teams ...');
 * });
 * ```
 */
export async function transaction<T = any>(
  callback: (connection: mysql.PoolConnection) => Promise<T>
): Promise<T> {
  const connection = await getPool().getConnection();
  
  try {
    await connection.beginTransaction();
    
    const result = await callback(connection);
    
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    console.error('❌ Error en transacción, rollback ejecutado:', error);
    throw error;
  } finally {
    connection.release();
  }
}

/**
 * Verificar conexión a MySQL
 */
export async function checkConnection(): Promise<boolean> {
  try {
    const result = await query<any[]>('SELECT 1 as test');
    return result.length > 0;
  } catch (error) {
    console.error('❌ Error de conexión a MySQL:', error);
    return false;
  }
}

/**
 * Cerrar pool de conexiones (usar en shutdown)
 */
export async function closePool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
    console.log('🔌 Pool de conexiones MySQL cerrado');
  }
}

/**
 * Escapar valores para prevenir SQL injection
 * NOTA: Preferir usar queries preparadas con '?' en lugar de esto
 */
export function escape(value: any): string {
  return mysql.escape(value);
}

/**
 * Escapar identificadores (nombres de tablas, columnas)
 */
export function escapeId(identifier: string): string {
  return mysql.escapeId(identifier);
}

// Cleanup al cerrar la aplicación
if (typeof window === 'undefined') {
  process.on('beforeExit', closePool);
  process.on('SIGINT', closePool);
  process.on('SIGTERM', closePool);
}
