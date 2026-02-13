# 🔐 Mejores Prácticas de Seguridad
**Guía para desarrollo seguro en Amistoso TER Web**

---

## 📋 Tabla de Contenidos

1. [Seguridad en Base de Datos](#seguridad-en-base-de-datos)
2. [Validación de Inputs](#validación-de-inputs)
3. [Autenticación y Autorización](#autenticación-y-autorización)
4. [Protección contra Ataques](#protección-contra-ataques)
5. [Configuración de Producción](#configuración-de-producción)
6. [Monitoring y Logging](#monitoring-y-logging)

---

## 🗄️ Seguridad en Base de Datos

### ✅ DO: Usar Prisma Client (preferido)

```typescript
// ✅ CORRECTO: Prisma escapa automáticamente
const teams = await prisma.team.findMany({
  where: {
    name: {
      contains: userInput, // Prisma escapa automáticamente
    },
  },
});
```

### ✅ DO: Raw SQL con Tagged Templates

```typescript
// ✅ CORRECTO: Usar tagged template literals
const results = await prisma.$queryRaw`
  SELECT * FROM teams 
  WHERE name LIKE CONCAT('%', ${searchTerm}, '%')
`;
```

### ❌ DON'T: Concatenación de Strings en SQL

```typescript
// ❌ INCORRECTO: SQL Injection vulnerability
const query = `SELECT * FROM teams WHERE name LIKE '%${userInput}%'`;
const results = await prisma.$queryRawUnsafe(query);
```

### 🛡️ Escapar Wildcards en LIKE

```typescript
// Escapar caracteres especiales de SQL: %, _, \
function escapeSqlLike(input: string): string {
  return input.replace(/[%_\\]/g, '\\$&');
}

const sanitized = escapeSqlLike(userInput);
const results = await prisma.$queryRaw`
  WHERE field LIKE CONCAT('%', ${sanitized}, '%')
`;
```

---

## ✅ Validación de Inputs

### Usar lib/validation.ts

Todos los inputs de usuario deben pasar por validación:

```typescript
import { validateEmail, validateName } from '@/lib/validation';

// ✅ CORRECTO
const emailValidation = validateEmail(userEmail);
if (!emailValidation.isValid) {
  return res.status(400).json({ error: emailValidation.error });
}

const sanitizedEmail = emailValidation.sanitized;
```

### Reglas de Validación

| Campo | Reglas | Longitud |
|-------|--------|----------|
| Email | RFC 5322 format, lowercase | max 255 |
| Password | Min 8 chars, 1 uppercase, 1 number | 8-72 |
| Name | Letras, espacios, tildes | 2-255 |
| Phone | Números, espacios, guiones | 7-50 |
| Text | Sin HTML tags, sin scripts | max 500 |
| Price | Número positivo | 0-1000000 |

### ❌ Nunca Confiar en Input del Cliente

```typescript
// ❌ INCORRECTO
const { isAdmin } = req.body;
await prisma.user.update({
  data: { isAdmin }, // Usuario podría escalar privilegios
});

// ✅ CORRECTO
// Solo permitir campos que el usuario debería modificar
const { name, phone } = validateUserUpdate(req.body);
await prisma.user.update({
  data: { name, phone }, // Campos controlados
});
```

---

## 🔐 Autenticación y Autorización

### Passwords

```typescript
import { hash, compare } from 'bcryptjs';

// ✅ Hash con 12 rounds (balance seguridad/performance)
const hashedPassword = await hash(password, 12);

// ✅ Verificar password de forma segura
const isValid = await compare(password, user.password);
```

### Session Management

```typescript
// ✅ JWT con tiempo de expiración
jwt: {
  maxAge: 30 * 24 * 60 * 60, // 30 días
},

// ✅ Rotación de tokens
callbacks: {
  async jwt({ token, user }) {
    if (user) {
      token.id = user.id;
      token.issuedAt = Date.now();
    }
    return token;
  },
}
```

### Rate Limiting de Auth

```typescript
// Ya implementado en lib/rate-limit.ts
'/api/auth/register': {
  windowMs: 15 * 60 * 1000, // 15 minutos
  maxRequests: 5,           // Solo 5 registros por IP
}
```

---

## 🛡️ Protección contra Ataques

### 1. SQL Injection

**Prevención:**
- ✅ Usar Prisma Client
- ✅ Si usas raw SQL, tagged templates
- ✅ Escapar wildcards en LIKE
- ❌ NUNCA usar `$queryRawUnsafe` con input de usuario

### 2. XSS (Cross-Site Scripting)

**Prevención:**
- ✅ Sanitizar inputs con `lib/validation.ts`
- ✅ React escapa automáticamente en JSX
- ✅ Usar CSP headers (configurado en next.config.mjs)
- ❌ NUNCA usar `dangerouslySetInnerHTML` con input de usuario

```typescript
// ✅ CORRECTO: Sanitizar antes de guardar
import { sanitizeString } from '@/lib/validation';
const cleanText = sanitizeString(userInput);
```

### 3. CSRF (Cross-Site Request Forgery)

**Prevención:**
- ✅ NextAuth incluye protección CSRF automática
- ✅ SameSite cookies configuradas
- ✅ Verificar origin en requests críticas

### 4. Information Disclosure

```typescript
// ❌ INCORRECTO: Revela si email existe
if (existingUser) {
  return res.json({ error: 'Email ya registrado' });
}

// ✅ CORRECTO: Mensaje genérico
if (existingUser) {
  await delay(100); // Prevenir timing attacks
  return res.json({ error: 'No se pudo completar el registro' });
}
```

### 5. Timing Attacks

```typescript
// ✅ Agregar delay artificial en operaciones sensibles
async function safeCheckEmail(email: string) {
  const user = await prisma.user.findUnique({ where: { email } });
  
  // Delay constante independiente del resultado
  await new Promise(resolve => setTimeout(resolve, 100));
  
  return user;
}
```

### 6. Brute Force

**Prevención:**
- ✅ Rate limiting implementado (lib/rate-limit.ts)
- ✅ Límites por IP y por endpoint
- ⏳ TODO: Implementar account lockout después de N intentos
- ⏳ TODO: CAPTCHA en registro y login

---

## ⚙️ Configuración de Producción

### Variables de Entorno

```bash
# ✅ OBLIGATORIO cambiar en producción
NEXTAUTH_SECRET="<usar openssl rand -base64 32>"

# ✅ SSL obligatorio
DATABASE_URL="mysql://...?ssl=true&sslaccept=strict"

# ✅ Connection pooling configurado
DATABASE_URL="...?connection_limit=20&pool_timeout=30"
```

### Security Headers

Ya configurados en `next.config.mjs`:
- ✅ X-Frame-Options: DENY
- ✅ X-Content-Type-Options: nosniff
- ✅ X-XSS-Protection: 1; mode=block
- ✅ Content-Security-Policy
- ✅ Strict-Transport-Security (HSTS)
- ✅ Referrer-Policy

### HTTPS

```typescript
// ✅ Forzar HTTPS en producción
if (process.env.NODE_ENV === 'production' && req.protocol !== 'https') {
  return res.redirect(301, `https://${req.hostname}${req.url}`);
}
```

---

## 📊 Monitoring y Logging

### Logging Seguro

```typescript
// ❌ INCORRECTO: Loggea password
console.log('User data:', userData);

// ✅ CORRECTO: Excluir datos sensibles
const { password, ...safeData } = userData;
console.log('User data:', safeData);
```

### Logs de Seguridad

**Registrar eventos:**
- ✅ Intentos de login fallidos
- ✅ Cambios de password
- ✅ Rate limiting triggered
- ✅ Errores de autenticación
- ✅ Accesos a recursos protegidos

```typescript
// Ejemplo de log seguro
logger.warn({
  event: 'FAILED_LOGIN_ATTEMPT',
  ip: getClientIp(req),
  email: email.substring(0, 3) + '***', // Ofuscar email
  timestamp: new Date().toISOString(),
});
```

### Monitoring Recomendado

**Herramientas:**
- 🔹 Sentry - Error tracking
- 🔹 LogRocket - Session replay
- 🔹 Datadog - Infrastructure monitoring
- 🔹 New Relic - APM
- 🔹 Cloudflare - WAF + DDoS protection

---

## 🚀 Checklist de Despliegue

Antes de desplegar a producción:

### Base de Datos
- [x] Schema usa MySQL (no SQLite)
- [x] Todos los índices creados
- [x] ENUMs definidos para status
- [ ] SSL configurado en connection string
- [ ] Connection pooling configurado (10-20 conexiones)
- [ ] Backups automáticos configurados

### Seguridad
- [x] Rate limiting activo
- [x] Input validation en todos los endpoints
- [x] SQL queries escapadas correctamente
- [x] Security headers configurados
- [ ] NEXTAUTH_SECRET único generado
- [ ] SSL/HTTPS obligatorio
- [ ] CORS configurado para dominios específicos

### Código
- [ ] Tests de seguridad pasando
- [ ] npm audit sin vulnerabilidades HIGH/CRITICAL
- [ ] Dependencias actualizadas
- [ ] Código sin console.logs de desarrollo
- [ ] Variables de entorno de producción configuradas

### Infraestructura
- [ ] CDN configurado (Cloudflare/Vercel Edge)
- [ ] WAF activo
- [ ] Monitoring configurado (Sentry)
- [ ] Logging centralizado
- [ ] Health checks configurados
- [ ] Alertas de uptime

---

## 📚 Referencias

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [Prisma Security Best Practices](https://www.prisma.io/docs/guides/performance-and-optimization/query-optimization-performance)
- [Next.js Security](https://nextjs.org/docs/advanced-features/security-headers)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)

---

**Última actualización:** Febrero 2026  
**Mantenido por:** Equipo de Desarrollo Amistoso TER Web
