# 📦 Scripts de Migración

Este directorio contiene todos los scripts necesarios para migrar datos de SQLite a MySQL.

## 🚀 Inicio Rápido

```bash
# 1. Ejecutar schema MySQL
mysql -u root -p < database/mysql_schema.sql

# 2. Configurar .env
DATABASE_URL="mysql://usuario:password@localhost:3306/amistoso_ter_db"

# 3. Ejecutar migración
npm run migrate:to-mysql
```

## 📁 Archivos

| Archivo | Descripción |
|---------|-------------|
| `migrate-to-mysql.js` | **Script principal** - Ejecuta la migración completa |
| `migration-utils.js` | Validaciones y sanitización de datos |
| `migration-logger.js` | Sistema de logging con colores |
| `run-migration.js` | Wrapper ejecutable con verificaciones |
| `MIGRATION_GUIDE.md` | **Guía completa** de uso y troubleshooting |
| `migration.log` | Log de ejecución (generado automáticamente) |

## 📖 Comandos Disponibles

```bash
# Migración completa
npm run migrate:to-mysql

# Modo prueba (no inserta datos)
npm run migrate:dry-run

# Con Node directamente
node scripts/migrate-to-mysql.js

# Ejecutable con verificaciones
node scripts/run-migration.js

# Ver ayuda
node scripts/run-migration.js --help
```

## ⚙️ Configuración

Edita [`migrate-to-mysql.js`](migrate-to-mysql.js) para ajustar:

```javascript
const CONFIG = {
  BATCH_SIZE: 100,           // Registros por lote
  DRY_RUN: false,           // true = solo simula
  VERIFY_INTEGRITY: true,   // Verificar al final
  SKIP_IF_EXISTS: true,     // Saltar duplicados
  LOG_FILE: 'migration.log' // Nombre del log
};
```

## 🔍 Características

- ✅ **Idempotente**: Puedes ejecutar varias veces sin duplicar
- ✅ **Validación**: Revisa formato y relaciones antes de insertar
- ✅ **Logging detallado**: Consola + archivo con timestamps
- ✅ **Manejo de errores**: Continúa incluso si algunos registros fallan
- ✅ **Verificación de integridad**: Compara conteos al final
- ✅ **Migración en lotes**: Optimizado para grandes volúmenes
- ✅ **Sanitización**: Elimina caracteres peligrosos

## 📊 Proceso de Migración

```
1. Usuarios      → Validar email, password
2. Equipos       → Validar relación con usuario
3. Solicitudes   → Validar equipos y fechas
4. Partidos      → Validar todas las relaciones
5. Resultados    → Validar partido y marcadores
6. Verificación  → Comparar SQLite vs MySQL
```

## 🛠️ Troubleshooting

### Error de conexión
```bash
# Verificar MySQL
mysql -u root -p -e "SHOW DATABASES;"

# Verificar .env
cat .env | grep DATABASE_URL
```

### Datos no migrados
1. Revisa `migration.log` para ver errores específicos
2. Verifica que las relaciones sean válidas (FK existen)
3. Ejecuta en modo `DRY_RUN` para diagnosticar

### Duplicados
Por defecto, el script **salta** registros existentes. Para forzar re-inserción:
```javascript
SKIP_IF_EXISTS: false  // Cuidado: puede causar errores
```

## 📚 Más Información

Lee la guía completa: [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)

## ⚠️ Importante

- **SIEMPRE haz backup** antes de migrar
- Prueba primero en `DRY_RUN` mode
- Revisa el log después de cada ejecución
- El script NO elimina datos de SQLite

---

**¿Listo?** → `npm run migrate:to-mysql`
