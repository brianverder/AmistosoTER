/**
 * ============================================
 * LOGGER PERSONALIZADO PARA MIGRACIÓN
 * ============================================
 * 
 * Sistema de logging con salida a consola y archivo
 * para rastrear el progreso de la migración.
 */

const fs = require('fs');
const path = require('path');

class MigrationLogger {
  constructor(logFile = 'migration.log') {
    this.logFile = path.join(process.cwd(), 'scripts', logFile);
    this.startTime = Date.now();
    this.colors = {
      reset: '\x1b[0m',
      bright: '\x1b[1m',
      red: '\x1b[31m',
      green: '\x1b[32m',
      yellow: '\x1b[33m',
      blue: '\x1b[34m',
      magenta: '\x1b[35m',
      cyan: '\x1b[36m',
      gray: '\x1b[90m'
    };
    
    // Crear archivo de log (sobrescribir si existe)
    this._initLogFile();
  }
  
  /**
   * Inicializa el archivo de log
   */
  _initLogFile() {
    try {
      const dir = path.dirname(this.logFile);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      
      const header = `
${'='.repeat(80)}
MIGRACIÓN DE DATOS: SQLite → MySQL
${'='.repeat(80)}
Fecha: ${new Date().toISOString()}
Archivo: ${this.logFile}
${'='.repeat(80)}

`;
      
      fs.writeFileSync(this.logFile, header, 'utf8');
    } catch (error) {
      console.error('⚠️  No se pudo crear archivo de log:', error.message);
    }
  }
  
  /**
   * Escribe mensaje en consola y archivo
   */
  _write(message, color = null) {
    // Consola con color
    if (color && process.stdout.isTTY) {
      console.log(`${color}${message}${this.colors.reset}`);
    } else {
      console.log(message);
    }
    
    // Archivo sin color (remover códigos ANSI)
    const cleanMessage = message.replace(/\x1b\[\d+m/g, '');
    try {
      fs.appendFileSync(this.logFile, cleanMessage + '\n', 'utf8');
    } catch (error) {
      // Silenciar errores de escritura para no interrumpir la migración
    }
  }
  
  /**
   * Log normal
   */
  log(message) {
    const timestamp = this._timestamp();
    this._write(`[${timestamp}] ${message}`);
  }
  
  /**
   * Log de error
   */
  error(message, error = null) {
    const timestamp = this._timestamp();
    let fullMessage = `[${timestamp}] ❌ ${message}`;
    
    if (error) {
      if (error.stack) {
        fullMessage += `\n${error.stack}`;
      } else {
        fullMessage += `\n${JSON.stringify(error, null, 2)}`;
      }
    }
    
    this._write(fullMessage, this.colors.red);
  }
  
  /**
   * Log de advertencia
   */
  warn(message) {
    const timestamp = this._timestamp();
    this._write(`[${timestamp}] ⚠️  ${message}`, this.colors.yellow);
  }
  
  /**
   * Log de éxito
   */
  success(message) {
    const timestamp = this._timestamp();
    this._write(`[${timestamp}] ✅ ${message}`, this.colors.green);
  }
  
  /**
   * Log de información
   */
  info(message) {
    const timestamp = this._timestamp();
    this._write(`[${timestamp}] ℹ️  ${message}`, this.colors.cyan);
  }
  
  /**
   * Encabezado de sección
   */
  logSection(title) {
    const line = '─'.repeat(60);
    const message = `\n${line}\n  ${title}\n${line}`;
    this._write(message, this.colors.bright + this.colors.cyan);
  }
  
  /**
   * Encabezado principal
   */
  logHeader() {
    const header = `
╔${'═'.repeat(78)}╗
║${' '.repeat(20)}MIGRACIÓN DE DATOS: SQLite → MySQL${' '.repeat(23)}║
║${' '.repeat(78)}║
║  📦 Base de datos origen:  SQLite (prisma/dev.db)${' '.repeat(26)}║
║  🎯 Base de datos destino: MySQL${' '.repeat(45)}║
║  📅 Fecha: ${new Date().toLocaleString('es-ES')}${' '.repeat(48)}║
╚${'═'.repeat(78)}╝
`;
    this._write(header, this.colors.bright + this.colors.magenta);
  }
  
  /**
   * Pie de página
   */
  logFooter() {
    const duration = this._duration();
    const footer = `
╔${'═'.repeat(78)}╗
║${' '.repeat(25)}MIGRACIÓN FINALIZADA${' '.repeat(32)}║
║${' '.repeat(78)}║
║  ⏱️  Duración total: ${duration}${' '.repeat(53 - duration.length)}║
║  📄 Log guardado en: ${this.logFile}${' '.repeat(54 - this.logFile.length)}║
╚${'═'.repeat(78)}╝
`;
    this._write(footer, this.colors.bright + this.colors.magenta);
  }
  
  /**
   * Resumen de una tabla
   */
  logSummary(tableName, stats) {
    const message = `
┌─ RESUMEN: ${tableName} ${'─'.repeat(45 - tableName.length)}
│  ✅ Éxito:    ${stats.success}
│  ⏭️  Saltados: ${stats.skipped}
│  ❌ Fallidos: ${stats.failed}
└${'─'.repeat(60)}
`;
    this._write(message, this.colors.bright);
  }
  
  /**
   * Barra de progreso simple
   */
  logProgress(current, total, label = '') {
    const percentage = Math.round((current / total) * 100);
    const filled = Math.floor(percentage / 2);
    const empty = 50 - filled;
    const bar = '█'.repeat(filled) + '░'.repeat(empty);
    
    const message = `${label} [${bar}] ${percentage}% (${current}/${total})`;
    
    // En consola, sobrescribir la línea anterior
    if (process.stdout.isTTY) {
      process.stdout.clearLine(0);
      process.stdout.cursorTo(0);
      process.stdout.write(message);
      
      // Nueva línea al completar
      if (current === total) {
        process.stdout.write('\n');
      }
    } else {
      this._write(message);
    }
  }
  
  /**
   * Tabla de datos
   */
  logTable(headers, rows) {
    // Calcular ancho de columnas
    const colWidths = headers.map((header, i) => {
      const maxRowWidth = Math.max(...rows.map(row => String(row[i] || '').length));
      return Math.max(header.length, maxRowWidth);
    });
    
    // Construir tabla
    const separator = '─'.repeat(colWidths.reduce((sum, w) => sum + w + 3, 1));
    
    let table = `\n┌${separator}┐\n`;
    
    // Encabezados
    table += '│ ' + headers.map((h, i) => h.padEnd(colWidths[i])).join(' │ ') + ' │\n';
    table += `├${separator}┤\n`;
    
    // Filas
    rows.forEach(row => {
      table += '│ ' + row.map((cell, i) => String(cell || '').padEnd(colWidths[i])).join(' │ ') + ' │\n';
    });
    
    table += `└${separator}┘\n`;
    
    this._write(table);
  }
  
  /**
   * Timestamp formateado
   */
  _timestamp() {
    const now = new Date();
    return now.toTimeString().split(' ')[0]; // HH:MM:SS
  }
  
  /**
   * Duración desde inicio
   */
  _duration() {
    const ms = Date.now() - this.startTime;
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    
    if (hours > 0) {
      return `${hours}h ${minutes % 60}m ${seconds % 60}s`;
    } else if (minutes > 0) {
      return `${minutes}m ${seconds % 60}s`;
    } else {
      return `${seconds}s`;
    }
  }
  
  /**
   * Log estructurado (objeto JSON)
   */
  logJSON(obj, label = null) {
    if (label) {
      this.log(`${label}:`);
    }
    const json = JSON.stringify(obj, null, 2);
    this._write(json, this.colors.gray);
  }
  
  /**
   * Log de estadísticas
   */
  logStats(stats) {
    const entries = Object.entries(stats);
    const maxKeyLength = Math.max(...entries.map(([key]) => key.length));
    
    this._write('\n📊 ESTADÍSTICAS:', this.colors.bright);
    entries.forEach(([key, value]) => {
      const paddedKey = key.padEnd(maxKeyLength);
      this._write(`   ${paddedKey}: ${value}`);
    });
    this._write('');
  }
  
  /**
   * Separa bloques de log
   */
  separator() {
    this._write('\n' + '─'.repeat(80) + '\n');
  }
  
  /**
   * Obtiene la ruta del archivo de log
   */
  getLogFilePath() {
    return this.logFile;
  }
}

module.exports = { MigrationLogger };
