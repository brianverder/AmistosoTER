# 🚀 GUÍA DE DESPLIEGUE A PRODUCCIÓN

## 📋 PREPARACIÓN

### 1. Elegir Base de Datos

Tu app actualmente usa **SQLite** (archivo local) que NO sirve para producción.
Debes migrar a una base de datos real:

#### OPCIÓN A: PostgreSQL (Recomendada ⭐)
- **Vercel Postgres**: Gratis, integrado con Vercel
- **Supabase**: Gratis + incluye autenticación
- **Neon**: Gratis con serverless Postgres
- **Railway**: $5/mes, muy fácil de usar

#### OPCIÓN B: MySQL
- **PlanetScale**: Gratis con branching de base de datos
- **MySQL tradicional**: En tu hosting compartido

#### OPCIÓN C: MongoDB
- **MongoDB Atlas**: Gratis hasta 512MB

---

## 🔧 PASOS PARA DESPLEGAR

### PASO 1: Configurar Base de Datos en Producción

#### Ejemplo con Supabase (PostgreSQL):

1. Ve a https://supabase.com
2. Crea un proyecto gratis
3. En "Settings" → "Database", copia la cadena de conexión
4. Guárdala para el siguiente paso

```bash
# Tu cadena se verá así:
postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres
```

---

### PASO 2: Actualizar schema.prisma

Abre `prisma/schema.prisma` y cambia:

```prisma
datasource db {
  provider = "postgresql"  // Cambiar de "sqlite" a "postgresql"
  url      = env("DATABASE_URL")
}
```

---

### PASO 3: Migrar Datos (si tienes datos de prueba)

Si quieres conservar tus datos de desarrollo:

```bash
# 1. Generar migraciones
npx prisma migrate dev --name init

# 2. Exportar datos (manual o usar Prisma Studio)
npx prisma studio
```

**Nota**: Normalmente en producción empiezas con base de datos limpia.

---

### PASO 4: Desplegar en Hosting

#### OPCIÓN A: Vercel (Recomendado - Gratis)

1. Instala Vercel CLI:
```bash
npm i -g vercel
```

2. Conecta tu proyecto:
```bash
vercel login
vercel
```

3. Añade variables de entorno en Vercel Dashboard:
   - `DATABASE_URL`: Tu cadena de PostgreSQL
   - `NEXTAUTH_URL`: https://tu-proyecto.vercel.app
   - `NEXTAUTH_SECRET`: Genera uno con: `openssl rand -base64 32`

4. Ejecuta migraciones en producción:
```bash
# En tu terminal local, con DATABASE_URL de producción:
npx prisma migrate deploy
```

#### OPCIÓN B: Hosting Tradicional (cPanel, etc.)

1. Requisitos:
   - Node.js 18+ instalado
   - Acceso a SSH
   - Base de datos MySQL/PostgreSQL

2. Build del proyecto:
```bash
npm run build
```

3. Sube estos archivos:
   - `.next/` (carpeta completa)
   - `node_modules/`
   - `public/`
   - `prisma/`
   - `package.json`
   - `.env.production` (con tus variables)

4. Ejecuta en servidor:
```bash
npm run start
```

#### OPCIÓN C: Railway (Muy Fácil - $5/mes)

1. Ve a https://railway.app
2. Conecta tu repositorio de GitHub
3. Railway detecta Next.js automáticamente
4. Añade PostgreSQL desde el dashboard
5. Railway configura DATABASE_URL automáticamente
6. Añade otras variables: NEXTAUTH_URL, NEXTAUTH_SECRET

---

## 🔐 SEGURIDAD DE USUARIOS

### Cómo se guardan los usuarios:

Tu app ya implementa **buenas prácticas**:

```typescript
// Registro (app/api/auth/register/route.ts)
import bcrypt from 'bcryptjs';

const hashedPassword = await bcrypt.hash(password, 10);
await prisma.user.create({
  data: {
    email,
    password: hashedPassword,  // ✅ Nunca se guarda la contraseña original
    name,
    phone,
  },
});
```

```typescript
// Login (lib/auth.ts con NextAuth)
const user = await prisma.user.findUnique({ where: { email } });
const isValid = await bcrypt.compare(credentials.password, user.password);
// ✅ Se compara el hash, no la contraseña real
```

### Datos que se guardan en la base de datos:

| Campo | Tipo | Seguridad |
|-------|------|-----------|
| `id` | String (cuid) | Generado automáticamente |
| `email` | String | Texto plano (necesario para login) |
| `password` | String | **Hasheado con bcrypt** ✅ |
| `name` | String | Texto plano |
| `phone` | String | Texto plano (opcional) |

---

## 📊 ESTRUCTURA DE DATOS EN PRODUCCIÓN

Tu base de datos tendrá estas tablas:

- **User**: Usuarios registrados
- **Team**: Equipos creados por usuarios
- **MatchRequest**: Solicitudes publicadas
- **Match**: Partidos confirmados
- **MatchResult**: Resultados de partidos

**Prisma** se encarga de:
- ✅ Crear las tablas automáticamente
- ✅ Manejar relaciones entre tablas
- ✅ Validar tipos de datos
- ✅ Realizar queries seguras (previene SQL injection)

---

## 🔄 MIGRACIÓN DE SQLite A POSTGRESQL

### Script para cambiar de base de datos:

```bash
# 1. Detener servidor de desarrollo
# 2. Actualizar schema.prisma (cambiar provider)
# 3. Configurar nueva DATABASE_URL

# 4. Generar migración inicial
npx prisma migrate dev --name initial_production_migration

# 5. Aplicar a producción
DATABASE_URL="tu-url-de-produccion" npx prisma migrate deploy

# 6. Generar cliente de Prisma
npx prisma generate
```

---

## ✅ CHECKLIST ANTES DE DESPLEGAR

- [ ] Cambiar `provider` en schema.prisma a "postgresql"
- [ ] Configurar DATABASE_URL de producción
- [ ] Generar NEXTAUTH_SECRET aleatorio seguro
- [ ] Actualizar NEXTAUTH_URL con tu dominio real
- [ ] Ejecutar `npx prisma migrate deploy` en producción
- [ ] Verificar que las variables de entorno están configuradas
- [ ] Probar registro de usuarios
- [ ] Probar login
- [ ] Probar creación de equipos y solicitudes
- [ ] Verificar que las imágenes externas cargan (next.config.js)

---

## 🆘 PROBLEMAS COMUNES

### Error: "Can't reach database server"
- Verifica que DATABASE_URL es correcta
- Revisa whitelist de IPs en tu proveedor de base de datos
- Algunos proveedores requieren SSL: añade `?sslmode=require`

### Error: "Table doesn't exist"
- Ejecuta: `npx prisma migrate deploy`
- Verifica que las migraciones se aplicaron correctamente

### Usuarios no pueden registrarse
- Verifica que NEXTAUTH_SECRET está configurado
- Revisa los logs del servidor
- Confirma que la tabla User existe en la base de datos

---

## 📚 RECURSOS

- Prisma Docs: https://www.prisma.io/docs
- Next.js Deployment: https://nextjs.org/docs/deployment
- NextAuth.js: https://next-auth.js.org/deployment
- Vercel Dashboard: https://vercel.com/dashboard

---

## 💡 RECOMENDACIÓN FINAL

Para tu caso, te recomiendo:

1. **Hosting**: Vercel (gratis, optimizado para Next.js)
2. **Base de datos**: Supabase (gratis, PostgreSQL, fácil)
3. **Pasos**:
   - Sube tu repo a GitHub
   - Conecta GitHub con Vercel
   - Crea base de datos en Supabase
   - Configura variables en Vercel
   - Deploy automático ✅

**Tiempo estimado**: 30-45 minutos para el primer despliegue.
