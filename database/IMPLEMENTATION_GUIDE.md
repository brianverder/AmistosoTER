# 🚀 GUÍA DE IMPLEMENTACIÓN - MIGRACIÓN A MYSQL

## 📋 CHECKLIST COMPLETO

- [ ] 1. Preparar entorno MySQL
- [ ] 2. Ejecutar script de base de datos
- [ ] 3. Actualizar Prisma Schema
- [ ] 4. Configurar variables de entorno
- [ ] 5. Ejecutar migraciones
- [ ] 6. Migrar datos existentes (si aplica)
- [ ] 7. Actualizar código de aplicación
- [ ] 8. Testing completo
- [ ] 9. Deploy a producción
- [ ] 10. Configurar backups

---

## 🔧 PASO 1: PREPARAR ENTORNO MYSQL

### Opción A: Instalación Local (Desarrollo)

#### Windows
```powershell
# Descargar e instalar MySQL 8.0
# https://dev.mysql.com/downloads/installer/

# O usar chocolatey
choco install mysql

# Iniciar servicio
net start MySQL80
```

#### macOS
```bash
# Usar Homebrew
brew install mysql@8.0

# Iniciar servicio
brew services start mysql@8.0
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install mysql-server-8.0

sudo systemctl start mysql
sudo systemctl enable mysql
```

### Opción B: MySQL en Docker (Recomendado para desarrollo)

```bash
# Crear contenedor MySQL
docker run -d \
  --name amistoso-mysql \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=amistoso_ter_db \
  -e MYSQL_USER=amistoso_app \
  -e MYSQL_PASSWORD=app_password \
  -p 3306:3306 \
  mysql:8.0 \
  --character-set-server=utf8mb4 \
  --collation-server=utf8mb4_unicode_ci

# Verificar que está corriendo
docker ps | grep amistoso-mysql

# Ver logs
docker logs amistoso-mysql
```

### Opción C: Hosting en la Nube (Producción)

#### PlanetScale (Recomendado, Free Tier disponible)
1. Crear cuenta en [planetscale.com](https://planetscale.com)
2. Crear database: "amistoso-ter"
3. Copiar connection string

#### Railway
1. Crear cuenta en [railway.app](https://railway.app)
2. New Project → Add MySQL
3. Copiar connection string

#### AWS RDS
```bash
# Crear instancia RDS MySQL
aws rds create-db-instance \
  --db-instance-identifier amistoso-ter-db \
  --db-instance-class db.t3.micro \
  --engine mysql \
  --engine-version 8.0.35 \
  --master-username admin \
  --master-user-password YourPassword123! \
  --allocated-storage 20
```

---

## 📝 PASO 2: EJECUTAR SCRIPT DE BASE DE DATOS

### Conectar a MySQL

```bash
# Local
mysql -u root -p

# Docker
docker exec -it amistoso-mysql mysql -u root -p

# Remoto
mysql -h hostname -u username -p
```

### Ejecutar el Script Completo

```bash
# Desde terminal
mysql -u root -p < database/mysql_schema.sql

# O desde MySQL CLI
mysql> source d:/bverdier/Documents/Amistoso TER Web/database/mysql_schema.sql

# Verificar que se creó correctamente
mysql> USE amistoso_ter_db;
mysql> SHOW TABLES;
mysql> DESCRIBE users;
```

### Verificar Creación

```sql
-- Verificar tablas
SELECT TABLE_NAME, TABLE_ROWS, DATA_LENGTH, INDEX_LENGTH
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'amistoso_ter_db';

-- Verificar índices
SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'amistoso_ter_db'
ORDER BY TABLE_NAME, INDEX_NAME;

-- Verificar foreign keys
SELECT 
  CONSTRAINT_NAME,
  TABLE_NAME,
  COLUMN_NAME,
  REFERENCED_TABLE_NAME,
  REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'amistoso_ter_db'
  AND REFERENCED_TABLE_NAME IS NOT NULL;
```

---

## 🔄 PASO 3: ACTUALIZAR PRISMA SCHEMA

### 3.1. Backup del schema actual
```bash
cp prisma/schema.prisma prisma/schema.prisma.backup
```

### 3.2. Modificar `prisma/schema.prisma`

Reemplazar el datasource:

```prisma
// ANTES (SQLite)
datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

// DESPUÉS (MySQL)
datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
  relationMode = "foreignKeys" // Si usas PlanetScale, usar "prisma"
}
```

### 3.3. Ajustar tipos de datos para MySQL

```prisma
model User {
  id        String   @id @default(uuid()) @db.Char(36)
  email     String   @unique @db.VarChar(255)
  password  String   @db.Char(60)
  name      String   @db.VarChar(150)
  phone     String?  @db.VarChar(20)
  
  // Agregar campos adicionales
  emailVerified Boolean  @default(false) @map("email_verified")
  isActive      Boolean  @default(true) @map("is_active")
  lastLoginAt   DateTime? @map("last_login_at")
  
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  teams         Team[]         
  matchRequests MatchRequest[] 
  matchesAsUser1 Match[]       @relation("User1Matches") 
  matchesAsUser2 Match[]       @relation("User2Matches")
  notifications Notification[]

  @@index([email])
  @@index([isActive])
  @@index([createdAt(sort: Desc)])
  @@map("users")
}

model Team {
  id          String   @id @default(uuid()) @db.Char(36)
  userId      String   @map("user_id") @db.Char(36)
  name        String   @db.VarChar(200)
  description String?  @db.Text
  logoUrl     String?  @map("logo_url") @db.VarChar(500)
  
  // Estadísticas
  gamesWon     Int @default(0) @map("games_won") @db.UnsignedInt
  gamesLost    Int @default(0) @map("games_lost") @db.UnsignedInt
  gamesDrawn   Int @default(0) @map("games_drawn") @db.UnsignedInt
  totalGames   Int @default(0) @map("total_games") @db.UnsignedInt
  goalsFor     Int @default(0) @map("goals_for") @db.UnsignedInt
  goalsAgainst Int @default(0) @map("goals_against") @db.UnsignedInt
  
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  user                  User           @relation(fields: [userId], references: [id], onDelete: Cascade)
  matchRequests         MatchRequest[]
  matchesAsTeam1        Match[]        @relation("Team1Matches")
  matchesAsTeam2        Match[]        @relation("Team2Matches")
  matchResultsAsWinner  MatchResult[]  @relation("WinnerTeam")

  @@index([userId])
  @@index([totalGames(sort: Desc)])
  @@index([name])
  @@index([createdAt(sort: Desc)])
  @@map("teams")
}

model MatchRequest {
  id           String    @id @default(uuid()) @db.Char(36)
  userId       String    @map("user_id") @db.Char(36)
  teamId       String    @map("team_id") @db.Char(36)
  
  footballType String?   @map("football_type") @db.VarChar(10)
  fieldAddress String?   @map("field_address") @db.VarChar(500)
  fieldPrice   Decimal?  @map("field_price") @db.Decimal(10, 2)
  matchDate    DateTime? @map("match_date")
  league       String?   @db.VarChar(100)
  description  String?   @db.Text
  
  status       String    @default("active") @db.VarChar(20)
  expiresAt    DateTime? @map("expires_at")
  
  createdAt    DateTime  @default(now()) @map("created_at")
  updatedAt    DateTime  @updatedAt @map("updated_at")

  user  User   @relation(fields: [userId], references: [id], onDelete: Cascade)
  team  Team   @relation(fields: [teamId], references: [id], onDelete: Cascade)
  match Match?

  @@index([userId])
  @@index([teamId])
  @@index([status])
  @@index([footballType])
  @@index([matchDate])
  @@index([createdAt(sort: Desc)])
  @@index([status, createdAt(sort: Desc)])
  @@map("match_requests")
}

model Match {
  id               String   @id @default(uuid()) @db.Char(36)
  matchRequestId   String   @unique @map("match_request_id") @db.Char(36)
  team1Id          String   @map("team1_id") @db.Char(36)
  team2Id          String   @map("team2_id") @db.Char(36)
  userId1          String   @map("user1_id") @db.Char(36)
  userId2          String   @map("user2_id") @db.Char(36)
  
  status           String   @default("pending") @db.VarChar(20)
  
  finalDate        DateTime? @map("final_date")
  finalAddress     String?   @map("final_address") @db.VarChar(500)
  finalPrice       Decimal?  @map("final_price") @db.Decimal(10, 2)
  finalFootballType String?  @map("final_football_type") @db.VarChar(10)
  notes            String?   @db.Text
  
  createdAt        DateTime  @default(now()) @map("created_at")
  updatedAt        DateTime  @updatedAt @map("updated_at")
  confirmedAt      DateTime? @map("confirmed_at")
  completedAt      DateTime? @map("completed_at")

  matchRequest MatchRequest @relation(fields: [matchRequestId], references: [id], onDelete: Cascade)
  team1        Team         @relation("Team1Matches", fields: [team1Id], references: [id], onDelete: Restrict)
  team2        Team         @relation("Team2Matches", fields: [team2Id], references: [id], onDelete: Restrict)
  user1        User         @relation("User1Matches", fields: [userId1], references: [id], onDelete: Restrict)
  user2        User         @relation("User2Matches", fields: [userId2], references: [id], onDelete: Restrict)
  matchResult  MatchResult?

  @@index([matchRequestId])
  @@index([team1Id])
  @@index([team2Id])
  @@index([userId1])
  @@index([userId2])
  @@index([status])
  @@index([finalDate])
  @@index([createdAt(sort: Desc)])
  @@index([status, finalDate])
  @@map("matches")
}

model MatchResult {
  id        String   @id @default(uuid()) @db.Char(36)
  matchId   String   @unique @map("match_id") @db.Char(36)
  
  team1Score Int     @map("team1_score") @db.UnsignedTinyInt
  team2Score Int     @map("team2_score") @db.UnsignedTinyInt
  winnerId   String? @map("winner_id") @db.Char(36)
  
  penalties       Boolean @default(false)
  team1Penalties  Int?    @map("team1_penalties") @db.UnsignedTinyInt
  team2Penalties  Int?    @map("team2_penalties") @db.UnsignedTinyInt
  
  verified         Boolean @default(false)
  verifiedByUser1  Boolean @default(false) @map("verified_by_user1")
  verifiedByUser2  Boolean @default(false) @map("verified_by_user2")
  
  notes     String?  @db.Text
  
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  match  Match  @relation(fields: [matchId], references: [id], onDelete: Cascade)
  winner Team?  @relation("WinnerTeam", fields: [winnerId], references: [id], onDelete: SetNull)

  @@index([matchId])
  @@index([winnerId])
  @@index([verified])
  @@index([createdAt(sort: Desc)])
  @@map("match_results")
}

model Notification {
  id         BigInt   @id @default(autoincrement()) @db.UnsignedBigInt
  userId     String   @map("user_id") @db.Char(36)
  
  type       String   @db.VarChar(50)
  title      String   @db.VarChar(200)
  message    String   @db.Text
  data       Json?
  
  readStatus Boolean  @default(false) @map("read_status")
  readAt     DateTime? @map("read_at")
  
  createdAt  DateTime @default(now()) @map("created_at")

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
  @@index([readStatus])
  @@index([userId, readStatus, createdAt(sort: Desc)])
  @@index([createdAt(sort: Desc)])
  @@map("notifications")
}
```

---

## 🔐 PASO 4: CONFIGURAR VARIABLES DE ENTORNO

### 4.1. Crear/actualizar `.env`

```env
# ============================================
# DATABASE CONFIGURATION
# ============================================

# Desarrollo Local
DATABASE_URL="mysql://amistoso_app:app_password@localhost:3306/amistoso_ter_db"

# Docker
# DATABASE_URL="mysql://amistoso_app:app_password@localhost:3306/amistoso_ter_db"

# PlanetScale
# DATABASE_URL="mysql://[user]:[password]@[region].connect.psdb.cloud/amistoso-ter?sslaccept=strict"

# Railway
# DATABASE_URL="mysql://root:[password]@containers-us-west-[xxx].railway.app:6789/railway"

# AWS RDS
# DATABASE_URL="mysql://admin:password@amistoso-ter-db.xxxxx.us-east-1.rds.amazonaws.com:3306/amistoso_ter_db"

# ============================================
# NEXTAUTH CONFIGURATION
# ============================================
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="your-secret-key-here-change-in-production"

# ============================================
# OTHER CONFIGURATION
# ============================================
NODE_ENV="development"
```

### 4.2. Agregar a `.env.production`

```env
DATABASE_URL="[TU_CONNECTION_STRING_DE_PRODUCCION]"
NEXTAUTH_URL="https://tudominio.com"
NEXTAUTH_SECRET="[SECRETO_FUERTE_ALEATORIO]"
NODE_ENV="production"
```

### 4.3. Actualizar `.gitignore`

```gitignore
# Environment variables
.env
.env.*
!.env.example

# Prisma
prisma/*.db
prisma/*.db-journal
```

---

## 🚀 PASO 5: EJECUTAR MIGRACIONES DE PRISMA

### 5.1. Resetear y generar migración

```bash
# Instalar dependencias si es necesario
npm install

# Resetear estado de migraciones (CUIDADO: borra datos)
npx prisma migrate reset

# Generar nueva migración basada en el schema
npx prisma migrate dev --name init_mysql

# O si ya existe la BD con estructura, usar:
npx prisma db push

# Generar cliente de Prisma
npx prisma generate
```

### 5.2. Verificar migración

```bash
# Ver estado de migraciones
npx prisma migrate status

# Abrir Prisma Studio para verificar
npx prisma studio
```

---

## 📊 PASO 6: MIGRAR DATOS EXISTENTES (SI APLICA)

Si tienes datos en SQLite que quieres migrar:

### 6.1. Crear script de migración

Crear `scripts/migrate-data.js`:

```javascript
const { PrismaClient } = require('@prisma/client');

// Cliente SQLite (antiguo)
const sqliteClient = new PrismaClient({
  datasources: {
    db: {
      url: 'file:./prisma/dev.db'
    }
  }
});

// Cliente MySQL (nuevo)
const mysqlClient = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
});

async function migrateData() {
  console.log('🚀 Iniciando migración de datos...\n');

  try {
    // 1. Migrar usuarios
    console.log('📊 Migrando usuarios...');
    const users = await sqliteClient.user.findMany();
    for (const user of users) {
      await mysqlClient.user.create({
        data: {
          id: user.id,
          email: user.email,
          password: user.password,
          name: user.name,
          phone: user.phone,
          createdAt: user.createdAt,
          updatedAt: user.updatedAt,
        }
      });
    }
    console.log(`✅ ${users.length} usuarios migrados\n`);

    // 2. Migrar equipos
    console.log('📊 Migrando equipos...');
    const teams = await sqliteClient.team.findMany();
    for (const team of teams) {
      await mysqlClient.team.create({
        data: {
          id: team.id,
          userId: team.userId,
          name: team.name,
          gamesWon: team.gamesWon,
          gamesLost: team.gamesLost,
          gamesDrawn: team.gamesDrawn || 0,
          totalGames: team.totalGames,
          createdAt: team.createdAt,
          updatedAt: team.updatedAt,
        }
      });
    }
    console.log(`✅ ${teams.length} equipos migrados\n`);

    // 3. Migrar solicitudes
    console.log('📊 Migrando solicitudes...');
    const requests = await sqliteClient.matchRequest.findMany();
    for (const request of requests) {
      await mysqlClient.matchRequest.create({
        data: {
          id: request.id,
          userId: request.userId,
          teamId: request.teamId,
          footballType: request.footballType,
          fieldAddress: request.fieldAddress,
          fieldPrice: request.fieldPrice,
          matchDate: request.matchDate,
          league: request.league,
          description: request.description,
          status: request.status,
          createdAt: request.createdAt,
          updatedAt: request.updatedAt,
        }
      });
    }
    console.log(`✅ ${requests.length} solicitudes migradas\n`);

    // 4. Migrar partidos
    console.log('📊 Migrando partidos...');
    const matches = await sqliteClient.match.findMany();
    for (const match of matches) {
      await mysqlClient.match.create({
        data: {
          id: match.id,
          matchRequestId: match.matchRequestId,
          team1Id: match.team1Id,
          team2Id: match.team2Id,
          userId1: match.userId1,
          userId2: match.userId2,
          status: match.status,
          finalDate: match.finalDate,
          finalAddress: match.finalAddress,
          finalPrice: match.finalPrice,
          createdAt: match.createdAt,
          updatedAt: match.updatedAt,
        }
      });
    }
    console.log(`✅ ${matches.length} partidos migrados\n`);

    // 5. Migrar resultados
    console.log('📊 Migrando resultados...');
    const results = await sqliteClient.matchResult.findMany();
    for (const result of results) {
      await mysqlClient.matchResult.create({
        data: {
          id: result.id,
          matchId: result.matchId,
          team1Score: result.team1Score,
          team2Score: result.team2Score,
          winnerId: result.winnerId,
          createdAt: result.createdAt,
          updatedAt: result.updatedAt,
        }
      });
    }
    console.log(`✅ ${results.length} resultados migrados\n`);

    console.log('🎉 ¡Migración completada exitosamente!');

  } catch (error) {
    console.error('❌ Error durante la migración:', error);
    throw error;
  } finally {
    await sqliteClient.$disconnect();
    await mysqlClient.$disconnect();
  }
}

migrateData()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### 6.2. Ejecutar migración

```bash
node scripts/migrate-data.js
```

---

## 🧪 PASO 7: TESTING COMPLETO

### 7.1. Testing manual con Prisma Studio

```bash
npx prisma studio
```

Verificar:
- [ ] Usuarios se muestran correctamente
- [ ] Equipos tienen relaciones con usuarios
- [ ] Solicitudes tienen relaciones
- [ ] Partidos tienen resultados

### 7.2. Testing de endpoints

```bash
# Iniciar servidor
npm run dev

# Probar endpoints
curl http://localhost:3000/api/teams
curl http://localhost:3000/api/requests
curl http://localhost:3000/api/matches
```

### 7.3. Testing de funcionalidad completa

- [ ] Registro de usuario funciona
- [ ] Login funciona
- [ ] Crear equipo funciona
- [ ] Publicar solicitud funciona
- [ ] Aceptar solicitud y crear match funciona
- [ ] Registrar resultado funciona
- [ ] Estadísticas se actualizan correctamente

---

## 🌐 PASO 8: DEPLOY A PRODUCCIÓN

### Opción A: Vercel + PlanetScale

```bash
# 1. Crear database en PlanetScale
pscale db create amistoso-ter --region us-east

# 2. Obtener connection string
pscale connect amistoso-ter main

# 3. Configurar en Vercel
vercel env add DATABASE_URL
# Pegar connection string de PlanetScale

# 4. Deploy
vercel --prod

# 5. Ejecutar migraciones en producción
DATABASE_URL="[production-url]" npx prisma migrate deploy
```

### Opción B: Railway

```bash
# 1. Instalar CLI
npm install -g @railway/cli

# 2. Login
railway login

# 3. Crear proyecto
railway init

# 4. Agregar MySQL
railway add

# 5. Deploy
railway up
```

---

## 💾 PASO 9: CONFIGURAR BACKUPS

### Backup automático diario (cron job)

Crear `scripts/backup.sh`:

```bash
#!/bin/bash

# Configuración
BACKUP_DIR="/backups"
DB_NAME="amistoso_ter_db"
DB_USER="backup_user"
DB_PASS="backup_password"
DB_HOST="localhost"
DATE=$(date +%Y%m%d_%H%M%S)

# Crear backup
echo "🗄️  Creando backup de $DB_NAME..."

mysqldump --host=$DB_HOST \
  --user=$DB_USER \
  --password=$DB_PASS \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  $DB_NAME | gzip > "$BACKUP_DIR/backup_$DATE.sql.gz"

# Eliminar backups antiguos (mayores a 30 días)
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete

echo "✅ Backup completado: backup_$DATE.sql.gz"
```

Configurar crontab:

```bash
# Editar crontab
crontab -e

# Agregar línea para backup diario a las 3 AM
0 3 * * * /path/to/scripts/backup.sh
```

---

## 📊 PASO 10: MONITOREO

### 10.1. Configurar slow query log

```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL slow_query_log_file = '/var/log/mysql/slow-query.log';
SET GLOBAL long_query_time = 2;
```

### 10.2. Monitorear queries en tiempo real

```sql
-- Ver queries activas
SHOW FULL PROCESSLIST;

-- Ver queries lentas
SELECT * FROM mysql.slow_log
ORDER BY start_time DESC
LIMIT 10;

-- Ver uso de índices
SELECT * FROM sys.schema_unused_indexes
WHERE object_schema = 'amistoso_ter_db';
```

### 10.3. Configurar alertas (ejemplo con Node.js)

```javascript
// scripts/monitor.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkDatabaseHealth() {
  try {
    // Test de conexión
    await prisma.$queryRaw`SELECT 1`;
    
    // Verificar tamaño de tablas
    const tableStats = await prisma.$queryRaw`
      SELECT 
        table_name,
        table_rows,
        ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb
      FROM information_schema.tables
      WHERE table_schema = 'amistoso_ter_db'
      ORDER BY (data_length + index_length) DESC
    `;
    
    console.log('✅ Base de datos saludable');
    console.log('Estadísticas de tablas:', tableStats);
    
  } catch (error) {
    console.error('❌ Error en base de datos:', error);
    // Enviar alerta (email, Slack, etc.)
  }
}

// Ejecutar cada 5 minutos
setInterval(checkDatabaseHealth, 5 * 60 * 1000);
```

---

## ⚠️ TROUBLESHOOTING COMÚN

### Error: "Can't connect to MySQL server"

```bash
# Verificar que MySQL está corriendo
sudo systemctl status mysql

# Verificar puerto
netstat -tuln | grep 3306

# Verificar firewall
sudo ufw allow 3306
```

### Error: "Access denied for user"

```sql
-- Crear usuario con privilegios
CREATE USER 'amistoso_app'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON amistoso_ter_db.* TO 'amistoso_app'@'%';
FLUSH PRIVILEGES;
```

### Error: "Too many connections"

```sql
-- Ver conexiones actuales
SHOW PROCESSLIST;

-- Aumentar límite
SET GLOBAL max_connections = 200;

-- Permanente en my.cnf
[mysqld]
max_connections = 200
```

### Error: Prisma migration failed

```bash
# Resetear migraciones (CUIDADO: borra datos)
npx prisma migrate reset

# O forzar migración
npx prisma db push --force-reset
```

---

## ✅ VALIDACIÓN FINAL

Ejecutar estos checks antes de considerar la migración completa:

```bash
# 1. Verificar conexión
npx prisma db pull

# 2. Verificar estructura
npx prisma studio

# 3. Ejecutar tests
npm test

# 4. Verificar rendimiento
# Ejecutar queries del sistema y medir tiempos

# 5. Backup
# Crear backup inmediatamente después de migración exitosa
```

---

## 📞 SOPORTE

Si encuentras problemas:

1. Revisa logs de MySQL: `/var/log/mysql/error.log`
2. Revisa logs de Prisma: `DEBUG="*" npm run dev`
3. Consulta documentación:
   - [Prisma MySQL](https://www.prisma.io/docs/concepts/database-connectors/mysql)
   - [MySQL 8.0 Docs](https://dev.mysql.com/doc/refman/8.0/en/)

---

**¡Migración Completada! 🎉**

Ahora tienes una base de datos MySQL robusta, escalable y lista para producción.
