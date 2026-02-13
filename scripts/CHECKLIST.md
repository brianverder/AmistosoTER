# ✅ Checklist de Migración SQLite → MySQL

Sigue estos pasos en orden para migrar tus datos de forma segura.

## 📋 PRE-MIGRACIÓN

- [ ] **Backup de SQLite**
  ```bash
  cp prisma/dev.db prisma/dev.db.backup
  ```

- [ ] **MySQL instalado y corriendo**
  ```bash
  mysql --version
  mysql -u root -p -e "SHOW DATABASES;"
  ```

- [ ] **Crear base de datos MySQL**
  ```bash
  mysql -u root -p < database/mysql_schema.sql
  ```

- [ ] **Configurar variables de entorno**
  ```bash
  # Editar .env
  DATABASE_URL="mysql://usuario:password@localhost:3306/amistoso_ter_db"
  ```

- [ ] **Dependencias instaladas**
  ```bash
  npm install
  ```

- [ ] **Verificar requisitos**
  ```bash
  node scripts/run-migration.js --help
  ```

## 🧪 TESTING (OPCIONAL)

- [ ] **Prueba en modo DRY RUN**
  ```bash
  npm run migrate:dry-run
  ```

- [ ] **Revisar el log generado**
  ```bash
  cat scripts/migration.log
  ```

- [ ] **Verificar que no hay errores críticos**
  - Busca líneas con ❌ en el log
  - Corrige problemas de validación si aparecen

## 🚀 MIGRACIÓN

- [ ] **Ejecutar migración**
  ```bash
  npm run migrate:to-mysql
  ```

- [ ] **Esperar a que termine**
  - No interrumpas el proceso (puede tomar varios minutos)
  - Observa la consola para ver el progreso

- [ ] **Revisar el log de migración**
  ```bash
  cat scripts/migration.log | grep "RESUMEN FINAL"
  ```

- [ ] **Verificar que no hubo fallos**
  - ✅ Migrados con éxito: [número]
  - ⏭️  Saltados: [número]
  - ❌ Fallidos: 0 ← **DEBE SER 0**

## 🔍 VERIFICACIÓN

- [ ] **Verificar conteos en MySQL**
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

- [ ] **Comparar con SQLite**
  ```bash
  # Los números deben coincidir con el resumen del log
  ```

- [ ] **Regenerar cliente Prisma para MySQL**
  ```bash
  npx prisma generate
  ```

- [ ] **Probar health check**
  ```bash
  npm run dev
  # En otro terminal:
  curl http://localhost:3000/api/health
  ```

- [ ] **Verificar respuesta del health check**
  ```json
  {
    "status": "ok",
    "database": "connected",
    "environment": "development",
    "timestamp": "..."
  }
  ```

## 🧪 PRUEBAS DE LA APLICACIÓN

- [ ] **Login funciona**
  - Prueba con un usuario existente
  - Verifica que la sesión se crea correctamente

- [ ] **Listar equipos funciona**
  - Navega a /dashboard/teams
  - Verifica que se muestran los equipos

- [ ] **Crear nuevo equipo funciona**
  - Crea un equipo de prueba
  - Verifica que se guarda en MySQL

- [ ] **Ver solicitudes funciona**
  - Navega a /dashboard/requests
  - Verifica que se muestran las solicitudes

- [ ] **Crear solicitud funciona**
  - Crea una solicitud de prueba
  - Verifica que se guarda correctamente

- [ ] **Ver partidos funciona**
  - Navega a /dashboard/matches
  - Verifica que se muestran los partidos

- [ ] **Estadísticas funcionan**
  - Navega a /dashboard/stats
  - Verifica que se calculan correctamente

## 🎉 POST-MIGRACIÓN

- [ ] **Documentar la migración**
  ```bash
  # Guardar el log como evidencia
  cp scripts/migration.log logs/migration-$(date +%Y%m%d).log
  ```

- [ ] **Limpiar archivos temporales** (opcional)
  ```bash
  # Si ya no necesitas SQLite
  # ⚠️ CUIDADO: solo si estás 100% seguro
  # rm prisma/dev.db
  ```

- [ ] **Actualizar documentación del proyecto**
  - Marca que el proyecto ahora usa MySQL
  - Actualiza README con instrucciones de MySQL

- [ ] **Configurar backups automáticos de MySQL**
  ```bash
  # Ejemplo de backup manual
  mysqldump -u root -p amistoso_ter_db > backup-$(date +%Y%m%d).sql
  ```

## 🚨 EN CASO DE PROBLEMAS

Si algo sale mal:

### ❌ Error de conexión a MySQL

```bash
# 1. Verificar que MySQL está corriendo
sudo systemctl status mysql  # Linux
brew services list           # macOS
net start mysql              # Windows

# 2. Verificar credenciales en .env
cat .env | grep DATABASE_URL

# 3. Probar conexión manual
mysql -u root -p
```

### ❌ Registros fallidos en migración

```bash
# 1. Revisar log detallado
cat scripts/migration.log | grep "❌"

# 2. Corregir datos en SQLite si es necesario

# 3. Re-ejecutar migración
# (con SKIP_IF_EXISTS: true, saltará los ya migrados)
npm run migrate:to-mysql
```

### ❌ Datos incorrectos en MySQL

```bash
# 1. Limpiar MySQL
mysql -u root -p amistoso_ter_db -e "
  DELETE FROM match_results;
  DELETE FROM matches;
  DELETE FROM match_requests;
  DELETE FROM teams;
  DELETE FROM users;
"

# 2. Re-ejecutar migración
npm run migrate:to-mysql
```

### ❌ Aplicación no funciona después de migrar

```bash
# 1. Verificar DATABASE_URL en .env
cat .env | grep DATABASE_URL

# 2. Regenerar cliente Prisma
npx prisma generate

# 3. Reiniciar servidor
npm run dev
```

## 📚 Recursos

- [Guía completa de migración](MIGRATION_GUIDE.md)
- [README de scripts](README.md)
- [Documentación de MySQL](../docs/MYSQL_CONNECTION_GUIDE.md)
- [Schema de base de datos](../database/DATABASE_DESIGN.md)

---

**¿Completaste todos los pasos?** 🎉

Felicidades, tu aplicación ahora usa MySQL de forma segura y escalable.
