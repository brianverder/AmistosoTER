/**
 * ============================================
 * SCRIPT DE PRUEBA DE MIGRACIÓN
 * ============================================
 * 
 * Este script crea datos de prueba en SQLite y luego
 * ejecuta la migración para verificar que todo funciona.
 * 
 * SOLO PARA TESTING - NO usar en producción
 */

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: 'file:./prisma/test.db' // Base de datos de prueba
    }
  }
});

async function createTestData() {
  console.log('🧪 Creando datos de prueba...\n');
  
  try {
    // 1. Crear usuarios de prueba
    console.log('👤 Creando usuarios...');
    const users = await Promise.all([
      prisma.user.create({
        data: {
          email: 'test1@ejemplo.com',
          password: await bcrypt.hash('password123', 10),
          name: 'Usuario Test 1',
          phone: '+34612345678'
        }
      }),
      prisma.user.create({
        data: {
          email: 'test2@ejemplo.com',
          password: await bcrypt.hash('password123', 10),
          name: 'Usuario Test 2',
          phone: '+34687654321'
        }
      }),
      prisma.user.create({
        data: {
          email: 'test3@ejemplo.com',
          password: await bcrypt.hash('password123', 10),
          name: 'Usuario Test 3',
          phone: '+34611223344'
        }
      })
    ]);
    console.log(`   ✅ ${users.length} usuarios creados\n`);
    
    // 2. Crear equipos
    console.log('⚽ Creando equipos...');
    const teams = await Promise.all([
      prisma.team.create({
        data: {
          name: 'Los Cracks FC',
          userId: users[0].id,
          gamesWon: 5,
          gamesLost: 2,
          gamesDraw: 1,
          totalGames: 8
        }
      }),
      prisma.team.create({
        data: {
          name: 'Tigres United',
          userId: users[1].id,
          gamesWon: 3,
          gamesLost: 4,
          gamesDraw: 2,
          totalGames: 9
        }
      }),
      prisma.team.create({
        data: {
          name: 'Águilas FC',
          userId: users[2].id,
          gamesWon: 7,
          gamesLost: 1,
          gamesDraw: 0,
          totalGames: 8
        }
      }),
      prisma.team.create({
        data: {
          name: 'Leones FC',
          userId: users[0].id,
          gamesWon: 2,
          gamesLost: 5,
          gamesDraw: 1,
          totalGames: 8
        }
      })
    ]);
    console.log(`   ✅ ${teams.length} equipos creados\n`);
    
    // 3. Crear solicitudes de partidos
    console.log('📝 Creando solicitudes...');
    const requests = await Promise.all([
      prisma.matchRequest.create({
        data: {
          userId: users[0].id,
          teamId: teams[0].id,
          footballType: '7',
          fieldAddress: 'Calle Principal 123, Madrid',
          fieldName: 'Polideportivo Central',
          date: new Date('2026-02-20'),
          time: '18:00',
          status: 'active'
        }
      }),
      prisma.matchRequest.create({
        data: {
          userId: users[1].id,
          teamId: teams[1].id,
          footballType: '11',
          fieldAddress: 'Av. Deportes 456, Barcelona',
          fieldName: 'Campo Municipal',
          date: new Date('2026-02-22'),
          time: '19:00',
          status: 'active'
        }
      }),
      prisma.matchRequest.create({
        data: {
          userId: users[2].id,
          teamId: teams[2].id,
          footballType: '5',
          fieldAddress: 'Plaza Fútbol 789, Valencia',
          fieldName: 'Indoor Sport Center',
          date: new Date('2026-02-25'),
          time: '20:00',
          status: 'matched'
        }
      })
    ]);
    console.log(`   ✅ ${requests.length} solicitudes creadas\n`);
    
    // 4. Crear partidos
    console.log('🎮 Creando partidos...');
    const matches = await Promise.all([
      prisma.match.create({
        data: {
          matchRequestId: requests[2].id,
          team1Id: teams[2].id,
          team2Id: teams[0].id,
          userId1: users[2].id,
          userId2: users[0].id,
          status: 'completed',
          proposedDate: new Date('2026-02-15'),
          finalDate: new Date('2026-02-15'),
          fieldAddress: 'Plaza Fútbol 789, Valencia',
          fieldName: 'Indoor Sport Center'
        }
      }),
      prisma.match.create({
        data: {
          matchRequestId: null,
          team1Id: teams[1].id,
          team2Id: teams[3].id,
          userId1: users[1].id,
          userId2: users[0].id,
          status: 'pending',
          proposedDate: new Date('2026-02-28'),
          finalDate: null,
          fieldAddress: 'Av. Deportes 456, Barcelona',
          fieldName: 'Campo Municipal'
        }
      })
    ]);
    console.log(`   ✅ ${matches.length} partidos creados\n`);
    
    // 5. Crear resultados
    console.log('📊 Creando resultados...');
    const results = await Promise.all([
      prisma.matchResult.create({
        data: {
          matchId: matches[0].id,
          team1Score: 5,
          team2Score: 3,
          winnerId: teams[2].id
        }
      })
    ]);
    console.log(`   ✅ ${results.length} resultados creados\n`);
    
    // Resumen
    console.log('━'.repeat(60));
    console.log('✅ DATOS DE PRUEBA CREADOS EXITOSAMENTE\n');
    console.log('📊 RESUMEN:');
    console.log(`   👤 Usuarios:    ${users.length}`);
    console.log(`   ⚽ Equipos:      ${teams.length}`);
    console.log(`   📝 Solicitudes: ${requests.length}`);
    console.log(`   🎮 Partidos:    ${matches.length}`);
    console.log(`   📊 Resultados:  ${results.length}`);
    console.log('━'.repeat(60));
    console.log('\n💡 Ahora puedes ejecutar la migración:');
    console.log('   npm run migrate:to-mysql\n');
    
  } catch (error) {
    console.error('❌ Error creando datos de prueba:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

async function cleanTestData() {
  console.log('🧹 Limpiando datos de prueba...\n');
  
  try {
    await prisma.matchResult.deleteMany();
    await prisma.match.deleteMany();
    await prisma.matchRequest.deleteMany();
    await prisma.team.deleteMany();
    await prisma.user.deleteMany();
    
    console.log('✅ Datos de prueba eliminados\n');
  } catch (error) {
    console.error('❌ Error limpiando datos:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Ejecutar según argumento
const command = process.argv[2];

if (command === 'create') {
  createTestData();
} else if (command === 'clean') {
  cleanTestData();
} else {
  console.log(`
🧪 GENERADOR DE DATOS DE PRUEBA

USO:
  node scripts/test-migration.js create  - Crea datos de prueba
  node scripts/test-migration.js clean   - Elimina datos de prueba

EJEMPLO DE FLUJO COMPLETO:
  1. node scripts/test-migration.js create
  2. npm run migrate:to-mysql
  3. Verificar datos en MySQL
  4. node scripts/test-migration.js clean
  `);
}

module.exports = { createTestData, cleanTestData };
