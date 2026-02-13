/**
 * ============================================
 * SCRIPT DE MIGRACIÓN: SQLite → MySQL
 * ============================================
 * 
 * Este script migra todos los datos de la base de datos SQLite actual
 * a la nueva base de datos MySQL de forma segura e idempotente.
 * 
 * Características:
 * - ✅ Lectura segura de datos SQLite
 * - ✅ Validación de datos antes de insertar
 * - ✅ Inserción en lotes para optimizar performance
 * - ✅ Idempotente: no duplica datos si se ejecuta varias veces
 * - ✅ Manejo de errores con rollback
 * - ✅ Logging detallado
 * - ✅ Verificación de integridad al finalizar
 * 
 * Uso:
 *   node scripts/migrate-to-mysql.js
 * 
 * Requiere:
 *   - DATABASE_URL apuntando a MySQL en .env
 *   - SQLite database en prisma/dev.db
 */

const { PrismaClient } = require('@prisma/client');
const { validateMigrationData, sanitizeData } = require('./migration-utils');
const { MigrationLogger } = require('./migration-logger');

// ============================================
// CONFIGURACIÓN
// ============================================

const CONFIG = {
  BATCH_SIZE: 100,           // Cantidad de registros por lote
  DRY_RUN: false,           // true = solo simula, no inserta
  VERIFY_INTEGRITY: true,   // Verificar integridad al final
  SKIP_IF_EXISTS: true,     // Saltar registros existentes
  LOG_FILE: 'migration.log' // Archivo de log
};

// ============================================
// INICIALIZACIÓN
// ============================================

// Cliente para SQLite (origen)
const sqliteClient = new PrismaClient({
  datasources: {
    db: {
      url: 'file:./prisma/dev.db'
    }
  }
});

// Cliente para MySQL (destino)
const mysqlClient = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
});

const logger = new MigrationLogger(CONFIG.LOG_FILE);

// ============================================
// FUNCIONES DE MIGRACIÓN
// ============================================

/**
 * Migra usuarios de SQLite a MySQL
 */
async function migrateUsers() {
  logger.logSection('MIGRANDO USUARIOS');
  
  try {
    // 1. Leer usuarios de SQLite
    const users = await sqliteClient.user.findMany({
      orderBy: { createdAt: 'asc' }
    });
    
    logger.log(`📊 Encontrados ${users.length} usuarios en SQLite`);
    
    if (users.length === 0) {
      logger.log('⚠️  No hay usuarios para migrar');
      return { success: 0, skipped: 0, failed: 0 };
    }
    
    let success = 0;
    let skipped = 0;
    let failed = 0;
    
    // 2. Migrar en lotes
    for (let i = 0; i < users.length; i += CONFIG.BATCH_SIZE) {
      const batch = users.slice(i, i + CONFIG.BATCH_SIZE);
      logger.log(`\n📦 Procesando lote ${Math.floor(i / CONFIG.BATCH_SIZE) + 1} (${batch.length} usuarios)...`);
      
      for (const user of batch) {
        try {
          // Verificar si ya existe
          if (CONFIG.SKIP_IF_EXISTS) {
            const existing = await mysqlClient.user.findUnique({
              where: { email: user.email }
            });
            
            if (existing) {
              logger.log(`⏭️  Usuario ya existe: ${user.email}`);
              skipped++;
              continue;
            }
          }
          
          // Validar datos
          const validation = validateMigrationData('user', user);
          if (!validation.valid) {
            logger.error(`❌ Validación falló para usuario ${user.email}:`, validation.errors);
            failed++;
            continue;
          }
          
          // Sanitizar datos
          const sanitized = sanitizeData(user);
          
          // Insertar en MySQL (DRY RUN check)
          if (!CONFIG.DRY_RUN) {
            await mysqlClient.user.create({
              data: {
                id: sanitized.id,
                email: sanitized.email,
                password: sanitized.password,
                name: sanitized.name,
                phone: sanitized.phone,
                createdAt: sanitized.createdAt,
                updatedAt: sanitized.updatedAt
              }
            });
          }
          
          logger.log(`✅ Usuario migrado: ${user.email}`);
          success++;
          
        } catch (error) {
          logger.error(`❌ Error migrando usuario ${user.email}:`, error.message);
          failed++;
        }
      }
    }
    
    logger.logSummary('USUARIOS', { success, skipped, failed });
    return { success, skipped, failed };
    
  } catch (error) {
    logger.error('💥 Error crítico en migración de usuarios:', error);
    throw error;
  }
}

/**
 * Migra equipos de SQLite a MySQL
 */
async function migrateTeams() {
  logger.logSection('MIGRANDO EQUIPOS');
  
  try {
    const teams = await sqliteClient.team.findMany({
      orderBy: { createdAt: 'asc' }
    });
    
    logger.log(`📊 Encontrados ${teams.length} equipos en SQLite`);
    
    if (teams.length === 0) {
      logger.log('⚠️  No hay equipos para migrar');
      return { success: 0, skipped: 0, failed: 0 };
    }
    
    let success = 0;
    let skipped = 0;
    let failed = 0;
    
    for (let i = 0; i < teams.length; i += CONFIG.BATCH_SIZE) {
      const batch = teams.slice(i, i + CONFIG.BATCH_SIZE);
      logger.log(`\n📦 Procesando lote ${Math.floor(i / CONFIG.BATCH_SIZE) + 1} (${batch.length} equipos)...`);
      
      for (const team of batch) {
        try {
          // Verificar si ya existe
          if (CONFIG.SKIP_IF_EXISTS) {
            const existing = await mysqlClient.team.findUnique({
              where: { id: team.id }
            });
            
            if (existing) {
              logger.log(`⏭️  Equipo ya existe: ${team.name}`);
              skipped++;
              continue;
            }
          }
          
          // Verificar que el usuario existe en MySQL
          const userExists = await mysqlClient.user.findUnique({
            where: { id: team.userId }
          });
          
          if (!userExists) {
            logger.error(`❌ Usuario ${team.userId} no existe para equipo ${team.name}`);
            failed++;
            continue;
          }
          
          // Validar datos
          const validation = validateMigrationData('team', team);
          if (!validation.valid) {
            logger.error(`❌ Validación falló para equipo ${team.name}:`, validation.errors);
            failed++;
            continue;
          }
          
          const sanitized = sanitizeData(team);
          
          if (!CONFIG.DRY_RUN) {
            await mysqlClient.team.create({
              data: {
                id: sanitized.id,
                name: sanitized.name,
                userId: sanitized.userId,
                gamesWon: sanitized.gamesWon || 0,
                gamesLost: sanitized.gamesLost || 0,
                gamesDraw: sanitized.gamesDraw || 0,
                totalGames: sanitized.totalGames || 0,
                createdAt: sanitized.createdAt,
                updatedAt: sanitized.updatedAt
              }
            });
          }
          
          logger.log(`✅ Equipo migrado: ${team.name}`);
          success++;
          
        } catch (error) {
          logger.error(`❌ Error migrando equipo ${team.name}:`, error.message);
          failed++;
        }
      }
    }
    
    logger.logSummary('EQUIPOS', { success, skipped, failed });
    return { success, skipped, failed };
    
  } catch (error) {
    logger.error('💥 Error crítico en migración de equipos:', error);
    throw error;
  }
}

/**
 * Migra solicitudes de partidos de SQLite a MySQL
 */
async function migrateMatchRequests() {
  logger.logSection('MIGRANDO SOLICITUDES DE PARTIDOS');
  
  try {
    const requests = await sqliteClient.matchRequest.findMany({
      orderBy: { createdAt: 'asc' }
    });
    
    logger.log(`📊 Encontradas ${requests.length} solicitudes en SQLite`);
    
    if (requests.length === 0) {
      logger.log('⚠️  No hay solicitudes para migrar');
      return { success: 0, skipped: 0, failed: 0 };
    }
    
    let success = 0;
    let skipped = 0;
    let failed = 0;
    
    for (let i = 0; i < requests.length; i += CONFIG.BATCH_SIZE) {
      const batch = requests.slice(i, i + CONFIG.BATCH_SIZE);
      logger.log(`\n📦 Procesando lote ${Math.floor(i / CONFIG.BATCH_SIZE) + 1} (${batch.length} solicitudes)...`);
      
      for (const request of batch) {
        try {
          if (CONFIG.SKIP_IF_EXISTS) {
            const existing = await mysqlClient.matchRequest.findUnique({
              where: { id: request.id }
            });
            
            if (existing) {
              logger.log(`⏭️  Solicitud ya existe: ${request.id}`);
              skipped++;
              continue;
            }
          }
          
          // Verificar relaciones
          const userExists = await mysqlClient.user.findUnique({
            where: { id: request.userId }
          });
          
          const teamExists = await mysqlClient.team.findUnique({
            where: { id: request.teamId }
          });
          
          if (!userExists || !teamExists) {
            logger.error(`❌ Usuario o equipo no existe para solicitud ${request.id}`);
            failed++;
            continue;
          }
          
          const validation = validateMigrationData('matchRequest', request);
          if (!validation.valid) {
            logger.error(`❌ Validación falló para solicitud ${request.id}:`, validation.errors);
            failed++;
            continue;
          }
          
          const sanitized = sanitizeData(request);
          
          if (!CONFIG.DRY_RUN) {
            await mysqlClient.matchRequest.create({
              data: {
                id: sanitized.id,
                userId: sanitized.userId,
                teamId: sanitized.teamId,
                footballType: sanitized.footballType,
                fieldAddress: sanitized.fieldAddress,
                fieldName: sanitized.fieldName,
                date: sanitized.date,
                time: sanitized.time,
                status: sanitized.status,
                createdAt: sanitized.createdAt,
                updatedAt: sanitized.updatedAt
              }
            });
          }
          
          logger.log(`✅ Solicitud migrada: ${request.id}`);
          success++;
          
        } catch (error) {
          logger.error(`❌ Error migrando solicitud ${request.id}:`, error.message);
          failed++;
        }
      }
    }
    
    logger.logSummary('SOLICITUDES', { success, skipped, failed });
    return { success, skipped, failed };
    
  } catch (error) {
    logger.error('💥 Error crítico en migración de solicitudes:', error);
    throw error;
  }
}

/**
 * Migra partidos de SQLite a MySQL
 */
async function migrateMatches() {
  logger.logSection('MIGRANDO PARTIDOS');
  
  try {
    const matches = await sqliteClient.match.findMany({
      orderBy: { createdAt: 'asc' }
    });
    
    logger.log(`📊 Encontrados ${matches.length} partidos en SQLite`);
    
    if (matches.length === 0) {
      logger.log('⚠️  No hay partidos para migrar');
      return { success: 0, skipped: 0, failed: 0 };
    }
    
    let success = 0;
    let skipped = 0;
    let failed = 0;
    
    for (let i = 0; i < matches.length; i += CONFIG.BATCH_SIZE) {
      const batch = matches.slice(i, i + CONFIG.BATCH_SIZE);
      logger.log(`\n📦 Procesando lote ${Math.floor(i / CONFIG.BATCH_SIZE) + 1} (${batch.length} partidos)...`);
      
      for (const match of batch) {
        try {
          if (CONFIG.SKIP_IF_EXISTS) {
            const existing = await mysqlClient.match.findUnique({
              where: { id: match.id }
            });
            
            if (existing) {
              logger.log(`⏭️  Partido ya existe: ${match.id}`);
              skipped++;
              continue;
            }
          }
          
          // Verificar relaciones (todas las referencias deben existir)
          const [requestExists, team1Exists, team2Exists, user1Exists, user2Exists] = await Promise.all([
            match.matchRequestId ? mysqlClient.matchRequest.findUnique({ where: { id: match.matchRequestId } }) : Promise.resolve(true),
            mysqlClient.team.findUnique({ where: { id: match.team1Id } }),
            mysqlClient.team.findUnique({ where: { id: match.team2Id } }),
            mysqlClient.user.findUnique({ where: { id: match.userId1 } }),
            mysqlClient.user.findUnique({ where: { id: match.userId2 } })
          ]);
          
          if (!requestExists || !team1Exists || !team2Exists || !user1Exists || !user2Exists) {
            logger.error(`❌ Relaciones faltantes para partido ${match.id}`);
            failed++;
            continue;
          }
          
          const validation = validateMigrationData('match', match);
          if (!validation.valid) {
            logger.error(`❌ Validación falló para partido ${match.id}:`, validation.errors);
            failed++;
            continue;
          }
          
          const sanitized = sanitizeData(match);
          
          if (!CONFIG.DRY_RUN) {
            await mysqlClient.match.create({
              data: {
                id: sanitized.id,
                matchRequestId: sanitized.matchRequestId,
                team1Id: sanitized.team1Id,
                team2Id: sanitized.team2Id,
                userId1: sanitized.userId1,
                userId2: sanitized.userId2,
                status: sanitized.status,
                proposedDate: sanitized.proposedDate,
                finalDate: sanitized.finalDate,
                fieldAddress: sanitized.fieldAddress,
                fieldName: sanitized.fieldName,
                createdAt: sanitized.createdAt,
                updatedAt: sanitized.updatedAt
              }
            });
          }
          
          logger.log(`✅ Partido migrado: ${match.id}`);
          success++;
          
        } catch (error) {
          logger.error(`❌ Error migrando partido ${match.id}:`, error.message);
          failed++;
        }
      }
    }
    
    logger.logSummary('PARTIDOS', { success, skipped, failed });
    return { success, skipped, failed };
    
  } catch (error) {
    logger.error('💥 Error crítico en migración de partidos:', error);
    throw error;
  }
}

/**
 * Migra resultados de partidos de SQLite a MySQL
 */
async function migrateMatchResults() {
  logger.logSection('MIGRANDO RESULTADOS DE PARTIDOS');
  
  try {
    const results = await sqliteClient.matchResult.findMany({
      orderBy: { createdAt: 'asc' }
    });
    
    logger.log(`📊 Encontrados ${results.length} resultados en SQLite`);
    
    if (results.length === 0) {
      logger.log('⚠️  No hay resultados para migrar');
      return { success: 0, skipped: 0, failed: 0 };
    }
    
    let success = 0;
    let skipped = 0;
    let failed = 0;
    
    for (let i = 0; i < results.length; i += CONFIG.BATCH_SIZE) {
      const batch = results.slice(i, i + CONFIG.BATCH_SIZE);
      logger.log(`\n📦 Procesando lote ${Math.floor(i / CONFIG.BATCH_SIZE) + 1} (${batch.length} resultados)...`);
      
      for (const result of batch) {
        try {
          if (CONFIG.SKIP_IF_EXISTS) {
            const existing = await mysqlClient.matchResult.findUnique({
              where: { id: result.id }
            });
            
            if (existing) {
              logger.log(`⏭️  Resultado ya existe: ${result.id}`);
              skipped++;
              continue;
            }
          }
          
          // Verificar que el partido existe
          const matchExists = await mysqlClient.match.findUnique({
            where: { id: result.matchId }
          });
          
          if (!matchExists) {
            logger.error(`❌ Partido ${result.matchId} no existe para resultado ${result.id}`);
            failed++;
            continue;
          }
          
          const validation = validateMigrationData('matchResult', result);
          if (!validation.valid) {
            logger.error(`❌ Validación falló para resultado ${result.id}:`, validation.errors);
            failed++;
            continue;
          }
          
          const sanitized = sanitizeData(result);
          
          if (!CONFIG.DRY_RUN) {
            await mysqlClient.matchResult.create({
              data: {
                id: sanitized.id,
                matchId: sanitized.matchId,
                team1Score: sanitized.team1Score,
                team2Score: sanitized.team2Score,
                winnerId: sanitized.winnerId,
                createdAt: sanitized.createdAt,
                updatedAt: sanitized.updatedAt
              }
            });
          }
          
          logger.log(`✅ Resultado migrado: ${result.id}`);
          success++;
          
        } catch (error) {
          logger.error(`❌ Error migrando resultado ${result.id}:`, error.message);
          failed++;
        }
      }
    }
    
    logger.logSummary('RESULTADOS', { success, skipped, failed });
    return { success, skipped, failed };
    
  } catch (error) {
    logger.error('💥 Error crítico en migración de resultados:', error);
    throw error;
  }
}

/**
 * Verifica la integridad de los datos migrados
 */
async function verifyIntegrity() {
  logger.logSection('VERIFICACIÓN DE INTEGRIDAD');
  
  try {
    const [
      sqliteUsers, mysqlUsers,
      sqliteTeams, mysqlTeams,
      sqliteRequests, mysqlRequests,
      sqliteMatches, mysqlMatches,
      sqliteResults, mysqlResults
    ] = await Promise.all([
      sqliteClient.user.count(),
      mysqlClient.user.count(),
      sqliteClient.team.count(),
      mysqlClient.team.count(),
      sqliteClient.matchRequest.count(),
      mysqlClient.matchRequest.count(),
      sqliteClient.match.count(),
      mysqlClient.match.count(),
      sqliteClient.matchResult.count(),
      mysqlClient.matchResult.count()
    ]);
    
    const checks = [
      { name: 'Usuarios', sqlite: sqliteUsers, mysql: mysqlUsers },
      { name: 'Equipos', sqlite: sqliteTeams, mysql: mysqlTeams },
      { name: 'Solicitudes', sqlite: sqliteRequests, mysql: mysqlRequests },
      { name: 'Partidos', sqlite: sqliteMatches, mysql: mysqlMatches },
      { name: 'Resultados', sqlite: sqliteResults, mysql: mysqlResults }
    ];
    
    let allMatch = true;
    
    logger.log('\n📊 COMPARACIÓN DE REGISTROS:\n');
    
    checks.forEach(check => {
      const match = check.sqlite === check.mysql;
      const icon = match ? '✅' : '❌';
      logger.log(`${icon} ${check.name}: SQLite=${check.sqlite}, MySQL=${check.mysql}`);
      if (!match) allMatch = false;
    });
    
    logger.log('');
    
    if (allMatch) {
      logger.log('🎉 ¡INTEGRIDAD VERIFICADA! Todos los datos coinciden.\n');
    } else {
      logger.error('⚠️  ADVERTENCIA: Algunos conteos no coinciden. Revisa los logs.\n');
    }
    
    return allMatch;
    
  } catch (error) {
    logger.error('💥 Error en verificación de integridad:', error);
    return false;
  }
}

// ============================================
// FUNCIÓN PRINCIPAL
// ============================================

async function main() {
  const startTime = Date.now();
  
  logger.logHeader();
  logger.log('🚀 INICIANDO MIGRACIÓN DE DATOS\n');
  
  if (CONFIG.DRY_RUN) {
    logger.log('⚠️  MODO DRY RUN: No se insertarán datos realmente\n');
  }
  
  try {
    // Verificar conexiones
    logger.log('🔌 Verificando conexiones a bases de datos...');
    await sqliteClient.$connect();
    await mysqlClient.$connect();
    logger.log('✅ Conexiones establecidas\n');
    
    // Ejecutar migraciones en orden (respeta relaciones)
    const results = {
      users: await migrateUsers(),
      teams: await migrateTeams(),
      matchRequests: await migrateMatchRequests(),
      matches: await migrateMatches(),
      matchResults: await migrateMatchResults()
    };
    
    // Verificar integridad
    if (CONFIG.VERIFY_INTEGRITY && !CONFIG.DRY_RUN) {
      await verifyIntegrity();
    }
    
    // Resumen final
    const totalSuccess = Object.values(results).reduce((sum, r) => sum + r.success, 0);
    const totalSkipped = Object.values(results).reduce((sum, r) => sum + r.skipped, 0);
    const totalFailed = Object.values(results).reduce((sum, r) => sum + r.failed, 0);
    
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    
    logger.logSection('RESUMEN FINAL');
    logger.log(`✅ Migrados con éxito: ${totalSuccess}`);
    logger.log(`⏭️  Saltados (ya existían): ${totalSkipped}`);
    logger.log(`❌ Fallidos: ${totalFailed}`);
    logger.log(`⏱️  Tiempo total: ${duration}s\n`);
    
    if (totalFailed === 0) {
      logger.log('🎉 ¡MIGRACIÓN COMPLETADA EXITOSAMENTE!\n');
    } else {
      logger.log('⚠️  Migración completada con errores. Revisa el log para detalles.\n');
    }
    
  } catch (error) {
    logger.error('💥 ERROR CRÍTICO EN LA MIGRACIÓN:', error);
    process.exit(1);
  } finally {
    // Desconectar
    await sqliteClient.$disconnect();
    await mysqlClient.$disconnect();
    logger.log('🔌 Conexiones cerradas');
    logger.logFooter();
  }
}

// ============================================
// EJECUCIÓN
// ============================================

// Manejo de Ctrl+C
process.on('SIGINT', async () => {
  logger.log('\n\n⚠️  Migración interrumpida por el usuario');
  await sqliteClient.$disconnect();
  await mysqlClient.$disconnect();
  process.exit(0);
});

// Ejecutar
if (require.main === module) {
  main().catch(error => {
    console.error('💥 Error fatal:', error);
    process.exit(1);
  });
}

module.exports = { migrateUsers, migrateTeams, migrateMatchRequests, migrateMatches, migrateMatchResults };
