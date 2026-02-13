-- ============================================
-- AMISTOSO TER - MYSQL DATABASE SCHEMA
-- ============================================
-- Version: 1.0
-- MySQL: 8.0+
-- Character Set: utf8mb4 (soporte completo Unicode y emojis)
-- Collation: utf8mb4_unicode_ci (insensible a mayúsculas/minúsculas)
-- Engine: InnoDB (transacciones ACID, integridad referencial)
-- ============================================

-- ============================================
-- 1. CREAR BASE DE DATOS
-- ============================================
CREATE DATABASE IF NOT EXISTS amistoso_ter_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE amistoso_ter_db;

-- ============================================
-- 2. TABLA: users
-- Descripción: Usuarios registrados en la plataforma
-- ============================================
CREATE TABLE users (
    -- Identificador único
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    
    -- Credenciales (email único para login)
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash CHAR(60) NOT NULL COMMENT 'bcrypt hash ($2a$10$...)',
    
    -- Información personal
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NULL COMMENT 'Formato internacional: +34612345678',
    
    -- Configuración de cuenta
    email_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP NULL,
    
    -- Índices para rendimiento
    INDEX idx_email (email),
    INDEX idx_active (is_active),
    INDEX idx_created (created_at DESC)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Usuarios registrados en la plataforma';

-- ============================================
-- 3. TABLA: teams
-- Descripción: Equipos creados por los usuarios
-- ============================================
CREATE TABLE teams (
    -- Identificador único
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    
    -- Relación con usuario
    user_id CHAR(36) NOT NULL,
    
    -- Información del equipo
    name VARCHAR(200) NOT NULL,
    description TEXT NULL,
    logo_url VARCHAR(500) NULL COMMENT 'URL del logo del equipo',
    
    -- Estadísticas (desnormalizado por rendimiento)
    games_won INT UNSIGNED DEFAULT 0,
    games_lost INT UNSIGNED DEFAULT 0,
    games_drawn INT UNSIGNED DEFAULT 0,
    total_games INT UNSIGNED DEFAULT 0,
    goals_for INT UNSIGNED DEFAULT 0 COMMENT 'Goles a favor',
    goals_against INT UNSIGNED DEFAULT 0 COMMENT 'Goles en contra',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Claves foráneas
    CONSTRAINT fk_teams_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    
    -- Índices
    INDEX idx_user_id (user_id),
    INDEX idx_total_games (total_games DESC),
    INDEX idx_name (name),
    INDEX idx_created (created_at DESC),
    
    -- Restricciones de integridad
    CONSTRAINT chk_stats_valid CHECK (
        total_games = (games_won + games_lost + games_drawn)
    )
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Equipos de fútbol creados por usuarios';

-- ============================================
-- 4. TABLA: match_requests
-- Descripción: Solicitudes de partidos amistosos publicadas
-- ============================================
CREATE TABLE match_requests (
    -- Identificador único
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    
    -- Relaciones
    user_id CHAR(36) NOT NULL COMMENT 'Usuario que publica la solicitud',
    team_id CHAR(36) NOT NULL COMMENT 'Equipo que busca rival',
    
    -- Datos del partido solicitado
    football_type ENUM('5', '7', '8', '11', 'otro') NULL COMMENT 'Tipo de fútbol',
    field_address VARCHAR(500) NULL COMMENT 'Dirección de la cancha',
    field_price DECIMAL(10,2) NULL COMMENT 'Precio en euros',
    match_date DATETIME NULL COMMENT 'Fecha y hora propuesta',
    league VARCHAR(100) NULL COMMENT 'Liga del equipo solicitante',
    
    -- Información adicional
    description TEXT NULL COMMENT 'Descripción adicional o requisitos',
    
    -- Estado de la solicitud
    status ENUM('active', 'matched', 'cancelled', 'expired') DEFAULT 'active',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL COMMENT 'Fecha de expiración automática',
    
    -- Claves foráneas
    CONSTRAINT fk_match_requests_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_match_requests_team 
        FOREIGN KEY (team_id) 
        REFERENCES teams(id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    
    -- Índices para búsquedas y filtros
    INDEX idx_user_id (user_id),
    INDEX idx_team_id (team_id),
    INDEX idx_status (status),
    INDEX idx_football_type (football_type),
    INDEX idx_match_date (match_date),
    INDEX idx_created (created_at DESC),
    INDEX idx_status_created (status, created_at DESC) COMMENT 'Índice compuesto para listados',
    
    -- Full-text search para búsqueda por texto
    FULLTEXT INDEX ft_description (description, field_address)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Solicitudes de partidos publicadas';

-- ============================================
-- 5. TABLA: matches
-- Descripción: Partidos confirmados entre dos equipos
-- ============================================
CREATE TABLE `matches` (
    -- Identificador único
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    
    -- Relación con la solicitud original (1:1)
    match_request_id CHAR(36) NOT NULL UNIQUE,
    
    -- Equipos participantes
    team1_id CHAR(36) NOT NULL COMMENT 'Equipo que publicó la solicitud',
    team2_id CHAR(36) NOT NULL COMMENT 'Equipo que aceptó el match',
    
    -- Usuarios participantes
    user1_id CHAR(36) NOT NULL COMMENT 'Usuario del equipo 1',
    user2_id CHAR(36) NOT NULL COMMENT 'Usuario del equipo 2',
    
    -- Estado del partido
    status ENUM('pending', 'confirmed', 'completed', 'cancelled') DEFAULT 'pending',
    
    -- Datos finales acordados (pueden diferir de la solicitud)
    final_date DATETIME NULL COMMENT 'Fecha/hora definitiva acordada',
    final_address VARCHAR(500) NULL COMMENT 'Dirección definitiva',
    final_price DECIMAL(10,2) NULL COMMENT 'Precio final acordado',
    final_football_type ENUM('5', '7', '8', '11', 'otro') NULL,
    
    -- Información adicional
    notes TEXT NULL COMMENT 'Notas o acuerdos adicionales',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP NULL COMMENT 'Momento en que ambos confirmaron',
    completed_at TIMESTAMP NULL COMMENT 'Momento en que se jugó',
    
    -- Claves foráneas
    CONSTRAINT fk_matches_request 
        FOREIGN KEY (match_request_id) 
        REFERENCES match_requests(id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_matches_team1 
        FOREIGN KEY (team1_id) 
        REFERENCES teams(id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_matches_team2 
        FOREIGN KEY (team2_id) 
        REFERENCES teams(id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_matches_user1 
        FOREIGN KEY (user1_id) 
        REFERENCES users(id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_matches_user2 
        FOREIGN KEY (user2_id) 
        REFERENCES users(id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    -- Índices
    INDEX idx_match_request (match_request_id),
    INDEX idx_team1 (team1_id),
    INDEX idx_team2 (team2_id),
    INDEX idx_user1 (user1_id),
    INDEX idx_user2 (user2_id),
    INDEX idx_status (status),
    INDEX idx_final_date (final_date),
    INDEX idx_created (created_at DESC),
    INDEX idx_status_date (status, final_date) COMMENT 'Búsqueda de partidos por estado y fecha',
    
    -- Restricciones de integridad
    CONSTRAINT chk_different_teams CHECK (team1_id != team2_id),
    CONSTRAINT chk_different_users CHECK (user1_id != user2_id)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Partidos confirmados entre equipos';

-- ============================================
-- 6. TABLA: match_results
-- Descripción: Resultados de partidos finalizados
-- ============================================
CREATE TABLE match_results (
    -- Identificador único
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    
    -- Relación 1:1 con el partido
    match_id CHAR(36) NOT NULL UNIQUE,
    
    -- Resultado
    team1_score TINYINT UNSIGNED NOT NULL DEFAULT 0,
    team2_score TINYINT UNSIGNED NOT NULL DEFAULT 0,
    
    -- Determinación del ganador (desnormalizado para queries rápidas)
    winner_id CHAR(36) NULL COMMENT 'NULL = empate',
    result_type ENUM('win_team1', 'win_team2', 'draw') AS (
        CASE 
            WHEN team1_score > team2_score THEN 'win_team1'
            WHEN team2_score > team1_score THEN 'win_team2'
            ELSE 'draw'
        END
    ) STORED COMMENT 'Columna generada para consultas rápidas',
    
    -- Información adicional del resultado
    penalties BOOLEAN DEFAULT FALSE COMMENT 'Si se definió por penales',
    team1_penalties TINYINT UNSIGNED NULL,
    team2_penalties TINYINT UNSIGNED NULL,
    
    -- Verificación y validación
    verified BOOLEAN DEFAULT FALSE COMMENT 'Si ambos usuarios confirmaron el resultado',
    verified_by_user1 BOOLEAN DEFAULT FALSE,
    verified_by_user2 BOOLEAN DEFAULT FALSE,
    
    -- Notas del partido
    notes TEXT NULL COMMENT 'Comentarios sobre el partido',
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Claves foráneas
    CONSTRAINT fk_results_match 
        FOREIGN KEY (match_id) 
        REFERENCES `matches`(id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
        
    CONSTRAINT fk_results_winner 
        FOREIGN KEY (winner_id) 
        REFERENCES teams(id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
    
    -- Índices
    INDEX idx_match (match_id),
    INDEX idx_winner (winner_id),
    INDEX idx_result_type (result_type),
    INDEX idx_verified (verified),
    INDEX idx_created (created_at DESC),
    
    -- Restricciones de integridad
    CONSTRAINT chk_scores_valid CHECK (
        team1_score >= 0 AND team2_score >= 0
    ),
    CONSTRAINT chk_penalties_valid CHECK (
        (penalties = FALSE AND team1_penalties IS NULL AND team2_penalties IS NULL) OR
        (penalties = TRUE AND team1_penalties IS NOT NULL AND team2_penalties IS NOT NULL)
    )
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Resultados de partidos finalizados';

-- ============================================
-- 7. TABLA: notifications (OPCIONAL - Para notificaciones)
-- Descripción: Sistema de notificaciones push/email
-- ============================================
CREATE TABLE notifications (
    -- Identificador único
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    
    -- Destinatario
    user_id CHAR(36) NOT NULL,
    
    -- Contenido
    type ENUM('match_request', 'match_confirmed', 'match_cancelled', 'result_pending', 'system') NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    
    -- Datos relacionados (JSON para flexibilidad)
    data JSON NULL COMMENT 'Datos adicionales en formato JSON',
    
    -- Estado
    read_status BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Claves foráneas
    CONSTRAINT fk_notifications_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    
    -- Índices
    INDEX idx_user_id (user_id),
    INDEX idx_read_status (read_status),
    INDEX idx_user_unread (user_id, read_status, created_at DESC) COMMENT 'Notificaciones no leídas por usuario',
    INDEX idx_created (created_at DESC)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Notificaciones del sistema';

-- ============================================
-- 8. TABLA: audit_log (OPCIONAL - Para auditoría)
-- Descripción: Registro de acciones importantes
-- ============================================
CREATE TABLE audit_log (
    -- Identificador único
    id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    
    -- Usuario que realizó la acción
    user_id CHAR(36) NULL COMMENT 'NULL para acciones del sistema',
    
    -- Acción realizada
    action VARCHAR(100) NOT NULL COMMENT 'Ej: user_login, team_created, match_completed',
    entity_type VARCHAR(50) NOT NULL COMMENT 'Ej: user, team, match',
    entity_id CHAR(36) NULL COMMENT 'ID de la entidad afectada',
    
    -- Detalles
    ip_address VARCHAR(45) NULL COMMENT 'IPv4 o IPv6',
    user_agent VARCHAR(500) NULL,
    details JSON NULL COMMENT 'Información adicional en JSON',
    
    -- Timestamp
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Claves foráneas (opcional, puede ser NULL para registros históricos)
    CONSTRAINT fk_audit_user 
        FOREIGN KEY (user_id) 
        REFERENCES users(id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE,
    
    -- Índices
    INDEX idx_user_id (user_id),
    INDEX idx_action (action),
    INDEX idx_entity (entity_type, entity_id),
    INDEX idx_created (created_at DESC),
    INDEX idx_user_action_date (user_id, action, created_at DESC)
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Registro de auditoría de acciones';

-- ============================================
-- 9. VISTAS ÚTILES
-- ============================================

-- Vista: Estadísticas de equipos enriquecidas
CREATE OR REPLACE VIEW v_team_stats AS
SELECT 
    t.id,
    t.name,
    t.user_id,
    u.name AS user_name,
    t.total_games,
    t.games_won,
    t.games_lost,
    t.games_drawn,
    t.goals_for,
    t.goals_against,
    (t.goals_for - t.goals_against) AS goal_difference,
    CASE 
        WHEN t.total_games > 0 
        THEN ROUND((t.games_won * 100.0 / t.total_games), 2)
        ELSE 0 
    END AS win_percentage,
    t.created_at
FROM teams t
INNER JOIN users u ON t.user_id = u.id
WHERE u.is_active = TRUE;

-- Vista: Solicitudes activas con información completa
CREATE OR REPLACE VIEW v_active_requests AS
SELECT 
    mr.id,
    mr.user_id,
    u.name AS user_name,
    u.phone AS user_phone,
    mr.team_id,
    t.name AS team_name,
    mr.football_type,
    mr.field_address,
    mr.field_price,
    mr.match_date,
    mr.league,
    mr.description,
    mr.created_at,
    DATEDIFF(COALESCE(mr.expires_at, DATE_ADD(mr.created_at, INTERVAL 30 DAY)), NOW()) AS days_until_expiry
FROM match_requests mr
INNER JOIN users u ON mr.user_id = u.id
INNER JOIN teams t ON mr.team_id = t.id
WHERE mr.status = 'active'
  AND u.is_active = TRUE
ORDER BY mr.created_at DESC;

-- Vista: Partidos próximos
CREATE OR REPLACE VIEW v_upcoming_matches AS
SELECT 
    m.id,
    m.final_date,
    m.status,
    m.final_address,
    t1.id AS team1_id,
    t1.name AS team1_name,
    t2.id AS team2_id,
    t2.name AS team2_name,
    u1.name AS user1_name,
    u1.phone AS user1_phone,
    u2.name AS user2_name,
    u2.phone AS user2_phone,
    m.created_at
FROM `matches` m
INNER JOIN teams t1 ON m.team1_id = t1.id
INNER JOIN teams t2 ON m.team2_id = t2.id
INNER JOIN users u1 ON m.user1_id = u1.id
INNER JOIN users u2 ON m.user2_id = u2.id
WHERE m.status IN ('pending', 'confirmed')
  AND m.final_date IS NOT NULL
  AND m.final_date >= NOW()
ORDER BY m.final_date ASC;

-- ============================================
-- 10. TRIGGERS PARA MANTENER INTEGRIDAD
-- ============================================

-- Trigger: Actualizar estadísticas del equipo al insertar resultado
DELIMITER //

CREATE TRIGGER trg_update_team_stats_after_result
AFTER INSERT ON match_results
FOR EACH ROW
BEGIN
    DECLARE v_team1_id CHAR(36);
    DECLARE v_team2_id CHAR(36);
    
    -- Obtener los IDs de los equipos
    SELECT team1_id, team2_id INTO v_team1_id, v_team2_id
    FROM `matches`
    WHERE id = NEW.match_id;
    
    -- Actualizar estadísticas del equipo 1
    UPDATE teams
    SET 
        games_won = games_won + IF(NEW.team1_score > NEW.team2_score, 1, 0),
        games_lost = games_lost + IF(NEW.team1_score < NEW.team2_score, 1, 0),
        games_drawn = games_drawn + IF(NEW.team1_score = NEW.team2_score, 1, 0),
        total_games = total_games + 1,
        goals_for = goals_for + NEW.team1_score,
        goals_against = goals_against + NEW.team2_score
    WHERE id = v_team1_id;
    
    -- Actualizar estadísticas del equipo 2
    UPDATE teams
    SET 
        games_won = games_won + IF(NEW.team2_score > NEW.team1_score, 1, 0),
        games_lost = games_lost + IF(NEW.team2_score < NEW.team1_score, 1, 0),
        games_drawn = games_drawn + IF(NEW.team2_score = NEW.team1_score, 1, 0),
        total_games = total_games + 1,
        goals_for = goals_for + NEW.team2_score,
        goals_against = goals_against + NEW.team1_score
    WHERE id = v_team2_id;
    
    -- Actualizar estado del match a 'completed'
    UPDATE `matches`
    SET 
        status = 'completed',
        completed_at = CURRENT_TIMESTAMP
    WHERE id = NEW.match_id;
END//

DELIMITER ;

-- Trigger: Actualizar estado de solicitud al crear match
DELIMITER //

CREATE TRIGGER trg_update_request_status_after_match
AFTER INSERT ON `matches`
FOR EACH ROW
BEGIN
    UPDATE match_requests
    SET status = 'matched'
    WHERE id = NEW.match_request_id;
END//

DELIMITER ;

-- ============================================
-- 11. PROCEDIMIENTOS ALMACENADOS ÚTILES
-- ============================================

-- Procedimiento: Obtener ranking de equipos
DELIMITER //

CREATE PROCEDURE sp_get_team_rankings(
    IN p_limit INT
)
BEGIN
    SELECT 
        t.id,
        t.name,
        t.total_games,
        t.games_won,
        t.games_lost,
        t.games_drawn,
        (t.games_won * 3 + t.games_drawn) AS points,
        t.goals_for,
        t.goals_against,
        (t.goals_for - t.goals_against) AS goal_difference,
        CASE 
            WHEN t.total_games > 0 
            THEN ROUND((t.games_won * 100.0 / t.total_games), 2)
            ELSE 0 
        END AS win_percentage
    FROM teams t
    WHERE t.total_games > 0
    ORDER BY points DESC, goal_difference DESC, goals_for DESC
    LIMIT p_limit;
END//

DELIMITER ;

-- Procedimiento: Buscar solicitudes disponibles
DELIMITER //

CREATE PROCEDURE sp_search_available_requests(
    IN p_user_id CHAR(36),
    IN p_football_type VARCHAR(10),
    IN p_date_from DATETIME,
    IN p_date_to DATETIME
)
BEGIN
    SELECT 
        mr.*,
        t.name AS team_name,
        u.name AS user_name,
        u.phone AS user_phone
    FROM match_requests mr
    INNER JOIN teams t ON mr.team_id = t.id
    INNER JOIN users u ON mr.user_id = u.id
    WHERE mr.user_id != p_user_id
      AND mr.status = 'active'
      AND (p_football_type IS NULL OR mr.football_type = p_football_type)
      AND (p_date_from IS NULL OR mr.match_date >= p_date_from)
      AND (p_date_to IS NULL OR mr.match_date <= p_date_to)
    ORDER BY mr.created_at DESC;
END//

DELIMITER ;

-- ============================================
-- 12. DATOS DE EJEMPLO (OPCIONAL)
-- ============================================

-- Usuarios de prueba
INSERT INTO users (id, email, password_hash, name, phone, email_verified, is_active) VALUES
('user-001', 'juan.perez@ejemplo.com', '$2a$10$XYZ...', 'Juan Pérez', '+34612345678', TRUE, TRUE),
('user-002', 'maria.garcia@ejemplo.com', '$2a$10$ABC...', 'María García', '+34698765432', TRUE, TRUE),
('user-003', 'carlos.lopez@ejemplo.com', '$2a$10$DEF...', 'Carlos López', '+34611223344', TRUE, TRUE);

-- Equipos de prueba
INSERT INTO teams (id, user_id, name, description) VALUES
('team-001', 'user-001', 'Los Cracks FC', 'Equipo amateur de Madrid'),
('team-002', 'user-002', 'Tigres United', 'Equipo veterano'),
('team-003', 'user-003', 'Relámpagos', 'Equipo juvenil');

-- ============================================
-- ÍNDICES ADICIONALES PARA OPTIMIZACIÓN
-- ============================================

-- Índice para búsquedas de partidos por fecha y usuario
CREATE INDEX idx_matches_user_date ON `matches`(user1_id, final_date DESC);
CREATE INDEX idx_matches_user2_date ON `matches`(user2_id, final_date DESC);

-- Índice para búsquedas de solicitudes activas por tipo de fútbol
CREATE INDEX idx_requests_type_status ON match_requests(football_type, status, created_at DESC);

-- ============================================
-- CONFIGURACIONES RECOMENDADAS DE MYSQL
-- ============================================

/*
Añadir a my.cnf o my.ini:

[mysqld]
# Character set
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# InnoDB settings
innodb_buffer_pool_size=1G
innodb_log_file_size=256M
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT

# Query cache (deshabilitado en MySQL 8.0+)
# query_cache_type=0

# Connections
max_connections=200
max_allowed_packet=64M

# Logs
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow-query.log
long_query_time=2

# Binary logs para replicación
log_bin=mysql-bin
binlog_format=ROW
expire_logs_days=7
*/

-- ============================================
-- FIN DEL SCRIPT
-- ============================================
