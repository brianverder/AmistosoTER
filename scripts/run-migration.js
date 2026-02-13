#!/usr/bin/env node

/**
 * ============================================
 * SCRIPT EJECUTABLE DE MIGRACIÓN
 * ============================================
 * 
 * Wrapper simple para ejecutar la migración con opciones CLI
 */

const { exec } = require('child_process');
const path = require('path');

// Colores para terminal
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m'
};

function printBanner() {
  console.log(`
${colors.bright}${colors.cyan}╔════════════════════════════════════════════════════════════════╗
║           MIGRACIÓN DE DATOS: SQLite → MySQL                 ║
║                                                                ║
║  Este script migrará todos tus datos de forma segura         ║
║  desde SQLite a MySQL.                                        ║
╚════════════════════════════════════════════════════════════════╝${colors.reset}
  `);
}

function printHelp() {
  console.log(`
${colors.bright}USO:${colors.reset}
  node scripts/run-migration.js [opciones]
  npm run migrate:to-mysql

${colors.bright}OPCIONES:${colors.reset}
  --dry-run       Simula la migración sin insertar datos
  --help, -h      Muestra esta ayuda
  --verify        Solo verifica la integridad sin migrar

${colors.bright}EJEMPLOS:${colors.reset}
  # Migración completa
  npm run migrate:to-mysql

  # Simular sin insertar (prueba)
  npm run migrate:dry-run

  # Con Node directamente
  node scripts/run-migration.js

${colors.bright}REQUISITOS PREVIOS:${colors.reset}
  1. MySQL debe estar corriendo
  2. Schema creado: mysql -u root -p < database/mysql_schema.sql
  3. DATABASE_URL configurado en .env
  4. Backup de seguridad de dev.db (recomendado)

${colors.bright}MÁS INFO:${colors.reset}
  Lee la guía completa: scripts/MIGRATION_GUIDE.md
  `);
}

function checkPrerequisites() {
  console.log(`${colors.cyan}🔍 Verificando requisitos previos...${colors.reset}\n`);
  
  const fs = require('fs');
  const checks = [];
  
  // 1. Verificar que existe .env
  const envExists = fs.existsSync('.env');
  checks.push({
    name: 'Archivo .env',
    passed: envExists,
    message: envExists ? '✅ Encontrado' : '❌ No encontrado (copia .env.example a .env)'
  });
  
  // 2. Verificar que existe dev.db
  const dbExists = fs.existsSync('prisma/dev.db');
  checks.push({
    name: 'Base SQLite (dev.db)',
    passed: dbExists,
    message: dbExists ? '✅ Encontrada' : '⚠️  No encontrada (¿tienes datos para migrar?)'
  });
  
  // 3. Verificar DATABASE_URL en .env
  if (envExists) {
    const envContent = fs.readFileSync('.env', 'utf8');
    const hasMySQLUrl = envContent.includes('mysql://');
    checks.push({
      name: 'DATABASE_URL (MySQL)',
      passed: hasMySQLUrl,
      message: hasMySQLUrl ? '✅ Configurado' : '⚠️  No apunta a MySQL (verifica .env)'
    });
  }
  
  // 4. Verificar que existe el script de migración
  const scriptExists = fs.existsSync('scripts/migrate-to-mysql.js');
  checks.push({
    name: 'Script de migración',
    passed: scriptExists,
    message: scriptExists ? '✅ Encontrado' : '❌ No encontrado'
  });
  
  // Mostrar resultados
  checks.forEach(check => {
    console.log(`  ${check.message}`);
  });
  
  console.log('');
  
  // Verificar si hay errores críticos
  const criticalFailed = checks.some(c => !c.passed && c.message.includes('❌'));
  
  if (criticalFailed) {
    console.log(`${colors.red}❌ Faltan requisitos críticos. No se puede continuar.${colors.reset}\n`);
    return false;
  }
  
  const warningExists = checks.some(c => !c.passed && c.message.includes('⚠️'));
  if (warningExists) {
    console.log(`${colors.yellow}⚠️  Hay advertencias. Revisa antes de continuar.${colors.reset}\n`);
  } else {
    console.log(`${colors.green}✅ Todos los requisitos cumplidos.${colors.reset}\n`);
  }
  
  return true;
}

function confirmMigration() {
  return new Promise((resolve) => {
    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });
    
    console.log(`${colors.yellow}⚠️  ADVERTENCIA:${colors.reset}`);
    console.log('   Esta operación migrará datos a MySQL.');
    console.log('   Asegúrate de tener un backup de seguridad.\n');
    
    readline.question('¿Deseas continuar? (s/N): ', (answer) => {
      readline.close();
      resolve(answer.toLowerCase() === 's' || answer.toLowerCase() === 'y');
    });
  });
}

async function main() {
  const args = process.argv.slice(2);
  
  // Mostrar ayuda
  if (args.includes('--help') || args.includes('-h')) {
    printHelp();
    process.exit(0);
  }
  
  printBanner();
  
  // Verificar requisitos
  const prereqsPassed = checkPrerequisites();
  if (!prereqsPassed) {
    console.log(`${colors.yellow}Ejecuta: npm install${colors.reset}`);
    console.log(`${colors.yellow}y configura .env correctamente${colors.reset}\n`);
    process.exit(1);
  }
  
  // Confirmar con usuario (solo en modo interactivo)
  if (process.stdin.isTTY && !args.includes('--dry-run')) {
    const confirmed = await confirmMigration();
    if (!confirmed) {
      console.log(`\n${colors.yellow}⏸️  Migración cancelada por el usuario.${colors.reset}\n`);
      process.exit(0);
    }
  }
  
  // Ejecutar migración
  console.log(`${colors.cyan}🚀 Iniciando migración...${colors.reset}\n`);
  console.log('─'.repeat(70) + '\n');
  
  const scriptPath = path.join(__dirname, 'migrate-to-mysql.js');
  const migrationScript = require(scriptPath);
  
  // Si es llamado como módulo, ejecutar directamente
  if (require.main === module) {
    // Ejecutar como proceso hijo para mejor control
    const { spawn } = require('child_process');
    const child = spawn('node', [scriptPath, ...args], {
      stdio: 'inherit'
    });
    
    child.on('exit', (code) => {
      if (code === 0) {
        console.log(`\n${colors.green}✅ Migración completada exitosamente${colors.reset}`);
        console.log(`\n${colors.cyan}📄 Revisa el log en: scripts/migration.log${colors.reset}\n`);
      } else {
        console.log(`\n${colors.red}❌ Migración falló con código ${code}${colors.reset}`);
        console.log(`\n${colors.yellow}📄 Revisa el log para más detalles: scripts/migration.log${colors.reset}\n`);
        process.exit(code);
      }
    });
  }
}

if (require.main === module) {
  main().catch(error => {
    console.error(`\n${colors.red}💥 Error fatal:${colors.reset}`, error);
    process.exit(1);
  });
}

module.exports = { checkPrerequisites, printHelp };
