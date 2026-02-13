# 🏛️ Guía de Arquitectura - Amistoso TER Web

## 📖 Índice
1. [Visión General](#visión-general)
2. [Capas de la Aplicación](#capas-de-la-aplicación)
3. [Flujo de Datos](#flujo-de-datos)
4. [Convenciones de Código](#convenciones-de-código)
5. [Creación de Nuevas Features](#creación-de-nuevas-features)
6. [Guía de Testing](#guía-de-testing)
7. [Troubleshooting](#troubleshooting)

---

## 🎯 Visión General

Esta aplicación sigue una **Arquitectura Limpia (Clean Architecture)** con separación de responsabilidades en capas bien definidas.

### Principios Fundamentales:
- **Separación de Concerns**: Cada capa tiene una responsabilidad única
- **Dependency Inversion**: Capas superiores dependen de abstracciones, no implementaciones
- **Testabilidad**: Cada capa puede testearse de forma aislada
- **Single Source of Truth**: MySQL es la única fuente de datos (no más archivos)

---

## 🧱 Capas de la Aplicación

### 1. Capa de Presentación (Presentation Layer)
📁 `app/` - Next.js App Router

**Responsabilidades:**
- Renderizar UI con React Server Components
- Manejar rutas con App Router
- Gestionar sesiones con NextAuth.js
- Validar autenticación antes de llamar servicios

**Archivos:**
```
app/
├── api/              # API Routes (HTTP endpoints)
├── dashboard/        # Páginas del dashboard (protegidas)
├── login/            # Página de login
├── register/         # Página de registro
└── partidos/         # Vista pública de partidos
```

**Ejemplo de API Route:**
```typescript
// app/api/teams/route.ts
import { TeamsService } from '@/lib/services-server';
import { handleApiError } from '@/lib/errors';

export async function GET() {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const teams = await TeamsService.getUserTeams(session.user.id);
    return NextResponse.json(teams);
  } catch (error) {
    const apiError = handleApiError(error);
    return NextResponse.json(
      { error: apiError.message },
      { status: apiError.statusCode }
    );
  }
}
```

---

### 2. Capa de Servicios (Service Layer)
📁 `lib/services-server/`

**Responsabilidades:**
- ✅ **Validación de datos de entrada**
- ✅ **Autorización** (verificar pertenencia de recursos)
- ✅ **Reglas de negocio** (ej: un equipo no puede tener múltiples solicitudes activas)
- ✅ **Orquestación** (coordinar múltiples repositorios)
- ✅ **Transformación de datos** (DTOs)
- ✅ **Manejo de transacciones**

**Archivos:**
```
lib/services-server/
├── teams.service.ts          # Lógica de equipos
├── requests.service.ts       # Lógica de solicitudes
├── matches.service.ts        # Lógica de partidos
└── index.ts                  # Barrel export
```

**Ejemplo de Método de Servicio:**
```typescript
// lib/services-server/teams.service.ts
export class TeamsService {
  static async createTeam(userId: string, name: string) {
    // 1. Validación
    if (!name || name.trim().length === 0) {
      throw new ValidationError('El nombre es requerido');
    }
    if (name.length > 100) {
      throw new ValidationError('El nombre no puede exceder 100 caracteres');
    }

    // 2. Sanitización
    const sanitizedName = name.trim();

    // 3. Lógica de negocio (ejemplo: verificar límite de equipos)
    const teamCount = await TeamsRepository.count({ userId });
    if (teamCount >= 10) {
      throw new BusinessRuleError('Has alcanzado el límite de 10 equipos');
    }

    // 4. Llamar al repositorio
    return await TeamsRepository.create({
      userId,
      name: sanitizedName,
    });
  }
}
```

---

### 3. Capa de Repositorios (Repository Layer)
📁 `lib/repositories/`

**Responsabilidades:**
- ✅ **Acceso a datos** (queries SQL con Prisma)
- ✅ **CRUD operations**
- ✅ **Queries complejas** (JOINs, agregaciones, FULLTEXT search)
- ❌ **NO contiene lógica de negocio**
- ❌ **NO valida datos** (eso es responsabilidad de Services)

**Archivos:**
```
lib/repositories/
├── users.repository.ts       # CRUD de usuarios
├── teams.repository.ts       # CRUD de equipos
├── requests.repository.ts    # CRUD de solicitudes
├── matches.repository.ts     # CRUD de partidos
├── results.repository.ts     # CRUD de resultados
└── index.ts                  # Barrel export
```

**Ejemplo de Método de Repositorio:**
```typescript
// lib/repositories/teams.repository.ts
export class TeamsRepository {
  // Query con Prisma
  static async findById(id: string) {
    return await prisma.team.findUnique({
      where: { id },
      include: { user: true },
    });
  }

  // Query SQL raw para casos complejos
  static async getTopTeamsByWins(limit: number = 10) {
    return await prisma.$queryRaw<TeamWithStats[]>`
      SELECT 
        t.*,
        t.wins,
        t.losses,
        t.draws,
        CASE 
          WHEN (t.wins + t.losses + t.draws) > 0 
          THEN ROUND((t.wins * 100.0) / (t.wins + t.losses + t.draws), 2)
          ELSE 0
        END as win_rate
      FROM teams t
      WHERE (t.wins + t.losses + t.draws) >= 5
      ORDER BY win_rate DESC, t.wins DESC
      LIMIT ${limit}
    `;
  }
}
```

---

### 4. Capa de Datos (Data Layer)
📁 `lib/prisma.ts` + `prisma/schema.prisma`

**Responsabilidades:**
- Configurar cliente de Prisma
- Definir esquema de base de datos
- Manejar migraciones

**Configuración del Cliente:**
```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client';

const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  });

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;
```

---

### 5. Sistema de Errores
📁 `lib/errors.ts`

**Errores Personalizados:**
```typescript
throw new ValidationError('Campo inválido');       // 400
throw new UnauthorizedError('Token expirado');     // 401
throw new ForbiddenError('Sin permisos');          // 403
throw new NotFoundError('Recurso no existe');      // 404
throw new ConflictError('Email ya existe');        // 409
throw new BusinessRuleError('Regla violada');      // 422
```

**Handler de Errores:**
```typescript
import { handleApiError } from '@/lib/errors';

try {
  // ... código
} catch (error) {
  const apiError = handleApiError(error);
  return NextResponse.json(
    { error: apiError.message },
    { status: apiError.statusCode }
  );
}
```

---

## 🔄 Flujo de Datos

### Lectura (GET)
```
Usuario hace request
    ↓
📄 API Route (app/api/teams/route.ts)
    │ - Verifica autenticación
    │ - Extrae session.user.id
    ↓
🧩 Service (lib/services-server/teams.service.ts)
    │ - Valida userId
    │ - Aplica reglas de negocio
    ↓
💾 Repository (lib/repositories/teams.repository.ts)
    │ - Ejecuta query con Prisma
    ↓
🗄️ MySQL Database
    │ - Retorna datos
    ↓
📄 API Route retorna JSON
```

### Escritura (POST/PATCH)
```
Usuario envía datos
    ↓
📄 API Route (app/api/teams/route.ts)
    │ - Verifica autenticación
    │ - Extrae datos del request body
    ↓
🧩 Service (lib/services-server/teams.service.ts)
    │ 1. Valida datos (formato, longitud, tipo)
    │ 2. Sanitiza (trim, escape)
    │ 3. Verifica autorización (belongsToUser)
    │ 4. Aplica reglas de negocio
    │ 5. Inicia transacción si es necesario
    ↓
💾 Repository (lib/repositories/teams.repository.ts)
    │ - Ejecuta INSERT/UPDATE con Prisma
    ↓
🗄️ MySQL Database
    │ - Persiste cambios
    ↓
💾 Repository retorna objeto creado/actualizado
    ↓
🧩 Service transforma datos (opcional)
    ↓
📄 API Route retorna JSON
```

---

## 📏 Convenciones de Código

### Naming Conventions

#### Servicios
```typescript
// ✅ CORRECTO
class TeamsService {
  static async getUserTeams(userId: string) { ... }
  static async createTeam(userId: string, name: string) { ... }
}

// ❌ INCORRECTO
class TeamService { ... }  // No plural
async getTeams() { ... }  // No especifica "user"
```

#### Repositorios
```typescript
// ✅ CORRECTO
class TeamsRepository {
  static async findById(id: string) { ... }
  static async findMany(filters: TeamFilters) { ... }
  static async create(data: CreateTeamInput) { ... }
  static async update(id: string, data: UpdateTeamInput) { ... }
  static async delete(id: string) { ... }
}

// ❌ INCORRECTO
async getTeam(id: string) { ... }  // Usar "findById"
async save(data) { ... }  // Usar "create" o "update"
```

### TypeScript Best Practices

```typescript
// ✅ CORRECTO - Tipos explícitos
async function getUserTeams(userId: string): Promise<Team[]> {
  const teams = await TeamsRepository.findByUserId(userId);
  return teams;
}

// ❌ INCORRECTO - Inferencia implícita
async function getUserTeams(userId) {
  return await TeamsRepository.findByUserId(userId);
}
```

### Error Handling

```typescript
// ✅ CORRECTO - Errores tipados
if (!name || name.trim().length === 0) {
  throw new ValidationError('El nombre es requerido');
}

// ❌ INCORRECTO - Error genérico
if (!name) {
  throw new Error('Invalid name');
}
```

---

## 🆕 Creación de Nuevas Features

### Ejemplo: Agregar Sistema de Comentarios a Partidos

#### 1️⃣ Actualizar el Schema de Prisma
```prisma
// prisma/schema.prisma
model MatchComment {
  id        String   @id @default(cuid())
  matchId   String
  userId    String
  content   String   @db.Text
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  match Match @relation(fields: [matchId], references: [id], onDelete: Cascade)
  user  User  @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([matchId])
  @@index([userId])
  @@map("match_comments")
}
```

```bash
npx prisma migrate dev --name add_match_comments
```

#### 2️⃣ Crear el Repositorio
```typescript
// lib/repositories/comments.repository.ts
import { prisma } from '@/lib/prisma';

export class CommentsRepository {
  static async findByMatchId(matchId: string) {
    return await prisma.matchComment.findMany({
      where: { matchId },
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  static async create(data: {
    matchId: string;
    userId: string;
    content: string;
  }) {
    return await prisma.matchComment.create({
      data,
      include: {
        user: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });
  }

  static async delete(id: string) {
    return await prisma.matchComment.delete({
      where: { id },
    });
  }

  static async belongsToUser(commentId: string, userId: string): Promise<boolean> {
    const comment = await prisma.matchComment.findUnique({
      where: { id: commentId },
      select: { userId: true },
    });
    return comment?.userId === userId;
  }
}
```

#### 3️⃣ Crear el Servicio
```typescript
// lib/services-server/comments.service.ts
import { CommentsRepository, MatchesRepository } from '@/lib/repositories';
import { ValidationError, UnauthorizedError, BusinessRuleError } from '@/lib/errors';

export class CommentsService {
  static async getMatchComments(matchId: string, userId: string) {
    // Verificar que el usuario participa en el partido
    const participates = await MatchesRepository.userParticipates(matchId, userId);
    if (!participates) {
      throw new UnauthorizedError('No tienes acceso a este partido');
    }

    return await CommentsRepository.findByMatchId(matchId);
  }

  static async createComment(
    matchId: string,
    userId: string,
    content: string
  ) {
    // Validar contenido
    if (!content || content.trim().length === 0) {
      throw new ValidationError('El comentario no puede estar vacío');
    }
    if (content.length > 500) {
      throw new ValidationError('El comentario no puede exceder 500 caracteres');
    }

    // Verificar que el usuario participa en el partido
    const participates = await MatchesRepository.userParticipates(matchId, userId);
    if (!participates) {
      throw new UnauthorizedError('Solo puedes comentar en tus partidos');
    }

    // Verificar que el partido existe
    const match = await MatchesRepository.findById(matchId);
    if (!match) {
      throw new ValidationError('Partido no encontrado');
    }

    return await CommentsRepository.create({
      matchId,
      userId,
      content: content.trim(),
    });
  }

  static async deleteComment(commentId: string, userId: string) {
    const belongs = await CommentsRepository.belongsToUser(commentId, userId);
    if (!belongs) {
      throw new UnauthorizedError('No puedes eliminar este comentario');
    }

    return await CommentsRepository.delete(commentId);
  }
}
```

#### 4️⃣ Crear las API Routes
```typescript
// app/api/matches/[id]/comments/route.ts
import { getServerSession } from 'next-auth';
import { NextResponse } from 'next/server';
import { authOptions } from '@/lib/auth';
import { CommentsService } from '@/lib/services-server/comments.service';
import { handleApiError } from '@/lib/errors';

export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const comments = await CommentsService.getMatchComments(
      params.id,
      session.user.id
    );

    return NextResponse.json(comments);
  } catch (error) {
    const apiError = handleApiError(error);
    return NextResponse.json(
      { error: apiError.message },
      { status: apiError.statusCode }
    );
  }
}

export async function POST(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }

    const { content } = await request.json();

    const comment = await CommentsService.createComment(
      params.id,
      session.user.id,
      content
    );

    return NextResponse.json(comment, { status: 201 });
  } catch (error) {
    const apiError = handleApiError(error);
    return NextResponse.json(
      { error: apiError.message },
      { status: apiError.statusCode }
    );
  }
}
```

#### 5️⃣ Actualizar el Index de Repositorios
```typescript
// lib/repositories/index.ts
export { CommentsRepository } from './comments.repository';
```

#### 6️⃣ Actualizar el Index de Servicios
```typescript
// lib/services-server/index.ts
export { CommentsService } from './comments.service';
```

---

## 🧪 Guía de Testing

### Testing de Repositorios (Integración)
```typescript
// __tests__/repositories/teams.repository.test.ts
import { TeamsRepository } from '@/lib/repositories';
import { prisma } from '@/lib/prisma';

beforeEach(async () => {
  await prisma.team.deleteMany();
});

describe('TeamsRepository', () => {
  it('debería crear un equipo', async () => {
    const team = await TeamsRepository.create({
      userId: 'user-123',
      name: 'Equipo Test',
    });

    expect(team).toHaveProperty('id');
    expect(team.name).toBe('Equipo Test');
    expect(team.userId).toBe('user-123');
  });

  it('debería encontrar equipos por userId', async () => {
    await TeamsRepository.create({ userId: 'user-123', name: 'Equipo 1' });
    await TeamsRepository.create({ userId: 'user-123', name: 'Equipo 2' });

    const teams = await TeamsRepository.findByUserId('user-123');

    expect(teams).toHaveLength(2);
  });
});
```

### Testing de Servicios (Unitario)
```typescript
// __tests__/services/teams.service.test.ts
import { TeamsService } from '@/lib/services-server';
import { TeamsRepository } from '@/lib/repositories';
import { ValidationError } from '@/lib/errors';

jest.mock('@/lib/repositories');

describe('TeamsService', () => {
  it('debería lanzar ValidationError si el nombre está vacío', async () => {
    await expect(
      TeamsService.createTeam('user-123', '')
    ).rejects.toThrow(ValidationError);
  });

  it('debería sanitizar el nombre', async () => {
    (TeamsRepository.create as jest.Mock).mockResolvedValue({
      id: 'team-123',
      name: 'Mi Equipo',
      userId: 'user-123',
    });

    await TeamsService.createTeam('user-123', '  Mi Equipo  ');

    expect(TeamsRepository.create).toHaveBeenCalledWith({
      userId: 'user-123',
      name: 'Mi Equipo',
    });
  });
});
```

---

## 🐛 Troubleshooting

### Error: "Prisma Client not found"
```bash
npx prisma generate
```

### Error: "Port 3000 already in use"
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:3000 | xargs kill -9
```

### Error: "Cannot connect to MySQL"
```bash
# Verificar que MySQL está corriendo
# Windows
net start MySQL80

# Linux
sudo systemctl start mysql

# Verificar .env
# DATABASE_URL="mysql://user:password@localhost:3306/amistoso_ter"
```

### Error: "Prisma schema validation errors"
```bash
npx prisma validate
npx prisma format
```

---

## 📚 Recursos Adicionales

- [Next.js App Router](https://nextjs.org/docs/app)
- [Prisma Documentation](https://www.prisma.io/docs)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)

---

**Última actualización:** [Fecha]  
**Versión:** 1.0.0
