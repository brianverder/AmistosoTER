# ============================================
# GUÍA COMPLETA DE CONEXIÓN MYSQL
# ============================================

## 📦 INSTALACIÓN DE DEPENDENCIAS

Para usar MySQL en tu proyecto Next.js, necesitas instalar:

```bash
# Si usas Prisma (RECOMENDADO)
npm install @prisma/client
npm install -D prisma

# Si necesitas queries SQL directas (OPCIONAL)
npm install mysql2

# Para validación y seguridad
npm install zod
```

---

## 📁 ESTRUCTURA DE ARCHIVOS CREADOS

```
lib/
├── prisma.ts                    # ✅ Conexión Prisma (RECOMENDADO)
├── mysql.ts                     # ⚡ Conexión directa mysql2 (OPCIONAL)
├── security.ts                  # 🔒 Validación y seguridad
└── examples/
    └── database-usage.ts        # 📚 Ejemplos completos de uso

.env                             # Variables de entorno (NO commitear)
.env.example                     # Template de variables
```

---

## 🚀 QUICK START

### Paso 1: Configurar Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto:

```env
# Conexión a MySQL
DATABASE_URL="mysql://usuario:password@localhost:3306/amistoso_ter_db"

# NextAuth (si ya lo tienes)
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="tu-secreto-aqui"
```

### Paso 2: Usar Prisma (Opción Recomendada)

```typescript
// En cualquier archivo de tu proyecto
import { prisma } from '@/lib/prisma';

// SELECT
const teams = await prisma.team.findMany();

// INSERT
const team = await prisma.team.create({
  data: {
    name: 'Mi Equipo',
    userId: userId,
  },
});

// UPDATE
await prisma.team.update({
  where: { id: teamId },
  data: { name: 'Nuevo Nombre' },
});

// DELETE
await prisma.team.delete({
  where: { id: teamId },
});
```

### Paso 3: Usar Queries SQL Directas (Opcional)

Solo si Prisma no es suficiente para tu caso:

```typescript
import { query, queryOne, transaction } from '@/lib/mysql';

// SELECT
const teams = await query('SELECT * FROM teams WHERE user_id = ?', [userId]);

// INSERT
await query('INSERT INTO teams (name, user_id) VALUES (?, ?)', ['Equipo', userId]);

// Transacción
await transaction(async (conn) => {
  await conn.execute('INSERT INTO ...');
  await conn.execute('UPDATE ...');
});
```

---

## 📖 EJEMPLOS DE USO

### Ejemplo 1: API Route con Prisma

**Archivo: `app/api/teams/route.ts`**

```typescript
import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { handleApiError } from '@/lib/security';

export async function GET() {
  try {
    const session = await getServerSession(authOptions);
    
    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }
    
    const teams = await prisma.team.findMany({
      where: { userId: session.user.id },
      orderBy: { createdAt: 'desc' },
    });
    
    return NextResponse.json(teams);
  } catch (error) {
    const { message, status } = handleApiError(error);
    return NextResponse.json({ error: message }, { status });
  }
}

export async function POST(request: Request) {
  try {
    const session = await getServerSession(authOptions);
    
    if (!session?.user) {
      return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
    }
    
    const { name } = await request.json();
    
    if (!name || name.trim().length === 0) {
      return NextResponse.json({ error: 'Nombre requerido' }, { status: 400 });
    }
    
    const team = await prisma.team.create({
      data: {
        name: name.trim(),
        userId: session.user.id,
      },
    });
    
    return NextResponse.json(team, { status: 201 });
  } catch (error) {
    const { message, status } = handleApiError(error);
    return NextResponse.json({ error: message }, { status });
  }
}
```

---

### Ejemplo 2: Server Action con Prisma

**Archivo: `app/actions/teams.ts`**

```typescript
'use server';

import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { revalidatePath } from 'next/cache';
import { createTeamSchema, validateData } from '@/lib/security';

export async function createTeamAction(formData: FormData) {
  try {
    // Autenticación
    const session = await getServerSession(authOptions);
    if (!session?.user) {
      return { error: 'No autenticado' };
    }
    
    // Validación
    const data = {
      name: formData.get('name') as string,
      description: formData.get('description') as string,
    };
    
    const validatedData = validateData(createTeamSchema, data);
    
    // Crear equipo
    const team = await prisma.team.create({
      data: {
        ...validatedData,
        userId: session.user.id,
      },
    });
    
    // Revalidar cache
    revalidatePath('/dashboard/teams');
    
    return { success: true, team };
  } catch (error) {
    console.error('Error:', error);
    return { error: 'Error al crear equipo' };
  }
}
```

---

### Ejemplo 3: Transacciones Complejas

```typescript
import { executeTransaction } from '@/lib/prisma';

export async function createMatchWithResult(matchData: any, resultData: any) {
  try {
    const result = await executeTransaction(async (tx) => {
      // Crear partido
      const match = await tx.match.create({
        data: matchData,
      });
      
      // Crear resultado
      const matchResult = await tx.matchResult.create({
        data: {
          ...resultData,
          matchId: match.id,
        },
      });
      
      // Actualizar solicitud
      await tx.matchRequest.update({
        where: { id: matchData.matchRequestId },
        data: { status: 'matched' },
      });
      
      // Si todo sale bien, se hace COMMIT automático
      return { match, matchResult };
    });
    
    return result;
  } catch (error) {
    // Si algo falla, se hace ROLLBACK automático
    console.error('Error en transacción:', error);
    throw error;
  }
}
```

---

### Ejemplo 4: Validación con Zod

```typescript
import { createTeamSchema, safeValidateData } from '@/lib/security';

export async function POST(request: Request) {
  const body = await request.json();
  
  // Validación segura
  const validation = safeValidateData(createTeamSchema, body);
  
  if (!validation.success) {
    return NextResponse.json(
      { error: 'Validación fallida', details: validation.errors },
      { status: 400 }
    );
  }
  
  // Usar datos validados
  const team = await prisma.team.create({
    data: validation.data,
  });
  
  return NextResponse.json(team);
}
```

---

## 🔒 SEGURIDAD

### ✅ Buenas Prácticas Implementadas

1. **Queries Parametrizadas**: Prisma las usa automáticamente
2. **Validación de Entrada**: Uso de Zod schemas
3. **Rate Limiting**: Implementado en `lib/security.ts`
4. **Manejo de Errores**: Función centralizada `handleApiError`
5. **Autenticación**: Verificación de sesión en cada endpoint
6. **Sanitización**: Funciones para limpiar strings
7. **Connection Pooling**: Evita múltiples conexiones

### ⚠️ Evitar

```typescript
// ❌ NUNCA hacer esto (SQL injection vulnerable)
const teams = await query(`SELECT * FROM teams WHERE name = '${userInput}'`);

// ✅ HACER esto (seguro)
const teams = await query('SELECT * FROM teams WHERE name = ?', [userInput]);

// ✅ O mejor aún, usar Prisma
const teams = await prisma.team.findMany({
  where: { name: userInput },
});
```

---

## 🧪 TESTING DE CONEXIÓN

Crea un endpoint de prueba:

**Archivo: `app/api/health/route.ts`**

```typescript
import { NextResponse } from 'next/server';
import { checkDatabaseConnection } from '@/lib/prisma';

export async function GET() {
  const isConnected = await checkDatabaseConnection();
  
  if (isConnected) {
    return NextResponse.json({ 
      status: 'ok', 
      database: 'connected' 
    });
  } else {
    return NextResponse.json(
      { status: 'error', database: 'disconnected' },
      { status: 500 }
    );
  }
}
```

Luego visita: `http://localhost:3000/api/health`

---

## 🔧 TROUBLESHOOTING

### Error: "Can't connect to MySQL server"

```bash
# Verificar que MySQL está corriendo
mysql -u root -p

# Verificar variables de entorno
echo $DATABASE_URL
```

### Error: "Client does not support authentication protocol"

```sql
-- En MySQL, ejecutar:
ALTER USER 'usuario'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
FLUSH PRIVILEGES;
```

### Error: "Too many connections"

Ajustar en `DATABASE_URL`:
```
DATABASE_URL="mysql://user:pass@host:3306/db?connection_limit=5"
```

### Error: "Access denied"

Verificar permisos:
```sql
GRANT ALL PRIVILEGES ON amistoso_ter_db.* TO 'amistoso_app'@'localhost';
FLUSH PRIVILEGES;
```

---

## 📊 MONITORING

### Ver queries ejecutadas (desarrollo)

Prisma ya registra queries en desarrollo. Para ver más detalles:

```typescript
// En lib/prisma.ts, ya está configurado:
log: process.env.NODE_ENV === 'development' 
  ? ['query', 'error', 'warn']
  : ['error']
```

### Obtener estadísticas de la BD

```typescript
import { getDatabaseStats } from '@/lib/prisma';

const stats = await getDatabaseStats();
console.log('Estadísticas de tablas:', stats);
```

---

## 🚀 DEPLOY A PRODUCCIÓN

### Checklist antes de deploy:

- [ ] Cambiar `DATABASE_URL` a servidor de producción
- [ ] Usar `NODE_ENV=production`
- [ ] Configurar SSL en conexión MySQL
- [ ] Ajustar `connection_limit` según servidor
- [ ] Configurar backups automáticos
- [ ] Deshabilitar logs de queries
- [ ] Configurar monitoreo

### Variables de entorno en Vercel:

```bash
# En Vercel Dashboard > Settings > Environment Variables

DATABASE_URL = mysql://user:pass@host:3306/db?ssl=true
NEXTAUTH_URL = https://tudominio.com
NEXTAUTH_SECRET = [secreto-seguro]
NODE_ENV = production
```

---

## 📚 RECURSOS ADICIONALES

- 📘 [Prisma MySQL Guide](https://www.prisma.io/docs/concepts/database-connectors/mysql)
- 📘 [mysql2 Documentation](https://github.com/sidorares/node-mysql2)
- 📘 [Zod Documentation](https://zod.dev)
- 🎓 [Next.js API Routes](https://nextjs.org/docs/app/building-your-application/routing/route-handlers)
- 🎓 [Server Actions](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)

---

## ✅ RESUMEN

### Archivos Creados:

1. **`lib/prisma.ts`** - Conexión Prisma optimizada (USAR ESTE)
2. **`lib/mysql.ts`** - Conexión directa mysql2 (opcional)
3. **`lib/security.ts`** - Validación y seguridad
4. **`lib/examples/database-usage.ts`** - Ejemplos completos

### Uso Recomendado:

```typescript
// Import principal
import { prisma } from '@/lib/prisma';

// Para queries normales
const data = await prisma.table.findMany();

// Para transacciones
import { executeTransaction } from '@/lib/prisma';

// Para validación
import { validateData, createTeamSchema } from '@/lib/security';

// Para manejo de errores
import { handleApiError } from '@/lib/security';
```

### Próximos Pasos:

1. Configurar `.env` con tu `DATABASE_URL`
2. Ejecutar `npx prisma generate` si usas Prisma
3. Probar conexión con endpoint `/api/health`
4. Implementar tus endpoints usando los ejemplos
5. Agregar validación con Zod en todos los endpoints

---

**¿Necesitas ayuda?** Revisa los ejemplos en `lib/examples/database-usage.ts`
