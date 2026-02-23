#!/usr/bin/env node
/**
 * ============================================================
 * setup-mysql.js — Inicialización de la Base de Datos MySQL
 * ============================================================
 *
 * Ejecutar una sola vez antes de correr el servidor:
 *   node scripts/setup-mysql.js
 *
 * Luego migrar el schema con Prisma:
 *   npx prisma migrate dev --name init
 *   (o en producción: npx prisma migrate deploy)
 *
 * Requisitos:
 *   - MySQL/MariaDB corriendo en localhost:3306
 *   - Variables DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME en .env
 * ============================================================
 */

require('dotenv').config();
const mysql = require('mysql2/promise');

const {
  DB_HOST     = 'localhost',
  DB_PORT     = '3306',
  DB_USER     = 'root',
  DB_PASSWORD = 'root',
  DB_NAME     = 'amistosos_db',
} = process.env;

async function setup() {
  console.log('\n🔧  Iniciando configuración de MySQL...\n');
  console.log(`   Host     : ${DB_HOST}:${DB_PORT}`);
  console.log(`   Usuario  : ${DB_USER}`);
  console.log(`   Base     : ${DB_NAME}\n`);

  // ── 1. Conectar sin seleccionar base de datos ──
  let conn;
  try {
    conn = await mysql.createConnection({
      host    : DB_HOST,
      port    : parseInt(DB_PORT),
      user    : DB_USER,
      password: DB_PASSWORD,
      multipleStatements: true,
    });
    console.log('✅  Conexión a MySQL exitosa');
  } catch (err) {
    console.error('❌  No se pudo conectar a MySQL:', err.message);
    console.error('\n   Asegúrate de que MySQL esté corriendo y de que');
    console.error('   las variables de entorno estén configuradas:\n');
    console.error('   DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME\n');
    process.exit(1);
  }

  // ── 2. Crear la base de datos si no existe ──
  try {
    await conn.query(`
      CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
      CHARACTER SET utf8mb4
      COLLATE utf8mb4_unicode_ci;
    `);
    console.log(`✅  Base de datos "${DB_NAME}" verificada/creada`);
  } catch (err) {
    console.error('❌  Error creando la base de datos:', err.message);
    await conn.end();
    process.exit(1);
  }

  // ── 3. Seleccionar la base ──
  await conn.query(`USE \`${DB_NAME}\`;`);

  // ── 4. Verificar privilegios mínimos ──
  try {
    await conn.query(`SELECT 1`);
    console.log('✅  Privilegios verificados\n');
  } catch (err) {
    console.error('❌  Error de privilegios:', err.message);
    await conn.end();
    process.exit(1);
  }

  await conn.end();

  // ── 5. Instrucciones para continuar ──
  console.log('═══════════════════════════════════════════════════════');
  console.log('  Base de datos lista. Siguientes pasos:\n');
  console.log('  1. Ejecutar migraciones de Prisma:');
  console.log('     npx prisma migrate dev --name init\n');
  console.log('  2. (Opcional) Abrir Prisma Studio:');
  console.log('     npx prisma studio\n');
  console.log('  3. Iniciar el servidor:');
  console.log('     npm run dev');
  console.log('═══════════════════════════════════════════════════════\n');
}

setup().catch((err) => {
  console.error('Error inesperado:', err);
  process.exit(1);
});
