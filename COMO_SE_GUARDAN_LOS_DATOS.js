// Este archivo muestra cómo se guardan y recuperan los datos en tu aplicación

// ============================================
// 1. CÓMO SE GUARDAN LOS USUARIOS
// ============================================

// REGISTRO (app/api/auth/register/route.ts)
import bcrypt from 'bcryptjs';
import { prisma } from '@/lib/prisma';

// Paso 1: Usuario envía email, contraseña, nombre, teléfono
const userData = {
  email: "usuario@ejemplo.com",
  password: "MiContraseña123",
  name: "Juan Pérez",
  phone: "+34612345678"
};

// Paso 2: La contraseña se ENCRIPTA con bcrypt (hash de 1 vía)
const hashedPassword = await bcrypt.hash(userData.password, 10);
// Resultado: "$2a$10$XYZ..." (la contraseña original NO se guarda)

// Paso 3: Se guarda en la base de datos
await prisma.user.create({
  data: {
    email: userData.email,
    password: hashedPassword,  // ✅ Solo el hash, no la contraseña real
    name: userData.name,
    phone: userData.phone,
  },
});

// ============================================
// 2. CÓMO SE VERIFICA EL LOGIN
// ============================================

// LOGIN (lib/auth.ts con NextAuth)

// Paso 1: Usuario intenta login con email y contraseña
const loginAttempt = {
  email: "usuario@ejemplo.com",
  password: "MiContraseña123"
};

// Paso 2: Buscar usuario por email
const user = await prisma.user.findUnique({
  where: { email: loginAttempt.email }
});

// Paso 3: Comparar contraseña con el hash guardado
const isValid = await bcrypt.compare(
  loginAttempt.password,        // Lo que escribió el usuario
  user.password                  // El hash guardado en la BD
);

// Paso 4: Si coincide, crear sesión con JWT
if (isValid) {
  // NextAuth crea token JWT y sesión
  return {
    id: user.id,
    email: user.email,
    name: user.name,
  };
}

// ============================================
// 3. CÓMO SE GUARDAN OTROS DATOS (Ejemplo: Equipos)
// ============================================

// CREAR EQUIPO
const nuevoEquipo = await prisma.team.create({
  data: {
    name: "Los Cracks FC",
    userId: "usuario_id_desde_sesion",
  },
});

// RECUPERAR EQUIPOS
const equipos = await prisma.team.findMany({
  where: {
    userId: "usuario_id_desde_sesion"
  },
  include: {
    user: true,  // Incluye datos del usuario dueño
  },
});

// ============================================
// 4. CÓMO FUNCIONA PRISMA (ORM)
// ============================================

// Prisma traduce tu código TypeScript a SQL:

// Tu código (TypeScript):
const partidos = await prisma.match.findMany({
  where: { status: 'pending' },
  include: { team1: true, team2: true }
});

// Se convierte en SQL (automático):
/*
  SELECT 
    m.*,
    t1.id AS team1_id, t1.name AS team1_name,
    t2.id AS team2_id, t2.name AS team2_name
  FROM Match m
  LEFT JOIN Team t1 ON m.team1Id = t1.id
  LEFT JOIN Team t2 ON m.team2Id = t2.id
  WHERE m.status = 'pending'
*/

// ============================================
// 5. DÓNDE SE GUARDAN LOS DATOS
// ============================================

// DESARROLLO (Actual):
// - Base de datos: SQLite
// - Ubicación: ./prisma/dev.db (archivo local)
// - Ventajas: No requiere configuración, rápido para desarrollo
// - Desventajas: No sirve para producción con múltiples usuarios

// PRODUCCIÓN (Cuando despliegues):
// - Base de datos: PostgreSQL / MySQL / MongoDB
// - Ubicación: Servidor remoto (Supabase, Vercel, Railway, etc.)
// - Ventajas: Escalable, seguro, múltiples conexiones simultáneas
// - Desventajas: Requiere configuración y puede tener costo

// ============================================
// 6. ESTRUCTURA DE DATOS EN LA BASE DE DATOS
// ============================================

// TABLA: User
/*
  id          | email                | password (hash)           | name      | phone
  ------------|---------------------|---------------------------|-----------|------------
  clx1abc123  | juan@ejemplo.com    | $2a$10$XYZ...            | Juan      | +34612...
  clx2def456  | maria@ejemplo.com   | $2a$10$ABC...            | María     | +34698...
*/

// TABLA: Team
/*
  id          | name           | userId      | gamesWon | gamesLost | totalGames
  ------------|----------------|-------------|----------|-----------|------------
  cly3ghi789  | Los Cracks FC  | clx1abc123  | 5        | 2         | 8
  cly4jkl012  | Tigres United  | clx2def456  | 3        | 4         | 7
*/

// TABLA: Match
/*
  id          | team1Id     | team2Id     | status    | finalDate
  ------------|-------------|-------------|-----------|------------------
  clz5mno345  | cly3ghi789  | cly4jkl012  | completed | 2026-02-10
  clz6pqr678  | cly3ghi789  | cly7stu901  | pending   | 2026-02-15
*/

// ============================================
// 7. SEGURIDAD
// ============================================

// ✅ LO QUE HACE TU APP (Correcto):
// - Contraseñas hasheadas con bcrypt (no reversible)
// - Validación de sesión en cada request
// - Queries parametrizadas (Prisma previene SQL injection)
// - CORS configurado
// - JWT para sesiones

// ❌ LO QUE NO HACE (Puedes mejorar para producción):
// - Rate limiting (prevenir ataques de fuerza bruta)
// - Verificación de email
// - 2FA (autenticación de dos factores)
// - Logs de auditoría
// - Backups automáticos

// ============================================
// 8. EJEMPLO COMPLETO: FLUJO DE REGISTRO A PARTIDO
// ============================================

// 1. Usuario se registra
const nuevoUsuario = await prisma.user.create({
  data: {
    email: "nuevo@ejemplo.com",
    password: await bcrypt.hash("password123", 10),
    name: "Nuevo Usuario",
  },
});
// → Se guarda en tabla User con contraseña hasheada

// 2. Usuario crea un equipo
const equipo = await prisma.team.create({
  data: {
    name: "Mi Equipo",
    userId: nuevoUsuario.id,
  },
});
// → Se guarda en tabla Team con relación al usuario

// 3. Usuario publica solicitud de partido
const solicitud = await prisma.matchRequest.create({
  data: {
    userId: nuevoUsuario.id,
    teamId: equipo.id,
    footballType: "7",
    fieldAddress: "Cancha Central",
    status: "active",
  },
});
// → Se guarda en tabla MatchRequest

// 4. Otro usuario acepta la solicitud
const partido = await prisma.match.create({
  data: {
    matchRequestId: solicitud.id,
    team1Id: equipo.id,
    team2Id: "otro_equipo_id",
    userId1: nuevoUsuario.id,
    userId2: "otro_usuario_id",
    status: "pending",
  },
});
// → Se guarda en tabla Match
// → La solicitud cambia status a "matched"

// 5. Se registra resultado
const resultado = await prisma.matchResult.create({
  data: {
    matchId: partido.id,
    team1Score: 3,
    team2Score: 2,
    winnerId: equipo.id,
  },
});
// → Se guarda en tabla MatchResult
// → Se actualizan estadísticas del equipo (gamesWon, totalGames)

// ============================================
// FIN: Todos los datos se guardan de forma relacional
// y pueden recuperarse fácilmente con Prisma
// ============================================
