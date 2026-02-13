# Módulo de Creación de Solicitudes de Partidos

## 📋 Descripción General

El módulo de creación de solicitudes permite a los usuarios publicar partidos amistosos para encontrar rivales. Todos los campos son opcionales excepto el equipo solicitante.

## 🎨 Características Principales

### Formulario de Nueva Solicitud

**Ubicación:** `/dashboard/requests/new`

**Campos del Formulario:**

1. **Equipo Solicitante** (Obligatorio)
   - Select con los equipos del usuario
   - Si no hay equipos, se muestra un mensaje para crear uno primero

2. **Tipo de Fútbol** (Opcional)
   - Fútbol 11
   - Fútbol 8
   - Fútbol 7
   - Fútbol 5
   - Otro

3. **Dirección de la Cancha** (Opcional)
   - Campo de texto libre
   - Placeholder: "Ej: Complejo Deportivo Norte, Calle Principal 123"

4. **Precio de la Cancha** (Opcional)
   - Campo numérico (acepta decimales)
   - Formato: $0.00

5. **Fecha y Hora del Partido** (Opcional)
   - Input datetime-local
   - Permite seleccionar fecha y hora

6. **Liga del Equipo** (Opcional)
   - Campo de texto libre
   - Placeholder: "Ej: Liga Amateur de Buenos Aires, Liga Barrial"
   - Ayuda a encontrar equipos de nivel similar

7. **Descripción Adicional** (Opcional)
   - Textarea para información extra
   - Placeholder: "Ej: Buscamos equipo de nivel competitivo para partido el sábado por la mañana"

### UI/UX

**Logo de Tercer Tiempo:**
- Ubicación: https://tercer-tiempo.com/images/logo_tercertiempoNegro.png
- Dimensiones: 60x60px en el header, 24x24px en consejos
- Se muestra en dos lugares:
  1. Header junto al título
  2. Sección de consejos

**Confirmación de Creación:**
- Mensaje de éxito animado (animate-pulse)
- Color verde (#22c55e - accent)
- Redirección automática después de 2 segundos
- Ícono: ✅

**Consejos en la Página:**
```
✓ Equipo: Es el único campo obligatorio
✓ Detalles completos: Cuanta más información proporciones, más fácil será encontrar rival
✓ Liga: Ayuda a encontrar equipos de nivel similar
✓ Contacto: Otros usuarios verán tu email y teléfono al hacer match
✓ Estado: Tu solicitud se publicará como "Activa" automáticamente
```

## 🗄️ Base de Datos

### Schema Prisma

```prisma
model MatchRequest {
  id          String    @id @default(cuid())
  userId      String    // Usuario que crea la solicitud
  teamId      String    // Equipo solicitante
  
  // Campos opcionales del partido
  footballType String?  // "11", "7", "5", "8", "otro"
  fieldAddress String?  // Dirección de la cancha
  fieldPrice   Float?   // Precio de la cancha
  matchDate    DateTime? // Fecha y hora del partido
  league       String?  // Liga en la que juega el equipo
  
  // Info adicional
  description  String?  // Descripción adicional
  status       String   @default("active") // "active", "matched", "cancelled", "completed"
  
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  user  User @relation(fields: [userId], references: [id], onDelete: Cascade)
  team  Team @relation(fields: [teamId], references: [id], onDelete: Cascade)
  match Match? // Relación 1-1 cuando se hace match

  @@index([userId])
  @@index([teamId])
  @@index([status])
}
```

### Estado Inicial

- **status:** "active" (configurado automáticamente)
- **userId:** ID del usuario autenticado (desde sesión)
- **teamId:** ID del equipo seleccionado
- **createdAt/updatedAt:** Timestamps automáticos

## 🔧 API

### POST /api/requests

**Descripción:** Crea una nueva solicitud de partido

**Headers:**
```json
{
  "Content-Type": "application/json"
}
```

**Body:**
```json
{
  "teamId": "string (requerido)",
  "footballType": "string | null",
  "fieldAddress": "string | null",
  "fieldPrice": "number | null",
  "matchDate": "string (ISO 8601) | null",
  "league": "string | null",
  "description": "string | null"
}
```

**Respuesta Exitosa (201):**
```json
{
  "id": "clxxx...",
  "userId": "clyyy...",
  "teamId": "clzzz...",
  "footballType": "11",
  "fieldAddress": "Complejo Deportivo Norte",
  "fieldPrice": 5000,
  "matchDate": "2026-02-15T18:00:00.000Z",
  "league": "Liga Amateur",
  "description": "Buscamos partido competitivo",
  "status": "active",
  "createdAt": "2026-02-11T14:30:00.000Z",
  "updatedAt": "2026-02-11T14:30:00.000Z",
  "team": {
    "id": "clzzz...",
    "name": "Los Cracks FC"
  }
}
```

**Errores:**

- **401 Unauthorized:** Usuario no autenticado
- **400 Bad Request:** 
  - TeamId no proporcionado
  - Equipo no pertenece al usuario

### Validaciones Backend

1. **Usuario Autenticado:**
   ```typescript
   const session = await getServerSession(authOptions);
   if (!session?.user) {
     return NextResponse.json({ error: 'No autorizado' }, { status: 401 });
   }
   ```

2. **Equipo Válido:**
   ```typescript
   const team = await prisma.team.findUnique({ where: { id: teamId } });
   if (!team || team.userId !== session.user.id) {
     return NextResponse.json({ error: 'Equipo no válido' }, { status: 400 });
   }
   ```

3. **Conversión de Tipos:**
   - fieldPrice: `parseFloat()` o null
   - matchDate: `new Date()` o null

## 📱 Páginas Relacionadas

### Lista de Solicitudes (`/dashboard/requests`)

Muestra los campos de liga en las tarjetas:

```tsx
{req.footballType && (
  <p>⚽ Tipo: Fútbol {req.footballType}</p>
)}
{req.league && (
  <p>🏆 Liga: {req.league}</p>
)}
{req.fieldAddress && (
  <p>📍 Lugar: {req.fieldAddress}</p>
)}
```

### Detalle de Solicitud (`/dashboard/requests/[id]`)

Muestra información completa incluyendo liga:

```tsx
{request.footballType && (
  <div>
    <span>⚽</span>
    <p className="font-semibold">Tipo de Fútbol</p>
    <p>Fútbol {request.footballType}</p>
  </div>
)}

{request.league && (
  <div>
    <span>🏆</span>
    <p className="font-semibold">Liga</p>
    <p>{request.league}</p>
  </div>
)}
```

## 🎯 Flujo de Usuario

1. **Acceso al Formulario:**
   - Desde dashboard: botón "Nueva Solicitud"
   - Desde lista de solicitudes: botón "➕ Nueva Solicitud"

2. **Creación de Solicitud:**
   ```
   Usuario → Formulario → Valida equipo → POST /api/requests 
   → Validación backend → Crear en DB → Mensaje éxito → Redirección
   ```

3. **Estados de la Solicitud:**
   - **active** (verde): Disponible para hacer match
   - **matched** (azul): Ya tiene un match confirmado
   - **completed** (gris): Partido finalizado
   - **cancelled** (rojo): Solicitud cancelada

4. **Acciones Disponibles:**
   - **Mis Solicitudes:** Ver, Eliminar (si no tiene match), Ver Match (si tiene)
   - **Disponibles:** Ver detalles, Hacer Match

## 🔍 Búsqueda y Filtrado

### Modos de Vista

**Disponibles:**
```typescript
const availableRequests = await prisma.matchRequest.findMany({
  where: {
    status: 'active',
    userId: { not: session.user.id }
  },
  include: { team: true, user: true },
  orderBy: { createdAt: 'desc' }
});
```

**Mis Solicitudes:**
```typescript
const myRequests = await prisma.matchRequest.findMany({
  where: { userId: session.user.id },
  include: { team: true, match: true },
  orderBy: { createdAt: 'desc' }
});
```

## 📊 TypeScript Interfaces

```typescript
interface MatchRequest {
  id: string;
  footballType: string | null;
  fieldAddress: string | null;
  fieldPrice: number | null;
  matchDate: string | null;
  league: string | null;  // Nuevo campo
  description: string | null;
  status: string;
  createdAt: string;
  team: {
    id: string;
    name: string;
  };
  user?: {
    name: string;
    phone: string | null;
  };
  match?: {
    id: string;
  };
}
```

## 🎨 Estilos y Componentes

### Colores

- **Primary:** Negro (#000000)
- **Accent:** Verde (#22c55e)
- **Success:** Verde claro (bg-green-50, border-accent)
- **Info:** Azul claro (bg-blue-50, border-blue-200)

### Componentes Reutilizables

- **StatusBadge:** Muestra estado de solicitud
- **EmptyState:** Cuando no hay solicitudes
- **QuickActionCard:** Acciones rápidas en dashboard

## 🚀 Comandos Útiles

```bash
# Generar cliente Prisma después de cambios en schema
npm run db:generate

# Sincronizar cambios con la base de datos
npm run db:push

# Ver base de datos en navegador
npm run db:studio

# Iniciar servidor de desarrollo
npm run dev
```

## ✅ Checklist de Implementación

- [x] Schema Prisma actualizado con campo "league"
- [x] API POST /api/requests actualizada
- [x] Formulario de creación con todos los campos
- [x] Logo de Tercer Tiempo integrado
- [x] Mensaje de confirmación con animación
- [x] Validaciones básicas (equipo obligatorio)
- [x] Lista de solicitudes muestra liga
- [x] Detalle de solicitud muestra liga
- [x] TypeScript interfaces actualizadas
- [x] Base de datos sincronizada
- [x] Scripts npm actualizados

## 📝 Notas Adicionales

- **Seguridad:** La validación del equipo asegura que solo el propietario pueda crear solicitudes con ese equipo
- **UX:** El campo de liga ayuda al matchmaking entre equipos de nivel similar
- **Flexibilidad:** Todos los campos opcionales permiten adaptarse a diferentes escenarios
- **Confirmación Visual:** El mensaje de éxito da feedback inmediato al usuario

## 🔄 Próximas Mejoras Sugeridas

1. **Filtros Avanzados:** Por tipo de fútbol, liga, ubicación, fecha
2. **Búsqueda:** Por nombre de equipo o liga
3. **Notificaciones:** Alertar cuando hay nuevas solicitudes compatibles
4. **Geolocalización:** Integrar mapa para mostrar ubicaciones de canchas
5. **Valoraciones:** Sistema de rating para equipos y canchas
6. **Chat:** Permitir comunicación antes del match
