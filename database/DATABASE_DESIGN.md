# 🗄️ DISEÑO DE BASE DE DATOS MYSQL - AMISTOSO TER

## 📋 ÍNDICE
1. [Diagrama lógico de entidad-relación](#diagrama-lógico)
2. [Descripción de tablas](#descripción-de-tablas)
3. [Estrategia de normalización](#estrategia-de-normalización)
4. [Índices y optimización](#índices-y-optimización)
5. [Escalabilidad y rendimiento](#escalabilidad-y-rendimiento)
6. [Seguridad](#seguridad)
7. [Backup y recuperación](#backup-y-recuperación)
8. [Migración de Prisma a MySQL](#migración-de-prisma-a-mysql)

---

## 🎯 DIAGRAMA LÓGICO

### Diagrama Entidad-Relación (Mermaid)

```mermaid
erDiagram
    users ||--o{ teams : "posee"
    users ||--o{ match_requests : "crea"
    users ||--o{ matches : "participa_como_user1"
    users ||--o{ matches : "participa_como_user2"
    users ||--o{ notifications : "recibe"
    
    teams ||--o{ match_requests : "solicita"
    teams ||--o{ matches : "juega_como_team1"
    teams ||--o{ matches : "juega_como_team2"
    teams ||--o{ match_results : "gana"
    
    match_requests ||--|| matches : "genera"
    
    matches ||--|| match_results : "tiene"
    
    users {
        CHAR(36) id PK
        VARCHAR(255) email UK
        CHAR(60) password_hash
        VARCHAR(150) name
        VARCHAR(20) phone
        BOOLEAN email_verified
        BOOLEAN is_active
        TIMESTAMP created_at
        TIMESTAMP updated_at
        TIMESTAMP last_login_at
    }
    
    teams {
        CHAR(36) id PK
        CHAR(36) user_id FK
        VARCHAR(200) name
        TEXT description
        VARCHAR(500) logo_url
        INT games_won
        INT games_lost
        INT games_drawn
        INT total_games
        INT goals_for
        INT goals_against
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }
    
    match_requests {
        CHAR(36) id PK
        CHAR(36) user_id FK
        CHAR(36) team_id FK
        ENUM football_type
        VARCHAR(500) field_address
        DECIMAL(10,2) field_price
        DATETIME match_date
        VARCHAR(100) league
        TEXT description
        ENUM status
        TIMESTAMP created_at
        TIMESTAMP updated_at
        TIMESTAMP expires_at
    }
    
    matches {
        CHAR(36) id PK
        CHAR(36) match_request_id FK UK
        CHAR(36) team1_id FK
        CHAR(36) team2_id FK
        CHAR(36) user1_id FK
        CHAR(36) user2_id FK
        ENUM status
        DATETIME final_date
        VARCHAR(500) final_address
        DECIMAL(10,2) final_price
        ENUM final_football_type
        TEXT notes
        TIMESTAMP created_at
        TIMESTAMP updated_at
        TIMESTAMP confirmed_at
        TIMESTAMP completed_at
    }
    
    match_results {
        CHAR(36) id PK
        CHAR(36) match_id FK UK
        TINYINT team1_score
        TINYINT team2_score
        CHAR(36) winner_id FK
        ENUM result_type
        BOOLEAN penalties
        TINYINT team1_penalties
        TINYINT team2_penalties
        BOOLEAN verified
        BOOLEAN verified_by_user1
        BOOLEAN verified_by_user2
        TEXT notes
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }
    
    notifications {
        BIGINT id PK
        CHAR(36) user_id FK
        ENUM type
        VARCHAR(200) title
        TEXT message
        JSON data
        BOOLEAN read_status
        TIMESTAMP read_at
        TIMESTAMP created_at
    }
```

---

## 📊 DESCRIPCIÓN DE TABLAS

### 1️⃣ Tabla: `users`
**Propósito:** Almacenar información de usuarios registrados.

| Campo | Tipo | Descripción | Constraints |
|-------|------|-------------|-------------|
| `id` | CHAR(36) | Identificador único (UUID) | PRIMARY KEY |
| `email` | VARCHAR(255) | Email para login | UNIQUE, NOT NULL |
| `password_hash` | CHAR(60) | Hash bcrypt de contraseña | NOT NULL |
| `name` | VARCHAR(150) | Nombre completo | NOT NULL |
| `phone` | VARCHAR(20) | Teléfono de contacto | NULL |
| `email_verified` | BOOLEAN | Estado de verificación | DEFAULT FALSE |
| `is_active` | BOOLEAN | Cuenta activa | DEFAULT TRUE |
| `created_at` | TIMESTAMP | Fecha de registro | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | Última modificación | ON UPDATE CURRENT_TIMESTAMP |
| `last_login_at` | TIMESTAMP | Último inicio de sesión | NULL |

**Índices:**
- `idx_email`: Para login rápido
- `idx_active`: Filtrar usuarios activos
- `idx_created`: Ordenar por fecha de registro

---

### 2️⃣ Tabla: `teams`
**Propósito:** Equipos de fútbol creados por usuarios.

| Campo | Tipo | Descripción | Constraints |
|-------|------|-------------|-------------|
| `id` | CHAR(36) | Identificador único | PRIMARY KEY |
| `user_id` | CHAR(36) | Usuario propietario | FK → users(id), NOT NULL |
| `name` | VARCHAR(200) | Nombre del equipo | NOT NULL |
| `description` | TEXT | Descripción | NULL |
| `logo_url` | VARCHAR(500) | URL del logo | NULL |
| `games_won` | INT UNSIGNED | Partidos ganados | DEFAULT 0 |
| `games_lost` | INT UNSIGNED | Partidos perdidos | DEFAULT 0 |
| `games_drawn` | INT UNSIGNED | Partidos empatados | DEFAULT 0 |
| `total_games` | INT UNSIGNED | Total partidos | DEFAULT 0 |
| `goals_for` | INT UNSIGNED | Goles a favor | DEFAULT 0 |
| `goals_against` | INT UNSIGNED | Goles en contra | DEFAULT 0 |

**Desnormalización:**
- Las estadísticas se guardan redundantemente para mejor rendimiento en consultas.
- Se usa un CONSTRAINT para verificar integridad: `total_games = games_won + games_lost + games_drawn`

**Índices:**
- `idx_user_id`: Filtrar equipos por usuario
- `idx_total_games`: Ranking de equipos
- `idx_name`: Búsqueda por nombre

---

### 3️⃣ Tabla: `match_requests`
**Propósito:** Solicitudes de partidos publicadas por usuarios.

| Campo | Tipo | Descripción | Constraints |
|-------|------|-------------|-------------|
| `id` | CHAR(36) | Identificador único | PRIMARY KEY |
| `user_id` | CHAR(36) | Usuario solicitante | FK → users(id) |
| `team_id` | CHAR(36) | Equipo solicitante | FK → teams(id) |
| `football_type` | ENUM | Tipo: 5, 7, 8, 11, otro | NULL |
| `field_address` | VARCHAR(500) | Dirección de cancha | NULL |
| `field_price` | DECIMAL(10,2) | Precio en € | NULL |
| `match_date` | DATETIME | Fecha propuesta | NULL |
| `league` | VARCHAR(100) | Liga del equipo | NULL |
| `description` | TEXT | Descripción adicional | NULL |
| `status` | ENUM | active, matched, cancelled, expired | DEFAULT 'active' |
| `expires_at` | TIMESTAMP | Fecha de expiración | NULL |

**Índices compuestos:**
- `idx_status_created`: Para listar solicitudes activas ordenadas por fecha
- `ft_description`: FULLTEXT para búsqueda de texto

---

### 4️⃣ Tabla: `matches`
**Propósito:** Partidos confirmados entre dos equipos.

| Campo | Tipo | Descripción | Constraints |
|-------|------|-------------|-------------|
| `id` | CHAR(36) | Identificador único | PRIMARY KEY |
| `match_request_id` | CHAR(36) | Solicitud origen | FK → match_requests(id), UNIQUE |
| `team1_id` | CHAR(36) | Equipo 1 | FK → teams(id) |
| `team2_id` | CHAR(36) | Equipo 2 | FK → teams(id) |
| `user1_id` | CHAR(36) | Usuario 1 | FK → users(id) |
| `user2_id` | CHAR(36) | Usuario 2 | FK → users(id) |
| `status` | ENUM | pending, confirmed, completed, cancelled | DEFAULT 'pending' |
| `final_date` | DATETIME | Fecha definitiva | NULL |
| `final_address` | VARCHAR(500) | Dirección definitiva | NULL |
| `final_price` | DECIMAL(10,2) | Precio definitivo | NULL |

**Constraints de integridad:**
- `CHK team1_id != team2_id`: Los equipos deben ser diferentes
- `CHK user1_id != user2_id`: Los usuarios deben ser diferentes

**Índice compuesto útil:**
- `idx_status_date`: Para listar partidos por estado y fecha

---

### 5️⃣ Tabla: `match_results`
**Propósito:** Resultados de partidos finalizados.

| Campo | Tipo | Descripción | Constraints |
|-------|------|-------------|-------------|
| `id` | CHAR(36) | Identificador único | PRIMARY KEY |
| `match_id` | CHAR(36) | Partido | FK → matches(id), UNIQUE |
| `team1_score` | TINYINT UNSIGNED | Goles equipo 1 | NOT NULL |
| `team2_score` | TINYINT UNSIGNED | Goles equipo 2 | NOT NULL |
| `winner_id` | CHAR(36) | Equipo ganador | FK → teams(id), NULL si empate |
| `result_type` | ENUM GENERATED | win_team1, win_team2, draw | STORED (calculado) |
| `penalties` | BOOLEAN | Definido por penales | DEFAULT FALSE |
| `verified` | BOOLEAN | Confirmado por ambos | DEFAULT FALSE |

**Columna generada:**
- `result_type`: Se calcula automáticamente basándose en los scores para queries rápidas.

---

### 6️⃣ Tabla: `notifications` (Opcional)
**Propósito:** Sistema de notificaciones.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | BIGINT | ID autoincremental |
| `user_id` | CHAR(36) | Destinatario |
| `type` | ENUM | Tipo de notificación |
| `title` | VARCHAR(200) | Título |
| `message` | TEXT | Mensaje |
| `data` | JSON | Datos adicionales |
| `read_status` | BOOLEAN | Leída o no |

**Índice compuesto crucial:**
- `idx_user_unread (user_id, read_status, created_at DESC)`: Para mostrar notificaciones no leídas eficientemente.

---

### 7️⃣ Tabla: `audit_log` (Opcional)
**Propósito:** Registro de auditoría para seguridad y compliance.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | BIGINT | ID autoincremental |
| `user_id` | CHAR(36) | Usuario que actuó |
| `action` | VARCHAR(100) | Acción realizada |
| `entity_type` | VARCHAR(50) | Tipo de entidad |
| `entity_id` | CHAR(36) | ID de entidad |
| `ip_address` | VARCHAR(45) | IP del usuario |
| `details` | JSON | Detalles adicionales |

---

## 🔄 ESTRATEGIA DE NORMALIZACIÓN

### Nivel de Normalización: **3FN (Tercera Forma Normal)**

#### ✅ Primera Forma Normal (1FN)
- Todos los campos contienen valores atómicos
- No hay grupos repetidos
- Cada columna tiene un único tipo de dato

#### ✅ Segunda Forma Normal (2FN)
- Cumple 1FN
- Todos los atributos no clave dependen completamente de la clave primaria
- No hay dependencias parciales

#### ✅ Tercera Forma Normal (3FN)
- Cumple 2FN
- No hay dependencias transitivas
- Todos los atributos no clave dependen directamente de la PK

### 📌 Desnormalizaciones Estratégicas

**1. Estadísticas en `teams`:**
```sql
games_won, games_lost, games_drawn, total_games, goals_for, goals_against
```
**Razón:** Evitar JOINs costosos para calcular estadísticas en tiempo real.
**Mantenimiento:** Triggers automáticos al insertar/actualizar resultados.

**2. Columna generada `result_type` en `match_results`:**
```sql
result_type ENUM(...) AS (...) STORED
```
**Razón:** Acelerar queries de filtrado por tipo de resultado.

**3. Información redundante en `matches`:**
```sql
user1_id, user2_id (además de team1_id, team2_id)
```
**Razón:** Evitar JOIN adicional con teams para obtener usuarios.

---

## 🚀 ÍNDICES Y OPTIMIZACIÓN

### 📊 Estrategia de Indexación

#### 1. **Índices de Clave Primaria (Automáticos)**
Todas las tablas tienen PK con UUID (CHAR(36)).

#### 2. **Índices de Clave Foránea (Obligatorios)**
```sql
-- En teams
INDEX idx_user_id (user_id)

-- En match_requests
INDEX idx_user_id (user_id)
INDEX idx_team_id (team_id)

-- En matches
INDEX idx_team1 (team1_id)
INDEX idx_team2 (team2_id)
INDEX idx_user1 (user1_id)
INDEX idx_user2 (user2_id)
```

#### 3. **Índices de Búsqueda Simple**
```sql
-- Para login
CREATE INDEX idx_email ON users(email);

-- Para filtrar por estado
CREATE INDEX idx_status ON match_requests(status);
CREATE INDEX idx_status ON matches(status);
```

#### 4. **Índices Compuestos (Multi-Columna)**
**Regla:** Columnas de filtro primero, luego columnas de ordenamiento.

```sql
-- Solicitudes activas ordenadas por fecha
CREATE INDEX idx_status_created 
ON match_requests(status, created_at DESC);

-- Partidos filtrados por usuario y fecha
CREATE INDEX idx_user_date 
ON matches(user1_id, final_date DESC);

-- Notificaciones no leídas por usuario
CREATE INDEX idx_user_unread 
ON notifications(user_id, read_status, created_at DESC);
```

#### 5. **Índices Full-Text para Búsqueda**
```sql
-- Búsqueda de texto en solicitudes
CREATE FULLTEXT INDEX ft_description 
ON match_requests(description, field_address);

-- Uso:
SELECT * FROM match_requests
WHERE MATCH(description, field_address) AGAINST('madrid cancha' IN NATURAL LANGUAGE MODE);
```

#### 6. **Índices para Ordenamiento**
```sql
-- Rankings y estadísticas
CREATE INDEX idx_total_games ON teams(total_games DESC);
CREATE INDEX idx_created ON users(created_at DESC);
```

---

## 📈 ESCALABILIDAD Y RENDIMIENTO

### 1. **Particionamiento (Para tablas grandes)**

#### Particionar `notifications` por fecha
```sql
ALTER TABLE notifications
PARTITION BY RANGE (YEAR(created_at)) (
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION p2026 VALUES LESS THAN (2027),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);
```

#### Particionar `audit_log` por mes
```sql
ALTER TABLE audit_log
PARTITION BY RANGE (TO_DAYS(created_at)) (
    PARTITION p202401 VALUES LESS THAN (TO_DAYS('2024-02-01')),
    PARTITION p202402 VALUES LESS THAN (TO_DAYS('2024-03-01')),
    -- etc...
);
```

**Beneficio:** Queries más rápidas, mantenimiento más eficiente, archivado sencillo.

---

### 2. **Caché de Consultas**

#### En la aplicación (Redis/Memcached)
```javascript
// Cachear rankings por 5 minutos
const rankings = await cache.remember('team:rankings:top20', 300, async () => {
  return await db.query('CALL sp_get_team_rankings(20)');
});
```

#### Queries frecuentes a cachear:
- Rankings de equipos
- Estadísticas globales
- Solicitudes activas (con invalidación al crear/actualizar)
- Listado de notificaciones

---

### 3. **Connection Pooling**

```javascript
// Prisma con connection pool
datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
  
  // Configuración de pool
  connection_limit = 20
  pool_timeout = 20
}
```

**Configuración recomendada para producción:**
- `max_connections`: 200-500 (según RAM disponible)
- `connection_limit`: 20-50 por instancia de aplicación
- `pool_timeout`: 10-20 segundos

---

### 4. **Triggers para Mantenimiento Automático**

```sql
-- Actualizar estadísticas automáticamente
CREATE TRIGGER trg_update_team_stats_after_result
AFTER INSERT ON match_results
FOR EACH ROW
BEGIN
    -- Actualiza games_won, games_lost, total_games, etc.
END;
```

**Beneficio:** Mantiene desnormalización sincronizada sin intervención manual.

---

### 5. **Vistas Materializadas (Simuladas)**

MySQL no tiene vistas materializadas nativas, pero se pueden simular:

```sql
-- Tabla de caché para estadísticas
CREATE TABLE cache_team_stats (
    team_id CHAR(36) PRIMARY KEY,
    total_points INT,
    ranking INT,
    last_updated TIMESTAMP,
    INDEX idx_ranking (ranking)
);

-- Procedimiento para actualizar
CREATE PROCEDURE sp_refresh_team_stats_cache()
BEGIN
    TRUNCATE cache_team_stats;
    
    INSERT INTO cache_team_stats
    SELECT 
        id,
        (games_won * 3 + games_drawn) AS total_points,
        @rank := @rank + 1 AS ranking,
        NOW()
    FROM teams, (SELECT @rank := 0) r
    ORDER BY total_points DESC, goals_for DESC;
END;
```

**Actualización:** Cada hora vía cron job.

---

## 🔒 SEGURIDAD

### 1. **Hashing de Contraseñas**
```javascript
// Usar bcrypt con cost factor 10-12
const hash = await bcrypt.hash(password, 10);
```

### 2. **SQL Injection Prevention**
✅ **Usar siempre queries parametrizadas** (Prisma lo hace automáticamente)
❌ **Nunca concatenar strings en SQL**

```javascript
// ✅ Correcto (Prisma)
await prisma.user.findUnique({ where: { email: userEmail } });

// ❌ Incorrecto (SQL directo)
await db.query(`SELECT * FROM users WHERE email = '${userEmail}'`);
```

### 3. **Privilegios de Usuario**

#### Usuario de aplicación (limitado)
```sql
CREATE USER 'amistoso_app'@'%' IDENTIFIED BY 'secure_password';

GRANT SELECT, INSERT, UPDATE, DELETE 
ON amistoso_ter_db.* 
TO 'amistoso_app'@'%';

-- NO dar privilegios de DROP, ALTER, CREATE
```

#### Usuario de administración (full)
```sql
CREATE USER 'amistoso_admin'@'%' IDENTIFIED BY 'admin_password';
GRANT ALL PRIVILEGES ON amistoso_ter_db.* TO 'amistoso_admin'@'%';
```

### 4. **Cifrado de Conexión (SSL/TLS)**
```javascript
// En .env
DATABASE_URL="mysql://user:pass@host:3306/db?ssl=true&sslaccept=strict"
```

### 5. **Rate Limiting en Aplicación**
```javascript
// Limitar requests de login
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 5 // 5 intentos
});
```

### 6. **Audit Log para Compliance**
Registrar acciones críticas:
- Logins y logouts
- Creación/modificación de equipos
- Modificación de resultados
- Cambios de contraseña

---

## 💾 BACKUP Y RECUPERACIÓN

### 1. **Estrategia de Backup**

#### Backup completo diario
```bash
#!/bin/bash
mysqldump --user=admin --password=password \
  --single-transaction \
  --routines --triggers \
  amistoso_ter_db > backup_$(date +%Y%m%d).sql
```

#### Backup incremental cada hora (Binary Logs)
```sql
-- Habilitar binary logging
SET GLOBAL binlog_format = 'ROW';
SET GLOBAL expire_logs_days = 7;
```

### 2. **Testing de Restore**
```bash
# Restaurar en base de prueba
mysql -u admin -p amistoso_ter_test < backup_20260213.sql

# Verificar integridad
mysql -u admin -p amistoso_ter_test -e "CHECK TABLE users, teams, matches;"
```

### 3. **Replicación Master-Slave**
Para alta disponibilidad:
- **Master:** Escrituras y lecturas
- **Slave 1:** Solo lecturas (queries pesadas)
- **Slave 2:** Backup en tiempo real

---

## 🔄 MIGRACIÓN DE PRISMA A MYSQL

### Paso 1: Actualizar `schema.prisma`

```prisma
datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
  relationMode = "prisma" // Para PlanetScale o similar sin FKs
}
```

### Paso 2: Ajustar tipos de datos

**Cambios necesarios:**

```prisma
model User {
  id String @id @default(uuid()) @db.Char(36)
  email String @unique @db.VarChar(255)
  password String @db.Char(60)
  phone String? @db.VarChar(20)
  // ...
}

model Team {
  id String @id @default(uuid()) @db.Char(36)
  gamesWon Int @default(0) @db.UnsignedInt
  gamesLost Int @default(0) @db.UnsignedInt
  // ...
}

model MatchRequest {
  fieldPrice Decimal? @db.Decimal(10, 2)
  footballType String? @db.VarChar(10)
  // ...
}
```

### Paso 3: Variable de entorno

```env
# Development
DATABASE_URL="mysql://root:password@localhost:3306/amistoso_ter_db"

# Production (ejemplo PlanetScale)
DATABASE_URL="mysql://usuario:password@aws.connect.psdb.cloud/amistoso-ter?ssl={"rejectUnauthorized":true}"
```

### Paso 4: Ejecutar migración

```bash
# Generar migración SQL
npx prisma migrate dev --name init_mysql

# En producción
npx prisma migrate deploy

# Generar cliente actualizado
npx prisma generate
```

### Paso 5: Migrar datos de SQLite a MySQL

#### Script de migración:
```javascript
// migrate-data.js
const { PrismaClient: SQLiteClient } = require('@prisma/client');
const { PrismaClient: MySQLClient } = require('@prisma/client');

const sqlite = new SQLiteClient({
  datasources: { db: { url: 'file:./dev.db' } }
});

const mysql = new MySQLClient({
  datasources: { db: { url: process.env.DATABASE_URL } }
});

async function migrate() {
  // Migrar usuarios
  const users = await sqlite.user.findMany();
  for (const user of users) {
    await mysql.user.create({ data: user });
  }
  
  // Migrar equipos
  const teams = await sqlite.team.findMany();
  for (const team of teams) {
    await mysql.team.create({ data: team });
  }
  
  // ... etc
}

migrate();
```

---

## 🏆 RECOMENDACIONES FINALES

### ✅ DO's (Hacer)

1. **Usar transacciones** para operaciones críticas
```javascript
await prisma.$transaction([
  prisma.match.update(...),
  prisma.matchRequest.update(...),
]);
```

2. **Monitorear slow queries**
```sql
SET GLOBAL slow_query_log = 1;
SET GLOBAL long_query_time = 2;
```

3. **Implementar paginación** en todas las listas
```javascript
const teams = await prisma.team.findMany({
  skip: (page - 1) * 20,
  take: 20,
});
```

4. **Usar EXPLAIN** para optimizar queries
```sql
EXPLAIN SELECT * FROM matches WHERE status = 'pending';
```

5. **Revisar índices periódicamente**
```sql
SELECT * FROM sys.schema_unused_indexes;
```

### ❌ DON'Ts (Evitar)

1. ❌ **No usar SELECT *** en producción
2. ❌ **No hacer queries en bucles** (usar batch queries)
3. ❌ **No exponer errores SQL** al cliente
4. ❌ **No guardar contraseñas en texto plano**
5. ❌ **No ignorar límites de conexión**

---

## 📊 MÉTRICAS DE RENDIMIENTO ESPERADAS

Con la base optimizada:

| Operación | Tiempo esperado | Registros |
|-----------|-----------------|-----------|
| Login | < 50ms | N/A |
| Listar solicitudes activas | < 100ms | < 1000 |
| Buscar solicitudes (FULLTEXT) | < 200ms | < 10000 |
| Crear partido | < 80ms | N/A |
| Actualizar estadísticas | < 30ms | triggers |
| Ranking de equipos | < 150ms | < 5000 |

---

## 🔗 RECURSOS ÚTILES

- [MySQL 8.0 Documentation](https://dev.mysql.com/doc/refman/8.0/en/)
- [Prisma MySQL Guide](https://www.prisma.io/docs/concepts/database-connectors/mysql)
- [Database Normalization](https://en.wikipedia.org/wiki/Database_normalization)
- [MySQL Performance Tuning](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)

---

## 📞 PRÓXIMOS PASOS

1. ✅ Revisar y ejecutar `mysql_schema.sql`
2. ✅ Actualizar `schema.prisma` con tipos MySQL
3. ✅ Configurar variable `DATABASE_URL`
4. ✅ Ejecutar `npx prisma migrate dev`
5. ✅ Migrar datos existentes (si aplica)
6. ✅ Actualizar queries complejas en la aplicación
7. ✅ Testing exhaustivo
8. ✅ Configurar backups automáticos
9. ✅ Monitoreo y optimización continua

---

**Documento creado por:** GitHub Copilot  
**Fecha:** 13 de Febrero de 2026  
**Versión:** 1.0
