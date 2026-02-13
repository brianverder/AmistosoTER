# 🔄 GUÍA DE MIGRACIÓN: SQLite → MySQL

Esta guía te ayudará a migrar todos tus datos de SQLite a MySQL de forma segura.

## 📋 Requisitos Previos

1. **Base de datos MySQL configurada**
   ```bash
   # Ejecutar el schema SQL
   mysql -u root -p < database/mysql_schema.sql
   ```

2. **Variables de entorno actualizadas**
   ```env
   # En .env
   DATABASE_URL="mysql://usuario:password@localhost:3306/amistoso_ter_db"
   ```

3. **Dependencias instaladas**
   ```bash
   npm install
   ```

4. **Backup de seguridad** (RECOMENDADO)
   ```bash
   # Copia de seguridad de SQLite
   cp prisma/dev.db prisma/dev.db.backup
   ```

## 🚀 Ejecución de la Migración

### Opción 1: Usando npm script (RECOMENDADO)

```bash
npm run migrate:to-mysql
```

### Opción 2: Ejecución directa

```bash
node scripts/migrate-to-mysql.js
```

### Opción 3: Modo DRY RUN (prueba sin insertar)

Edita `scripts/migrate-to-mysql.js` y cambia:
```javascript
const CONFIG = {
  DRY_RUN: true,  // Solo simula, no inserta datos
  // ...
};
```

Luego ejecuta:
```bash
node scripts/migrate-to-mysql.js
```

## 📊 Qué Hace el Script

### 1. Verificación Inicial
- ✅ Verifica conexión a SQLite
- ✅ Verifica conexión a MySQL
- ✅ Valida que el schema MySQL esté creado

### 2. Migración de Datos (en orden)
El script migra las tablas en este orden para respetar las relaciones:

1. **Usuarios** (`User`)
   - Lee de SQLite
   - Valida email, password, teléfono
   - Inserta en MySQL
   - Salta si el email ya existe

2. **Equipos** (`Team`)
   - Verifica que el usuario exista
   - Valida datos del equipo
   - Migra estadísticas (partidos ganados, perdidos, etc.)

3. **Solicitudes de Partidos** (`MatchRequest`)
   - Verifica usuario y equipo
   - Valida fechas y direcciones
   - Migra status (active, matched, cancelled)

4. **Partidos** (`Match`)
   - Verifica solicitud, equipos y usuarios
   - Valida fechas propuestas/finales
   - Migra status (pending, confirmed, completed)

5. **Resultados** (`MatchResult`)
   - Verifica que el partido exista
   - Valida marcadores
   - Determina equipo ganador

### 3. Validaciones Aplicadas

Para cada registro:
- ✅ **Validación de formato**: emails, IDs, fechas, teléfonos
- ✅ **Validación de rangos**: marcadores (0-99), estadísticas
- ✅ **Sanitización**: elimina caracteres peligrosos
- ✅ **Integridad referencial**: verifica que las FK existan
- ✅ **Prevención de duplicados**: salta registros existentes

### 4. Verificación Final
- Compara cantidad de registros: SQLite vs MySQL
- Muestra tabla resumen
- Confirma integridad de datos

## 📝 Logging

El script genera logs detallados en dos formatos:

### Consola (en tiempo real)
- Mensajes con colores
- Iconos visuales (✅ ❌ ⚠️ 📊)
- Barra de progreso

### Archivo `scripts/migration.log`
- Log completo sin colores
- Timestamps de cada operación
- Stack traces de errores
- Resumen final

## ⚙️ Configuración Avanzada

Edita el objeto `CONFIG` en [scripts/migrate-to-mysql.js](scripts/migrate-to-mysql.js):

```javascript
const CONFIG = {
  BATCH_SIZE: 100,           // Registros por lote (ajustar según memoria)
  DRY_RUN: false,           // true = simular sin insertar
  VERIFY_INTEGRITY: true,   // Verificar al final
  SKIP_IF_EXISTS: true,     // Saltar duplicados (recomendado)
  LOG_FILE: 'migration.log' // Nombre del archivo de log
};
```

### Ajuste de BATCH_SIZE
- **Pequeño (10-50)**: Más lento, menos memoria, mejor para debugging
- **Medio (100-500)**: Balance entre velocidad y seguridad
- **Grande (1000+)**: Más rápido, requiere más memoria

## 🔍 Solución de Problemas

### Error: "Cannot connect to MySQL"
```bash
# Verificar que MySQL esté corriendo
mysql -u root -p -e "SHOW DATABASES;"

# Verificar variables de entorno
echo $DATABASE_URL
```

### Error: "User/Team not found"
Esto significa que las referencias no son válidas. El script:
1. Registra el error en el log
2. Salta ese registro
3. Continúa con los siguientes

**Solución**: Revisa [scripts/migration.log](scripts/migration.log) para ver qué registros fallaron.

### Registros Duplicados
Si ejecutas el script varias veces, por defecto **salta** los registros que ya existen (basándose en email para usuarios, ID para el resto).

Para forzar sobrescritura:
```javascript
const CONFIG = {
  SKIP_IF_EXISTS: false,  // CUIDADO: puede causar errores de unique constraint
  // ...
};
```

### Proceso Interrumpido (Ctrl+C)
El script maneja la interrupción de forma segura:
- Cierra conexiones
- Guarda el log hasta ese punto
- **NO hace rollback** (registros ya insertados permanecen)

Para continuar:
1. Ejecuta el script nuevamente
2. Con `SKIP_IF_EXISTS: true`, saltará los ya migrados

## 📊 Ejemplo de Salida

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                    MIGRACIÓN DE DATOS: SQLite → MySQL                       ║
║                                                                              ║
║  📦 Base de datos origen:  SQLite (prisma/dev.db)                          ║
║  🎯 Base de datos destino: MySQL                                           ║
║  📅 Fecha: 13/02/2026 10:30:45                                             ║
╚══════════════════════════════════════════════════════════════════════════════╝

🚀 INICIANDO MIGRACIÓN DE DATOS

🔌 Verificando conexiones a bases de datos...
✅ Conexiones establecidas

────────────────────────────────────────────────────────────
  MIGRANDO USUARIOS
────────────────────────────────────────────────────────────
📊 Encontrados 15 usuarios en SQLite

📦 Procesando lote 1 (15 usuarios)...
✅ Usuario migrado: juan@ejemplo.com
✅ Usuario migrado: maria@ejemplo.com
⏭️  Usuario ya existe: admin@test.com
...

┌─ RESUMEN: USUARIOS ──────────────────────────────────────
│  ✅ Éxito:    12
│  ⏭️  Saltados: 3
│  ❌ Fallidos: 0
└──────────────────────────────────────────────────────────

[... continúa con equipos, solicitudes, etc. ...]

────────────────────────────────────────────────────────────
  VERIFICACIÓN DE INTEGRIDAD
────────────────────────────────────────────────────────────

📊 COMPARACIÓN DE REGISTROS:

✅ Usuarios: SQLite=15, MySQL=15
✅ Equipos: SQLite=23, MySQL=23
✅ Solicitudes: SQLite=45, MySQL=45
✅ Partidos: SQLite=32, MySQL=32
✅ Resultados: SQLite=28, MySQL=28

🎉 ¡INTEGRIDAD VERIFICADA! Todos los datos coinciden.

────────────────────────────────────────────────────────────
  RESUMEN FINAL
────────────────────────────────────────────────────────────
✅ Migrados con éxito: 143
⏭️  Saltados (ya existían): 3
❌ Fallidos: 0
⏱️  Tiempo total: 12.34s

🎉 ¡MIGRACIÓN COMPLETADA EXITOSAMENTE!

🔌 Conexiones cerradas

╔══════════════════════════════════════════════════════════════════════════════╗
║                         MIGRACIÓN FINALIZADA                                ║
║                                                                              ║
║  ⏱️  Duración total: 12.34s                                                ║
║  📄 Log guardado en: scripts/migration.log                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

## ✅ Verificación Post-Migración

Después de la migración, verifica que todo funcione:

### 1. Verificar cantidad de registros
```bash
mysql -u root -p amistoso_ter_db -e "
  SELECT 
    (SELECT COUNT(*) FROM users) as usuarios,
    (SELECT COUNT(*) FROM teams) as equipos,
    (SELECT COUNT(*) FROM match_requests) as solicitudes,
    (SELECT COUNT(*) FROM matches) as partidos,
    (SELECT COUNT(*) FROM match_results) as resultados;
"
```

### 2. Probar la aplicación
```bash
# Iniciar servidor con MySQL
npm run dev

# Probar login
# Probar crear equipo
# Probar crear solicitud
```

### 3. Usar el health check endpoint
```bash
curl http://localhost:3000/api/health
```

Respuesta esperada:
```json
{
  "status": "ok",
  "database": "connected",
  "environment": "development",
  "timestamp": "2026-02-13T10:30:45.123Z"
}
```

## 🔄 Rollback (si algo sale mal)

Si necesitas volver a SQLite:

1. **Detener el servidor**
   ```bash
   # Ctrl+C
   ```

2. **Restaurar .env**
   ```env
   DATABASE_URL="file:./dev.db"
   ```

3. **Regenerar cliente Prisma**
   ```bash
   npx prisma generate
   ```

4. **Reiniciar servidor**
   ```bash
   npm run dev
   ```

## 📚 Archivos del Sistema de Migración

- [scripts/migrate-to-mysql.js](scripts/migrate-to-mysql.js) - Script principal
- [scripts/migration-utils.js](scripts/migration-utils.js) - Validaciones y utilidades
- [scripts/migration-logger.js](scripts/migration-logger.js) - Sistema de logging
- `scripts/migration.log` - Log de ejecución (generado)

## 🆘 Soporte

Si encuentras problemas:

1. **Revisa el log**: [scripts/migration.log](scripts/migration.log)
2. **Ejecuta en modo DRY_RUN**: para ver qué pasaría sin insertar
3. **Verifica conexiones**: usa el health check
4. **Contacta soporte**: con el archivo `migration.log`

## ⚠️ Advertencias Importantes

- ❌ **NO ejecutes** el script en producción sin probarlo primero en desarrollo
- ✅ **SIEMPRE haz backup** antes de migrar
- ⚠️ **El script NO elimina** datos de SQLite (son solo lecturas)
- 🔄 **Es idempotente**: puedes ejecutarlo varias veces de forma segura
- 🛑 **Interrumpir con Ctrl+C** es seguro pero dejará la migración incompleta

## 💡 Consejos

1. **Primera vez**: Ejecuta en modo `DRY_RUN` para ver qué pasaría
2. **Producción**: Haz backup, ejecuta en horario de baja actividad
3. **Grandes volúmenes**: Ajusta `BATCH_SIZE` según tu hardware
4. **Monitoreo**: Observa el log en tiempo real: `tail -f scripts/migration.log`

---

**¿Listo para migrar?** 🚀

```bash
npm run migrate:to-mysql
```
