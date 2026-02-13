# 📊 DIAGRAMA VISUAL DE BASE DE DATOS

## DIAGRAMA DE RELACIONES (ASCII)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AMISTOSO TER - DATABASE SCHEMA                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────┐
│        users           │
├────────────────────────┤
│ PK  id (CHAR 36)       │──┐
│ UK  email              │  │
│     password_hash      │  │ 1:N
│     name               │  │
│     phone              │  │
│     email_verified     │  │
│     is_active          │  │
│     created_at         │  │
│     updated_at         │  │
│     last_login_at      │  │
└────────────────────────┘  │
         │                  │
         │ 1:N              │
         │                  │
         ▼                  ▼
┌────────────────────────┐  ┌────────────────────────┐
│        teams           │  │   match_requests       │
├────────────────────────┤  ├────────────────────────┤
│ PK  id (CHAR 36)       │──┤ PK  id (CHAR 36)       │
│ FK  user_id            │◄─┤ FK  user_id            │
│     name               │  │ FK  team_id            │──┐
│     description        │  │     football_type      │  │
│     logo_url           │  │     field_address      │  │
│     games_won          │  │     field_price        │  │
│     games_lost         │  │     match_date         │  │
│     games_drawn        │  │     league             │  │
│     total_games        │  │     description        │  │
│     goals_for          │  │     status             │  │
│     goals_against      │  │     expires_at         │  │
│     created_at         │  │     created_at         │  │
│     updated_at         │  │     updated_at         │  │
└────────────────────────┘  └────────────────────────┘  │
         │                           │                    │
         │ 1:N                       │ 1:1                │
         │                           │                    │
         │                           ▼                    │
         │                  ┌────────────────────────┐   │
         │                  │       matches          │   │
         │                  ├────────────────────────┤   │
         │                  │ PK  id (CHAR 36)       │   │
         │             ┌───►│ FK  match_request_id   │◄──┘
         │             │    │ FK  team1_id           │
         │             │    │ FK  team2_id           │
         │             │    │ FK  user1_id           │
         │             │    │ FK  user2_id           │
         ├─────────────┤    │     status             │
         │             │    │     final_date         │
         │             │    │     final_address      │
         └─────────────┤    │     final_price        │
                       │    │     final_football_type│
                       │    │     notes              │
                       │    │     created_at         │
                       │    │     updated_at         │
                       │    │     confirmed_at       │
                       │    │     completed_at       │
                       │    └────────────────────────┘
                       │              │
                       │              │ 1:1
                       │              │
                       │              ▼
                       │    ┌────────────────────────┐
                       │    │   match_results        │
                       │    ├────────────────────────┤
                       │    │ PK  id (CHAR 36)       │
                       │    │ FK  match_id           │
                       └───►│ FK  winner_id          │
                            │     team1_score        │
                            │     team2_score        │
                            │     result_type (GEN)  │
                            │     penalties          │
                            │     team1_penalties    │
                            │     team2_penalties    │
                            │     verified           │
                            │     verified_by_user1  │
                            │     verified_by_user2  │
                            │     notes              │
                            │     created_at         │
                            │     updated_at         │
                            └────────────────────────┘

┌────────────────────────┐
│    notifications       │
├────────────────────────┤
│ PK  id (BIGINT)        │
│ FK  user_id            │◄──── (De users)
│     type               │
│     title              │
│     message            │
│     data (JSON)        │
│     read_status        │
│     read_at            │
│     created_at         │
└────────────────────────┘

LEYENDA:
─────────────────────────────────
PK  = Primary Key (Clave Primaria)
FK  = Foreign Key (Clave Foránea)
UK  = Unique Key (Clave Única)
GEN = Generated Column (Columna Generada)
1:N = Relación Uno a Muchos
1:1 = Relación Uno a Uno
──► = Dirección de la relación
```

---

## FLUJO DE DATOS PRINCIPAL

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         FLUJO DE CREACIÓN DE PARTIDO                          │
└──────────────────────────────────────────────────────────────────────────────┘

1. REGISTRO DE USUARIO
   ┌─────────┐
   │ Usuario │ ──REGISTER──► [POST /api/auth/register]
   └─────────┘                        │
                                      ▼
                              ┌───────────────┐
                              │ INSERT users  │
                              └───────────────┘
                                      │
                                      ▼
                              ┌───────────────┐
                              │ Crear Sesión  │
                              └───────────────┘

2. CREACIÓN DE EQUIPO
   ┌─────────┐
   │ Usuario │ ──CREATE_TEAM──► [POST /api/teams]
   └─────────┘                        │
                                      ▼
                              ┌───────────────┐
                              │ INSERT teams  │
                              │ (user_id = X) │
                              └───────────────┘

3. PUBLICAR SOLICITUD DE PARTIDO
   ┌─────────┐
   │ Usuario │ ──CREATE_REQUEST──► [POST /api/requests]
   └─────────┘                            │
                                          ▼
                                  ┌────────────────────┐
                                  │ INSERT             │
                                  │ match_requests     │
                                  │ status = 'active'  │
                                  └────────────────────┘
                                          │
                                          ▼
                                  [Solicitud visible en
                                   vista pública]

4. OTRO USUARIO ACEPTA LA SOLICITUD
   ┌──────────┐
   │ Usuario2 │ ──ACCEPT_REQUEST──► [POST /api/requests/:id/match]
   └──────────┘                              │
                                             ▼
                              ┌──────────────────────────┐
                              │ BEGIN TRANSACTION        │
                              │ 1. INSERT matches        │
                              │ 2. UPDATE match_requests │
                              │    SET status='matched'  │
                              │ COMMIT                   │
                              └──────────────────────────┘
                                             │
                                             ▼
                                     [Both users notified]

5. JUGAR EL PARTIDO (Offline)
   ⚽ Partido se juega en la vida real

6. REGISTRAR RESULTADO
   ┌─────────┐
   │ Usuario │ ──SUBMIT_RESULT──► [POST /api/matches/:id/result]
   └─────────┘                              │
                                            ▼
                              ┌─────────────────────────────┐
                              │ BEGIN TRANSACTION           │
                              │ 1. INSERT match_results     │
                              │ 2. UPDATE matches           │
                              │    SET status='completed'   │
                              │ 3. TRIGGER: Update          │
                              │    team stats (via trigger) │
                              │ COMMIT                      │
                              └─────────────────────────────┘
                                            │
                                            ▼
                              ┌─────────────────────────────┐
                              │ Estadísticas actualizadas:  │
                              │ - teams.games_won           │
                              │ - teams.total_games         │
                              │ - teams.goals_for           │
                              │ - etc.                      │
                              └─────────────────────────────┘
```

---

## ÍNDICES APLICADOS POR TABLA

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          ESTRATEGIA DE INDEXACIÓN                        │
└─────────────────────────────────────────────────────────────────────────┘

TABLE: users
  ✓ PRIMARY KEY (id)
  ✓ UNIQUE INDEX (email)                    ← Para login rápido
  ✓ INDEX (is_active)                       ← Filtrar usuarios activos
  ✓ INDEX (created_at DESC)                 ← Ordenar por registro

TABLE: teams
  ✓ PRIMARY KEY (id)
  ✓ INDEX (user_id)                         ← FK, listar equipos por usuario
  ✓ INDEX (total_games DESC)                ← Rankings
  ✓ INDEX (name)                            ← Búsqueda por nombre
  ✓ INDEX (created_at DESC)                 ← Equipos recientes

TABLE: match_requests
  ✓ PRIMARY KEY (id)
  ✓ INDEX (user_id)                         ← FK, solicitudes del usuario
  ✓ INDEX (team_id)                         ← FK, solicitudes del equipo
  ✓ INDEX (status)                          ← Filtrar activas/matched
  ✓ INDEX (football_type)                   ← Filtrar por tipo
  ✓ INDEX (match_date)                      ← Ordenar por fecha
  ✓ INDEX (created_at DESC)                 ← Solicitudes recientes
  ✓ COMPOSITE INDEX (status, created_at)    ← Query más común: activas + recientes
  ✓ FULLTEXT INDEX (description, field_address) ← Búsqueda de texto

TABLE: matches
  ✓ PRIMARY KEY (id)
  ✓ UNIQUE INDEX (match_request_id)         ← Relación 1:1
  ✓ INDEX (team1_id, team2_id)              ← FK, buscar partidos por equipo
  ✓ INDEX (user1_id, user2_id)              ← FK, buscar partidos por usuario
  ✓ INDEX (status)                          ← Filtrar pending/completed
  ✓ INDEX (final_date)                      ← Ordenar por fecha
  ✓ INDEX (created_at DESC)                 ← Partidos recientes
  ✓ COMPOSITE INDEX (status, final_date)    ← Query común: partidos próximos
  ✓ COMPOSITE INDEX (user1_id, final_date)  ← Partidos de un usuario ordenados

TABLE: match_results
  ✓ PRIMARY KEY (id)
  ✓ UNIQUE INDEX (match_id)                 ← Relación 1:1
  ✓ INDEX (winner_id)                       ← FK, victorias por equipo
  ✓ INDEX (result_type)                     ← Filtrar wins/draws
  ✓ INDEX (verified)                        ← Resultados verificados
  ✓ INDEX (created_at DESC)                 ← Resultados recientes

TABLE: notifications
  ✓ PRIMARY KEY (id)
  ✓ INDEX (user_id)                         ← FK, notificaciones del usuario
  ✓ INDEX (read_status)                     ← Filtrar leídas/no leídas
  ✓ COMPOSITE INDEX (user_id, read_status, created_at DESC) ← Query crítica
  ✓ INDEX (created_at DESC)                 ← Notificaciones recientes
```

---

## QUERIES MÁS COMUNES Y SUS ÍNDICES

```sql
-- ============================================
-- QUERY 1: Listar solicitudes activas disponibles
-- ============================================
SELECT mr.*, t.name AS team_name, u.name AS user_name
FROM match_requests mr
JOIN teams t ON mr.team_id = t.id
JOIN users u ON mr.user_id = u.id
WHERE mr.status = 'active'
  AND mr.user_id != ?
ORDER BY mr.created_at DESC;

-- Índices utilizados:
-- ✓ match_requests(status, created_at) [COMPOSITE]
-- ✓ teams(id) [PK]
-- ✓ users(id) [PK]

-- ============================================
-- QUERY 2: Mis partidos próximos
-- ============================================
SELECT m.*, t1.name AS team1_name, t2.name AS team2_name
FROM matches m
JOIN teams t1 ON m.team1_id = t1.id
JOIN teams t2 ON m.team2_id = t2.id
WHERE (m.user1_id = ? OR m.user2_id = ?)
  AND m.status IN ('pending', 'confirmed')
  AND m.final_date >= NOW()
ORDER BY m.final_date ASC;

-- Índices utilizados:
-- ✓ matches(user1_id, final_date) [COMPOSITE]
-- ✓ matches(status) [SIMPLE]
-- ✓ teams(id) [PK]

-- ============================================
-- QUERY 3: Ranking de equipos
-- ============================================
SELECT 
    t.id,
    t.name,
    t.total_games,
    t.games_won,
    (t.games_won * 3 + t.games_drawn) AS points,
    t.goals_for - t.goals_against AS goal_diff
FROM teams t
WHERE t.total_games > 0
ORDER BY points DESC, goal_diff DESC
LIMIT 20;

-- Índices utilizados:
-- ✓ teams(total_games DESC) [SIMPLE]

-- ============================================
-- QUERY 4: Mis notificaciones no leídas
-- ============================================
SELECT *
FROM notifications
WHERE user_id = ?
  AND read_status = FALSE
ORDER BY created_at DESC
LIMIT 10;

-- Índices utilizados:
-- ✓ notifications(user_id, read_status, created_at DESC) [COMPOSITE ÓPTIMO]

-- ============================================
-- QUERY 5: Búsqueda de solicitudes por texto
-- ============================================
SELECT *
FROM match_requests
WHERE MATCH(description, field_address) 
      AGAINST('cancha madrid' IN NATURAL LANGUAGE MODE)
  AND status = 'active';

-- Índices utilizados:
-- ✓ match_requests FULLTEXT(description, field_address)
-- ✓ match_requests(status) [SIMPLE]

-- ============================================
-- QUERY 6: Historial de un equipo
-- ============================================
SELECT 
    m.id,
    m.final_date,
    CASE 
        WHEN m.team1_id = ? THEN t2.name
        ELSE t1.name
    END AS opponent,
    mr.team1_score,
    mr.team2_score,
    CASE
        WHEN mr.winner_id = ? THEN 'Victoria'
        WHEN mr.winner_id IS NULL THEN 'Empate'
        ELSE 'Derrota'
    END AS result
FROM matches m
JOIN teams t1 ON m.team1_id = t1.id
JOIN teams t2 ON m.team2_id = t2.id
LEFT JOIN match_results mr ON m.id = mr.match_id
WHERE (m.team1_id = ? OR m.team2_id = ?)
  AND m.status = 'completed'
ORDER BY m.final_date DESC;

-- Índices utilizados:
-- ✓ matches(team1_id) [SIMPLE]
-- ✓ matches(status) [SIMPLE]
-- ✓ match_results(match_id) [UNIQUE]
```

---

## EJEMPLO DE DATOS

```sql
-- ============================================
-- DATOS DE EJEMPLO INSERTADOS
-- ============================================

-- Usuario 1
INSERT INTO users VALUES 
('usr-001', 'juan@ejemplo.com', '$2a$10$...', 'Juan Pérez', '+34612345678', 
 TRUE, TRUE, NOW(), NOW(), NOW());

-- Equipo de Usuario 1
INSERT INTO teams VALUES 
('team-001', 'usr-001', 'Los Cracks FC', 'Equipo amateur de Madrid', NULL,
 5, 2, 1, 8, 23, 15, NOW(), NOW());

-- Solicitud de Partido
INSERT INTO match_requests VALUES 
('req-001', 'usr-001', 'team-001', '7', 'Calle Mayor 123, Madrid', 50.00,
 '2026-02-20 18:00:00', 'Regional', 'Buscamos rival para amistoso', 
 'active', NULL, NOW(), NOW());

-- Usuario 2 acepta
INSERT INTO users VALUES 
('usr-002', 'maria@ejemplo.com', '$2a$10$...', 'María García', '+34698765432',
 TRUE, TRUE, NOW(), NOW(), NOW());

INSERT INTO teams VALUES 
('team-002', 'usr-002', 'Tigres United', 'Veteranos', NULL,
 3, 4, 2, 9, 18, 20, NOW(), NOW());

-- Match creado
INSERT INTO matches VALUES 
('match-001', 'req-001', 'team-001', 'team-002', 'usr-001', 'usr-002',
 'confirmed', '2026-02-20 18:00:00', 'Calle Mayor 123, Madrid', 50.00,
 '7', NULL, NOW(), NOW(), NOW(), NULL);

-- Resultado después de jugar
INSERT INTO match_results VALUES 
('res-001', 'match-001', 3, 2, 'team-001', FALSE, NULL, NULL,
 TRUE, TRUE, TRUE, 'Gran partido!', NOW(), NOW());

-- Esta inserción AUTOMÁTICAMENTE actualiza las estadísticas vía TRIGGER:
-- teams.games_won
-- teams.total_games  
-- teams.goals_for
-- teams.goals_against
-- matches.status = 'completed'
```

---

## VISTAS ÚTILES CREADAS

```sql
-- ============================================
-- VISTA 1: v_team_stats
-- Estadísticas enriquecidas de equipos
-- ============================================
CREATE VIEW v_team_stats AS
SELECT 
    t.id,
    t.name,
    u.name AS owner,
    t.total_games,
    t.games_won,
    t.games_lost,
    t.games_drawn,
    (t.goals_for - t.goals_against) AS goal_diff,
    ROUND((t.games_won * 100.0 / t.total_games), 2) AS win_pct
FROM teams t
JOIN users u ON t.user_id = u.id
WHERE t.total_games > 0;

-- Uso:
SELECT * FROM v_team_stats ORDER BY win_pct DESC LIMIT 10;

-- ============================================
-- VISTA 2: v_active_requests
-- Solicitudes activas con información completa
-- ============================================
CREATE VIEW v_active_requests AS
SELECT 
    mr.*,
    t.name AS team_name,
    u.name AS user_name,
    u.phone AS contact_phone
FROM match_requests mr
JOIN teams t ON mr.team_id = t.id
JOIN users u ON mr.user_id = u.id
WHERE mr.status = 'active';

-- Uso:
SELECT * FROM v_active_requests WHERE football_type = '7';

-- ============================================
-- VISTA 3: v_upcoming_matches
-- Partidos próximos
-- ============================================
CREATE VIEW v_upcoming_matches AS
SELECT 
    m.id,
    m.final_date,
    t1.name AS team1,
    t2.name AS team2,
    m.final_address
FROM matches m
JOIN teams t1 ON m.team1_id = t1.id
JOIN teams t2 ON m.team2_id = t2.id
WHERE m.status IN ('pending', 'confirmed')
  AND m.final_date >= NOW();

-- Uso:
SELECT * FROM v_upcoming_matches ORDER BY final_date ASC;
```

---

## PROCEDIMIENTOS ALMACENADOS

```sql
-- ============================================
-- PROCEDIMIENTO 1: Obtener ranking
-- ============================================
CALL sp_get_team_rankings(20);

-- Retorna top 20 equipos por puntos

-- ============================================
-- PROCEDIMIENTO 2: Buscar solicitudes
-- ============================================
CALL sp_search_available_requests(
    'usr-001',      -- Mi user_id (excluir mis solicitudes)
    '7',            -- Tipo de fútbol (NULL = todos)
    '2026-02-15',   -- Desde (NULL = sin filtro)
    '2026-02-28'    -- Hasta (NULL = sin filtro)
);

-- Retorna solicitudes disponibles filtradas
```

---

## TRIGGERS AUTOMÁTICOS

```sql
-- ============================================
-- TRIGGER 1: Actualizar estadísticas al insertar resultado
-- ============================================
-- Se ejecuta automáticamente al hacer:
INSERT INTO match_results (match_id, team1_score, team2_score, ...) 
VALUES (...);

-- Actualiza automáticamente:
-- ✓ teams.games_won / games_lost / games_drawn
-- ✓ teams.total_games
-- ✓ teams.goals_for / goals_against
-- ✓ matches.status = 'completed'

-- ============================================
-- TRIGGER 2: Actualizar solicitud al crear match
-- ============================================
-- Se ejecuta automáticamente al hacer:
INSERT INTO matches (match_request_id, team1_id, team2_id, ...) 
VALUES (...);

-- Actualiza automáticamente:
-- ✓ match_requests.status = 'matched'
```

---

## TAMAÑOS ESPERADOS

```
┌───────────────────────────────────────────────────────────────┐
│              ESTIMACIÓN DE TAMAÑO DE TABLAS                    │
├─────────────────┬──────────────┬──────────────┬───────────────┤
│ Tabla           │ Filas        │ Tamaño/Fila  │ Tamaño Total  │
├─────────────────┼──────────────┼──────────────┼───────────────┤
│ users           │ 10,000       │ ~200 bytes   │ ~2 MB         │
│ teams           │ 15,000       │ ~250 bytes   │ ~3.75 MB      │
│ match_requests  │ 50,000       │ ~400 bytes   │ ~20 MB        │
│ matches         │ 30,000       │ ~300 bytes   │ ~9 MB         │
│ match_results   │ 30,000       │ ~150 bytes   │ ~4.5 MB       │
│ notifications   │ 100,000      │ ~200 bytes   │ ~20 MB        │
│ audit_log       │ 500,000      │ ~250 bytes   │ ~125 MB       │
├─────────────────┴──────────────┴──────────────┼───────────────┤
│ TOTAL (sin índices)                            │ ~184 MB       │
│ TOTAL (con índices, estimado +50%)            │ ~276 MB       │
└────────────────────────────────────────────────┴───────────────┘

Nota: Para 100K usuarios activos, la base de datos completa ocuparía menos de 1GB.
```

---

## CONCLUSIÓN

Esta base de datos está diseñada para:

✅ **Normalizada**: Elimina redundancia, mantiene integridad
✅ **Optimizada**: Índices estratégicos para queries comunes
✅ **Escalable**: Soporta millones de registros sin degradación
✅ **Segura**: Constraints, triggers, y foreign keys
✅ **Mantenible**: Vistas y procedimientos para lógica compleja
✅ **Documentada**: Cada decisión está explicada

**Siguiente paso:** Ejecutar `database/mysql_schema.sql` y seguir la guía de implementación.
