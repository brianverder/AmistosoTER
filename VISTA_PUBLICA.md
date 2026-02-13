# Vista Pública de Solicitudes de Partidos

## 📋 Descripción General

Sistema público para visualizar y aceptar solicitudes de partidos amistosos. Permite a cualquier usuario ver partidos disponibles, y a usuarios autenticados aceptar partidos y crear matches.

## 🌐 URLs Públicas

- **Lista de Partidos:** `/partidos`
- **Detalle de Partido:** `/partidos/[id]`
- **Página de Inicio:** `/` (redirige a `/partidos`)

## 🎯 Características Principales

### 1. Vista Pública de Listado (`/partidos`)

**Acceso:** Público (no requiere autenticación para ver)

**Funcionalidades:**

✅ **Tabs de Filtrado:**
- 🟢 **Partidos Disponibles:** Solicitudes con estado "active"
- 📚 **Historial:** Solicitudes con estado "matched", "completed", "cancelled"

✅ **Información Mostrada por Solicitud:**
- Nombre del equipo solicitante
- Organizador (nombre del usuario)
- Estadísticas del equipo (V-D/E)
- Tipo de fútbol (11, 8, 7, 5, otro)
- Liga del equipo
- Ubicación de la cancha
- Fecha y hora del partido
- Precio de la cancha
- Descripción
- Estado con badge visual

✅ **Estados con Badges:**
```typescript
🟢 Disponible (verde)    - Estado: "active"
🤝 Match Hecho (azul)   - Estado: "matched"
✅ Finalizado (gris)    - Estado: "completed"
❌ Cancelado (rojo)     - Estado: "cancelled"
```

✅ **Experiencia de Usuario:**
- Header con logo de Tercer Tiempo
- Botones de "Iniciar Sesión" / "Registrarse" (si no está autenticado)
- Botón "Mi Dashboard" (si está autenticado)
- Cards responsivas (grid 1/2/3 columnas)
- CTA para crear cuenta si no está autenticado

### 2. Vista de Detalle (`/partidos/[id]`)

**Acceso:** Público (no requiere autenticación para ver)

**Layout:**
- **Columna Principal (2/3):** Información completa del partido
- **Sidebar (1/3):** Acción principal y contexto

**Información Mostrada:**

📄 **Detalles del Partido:**
- ⚽ Tipo de Fútbol
- 🏆 Liga
- 📍 Ubicación de la cancha
- 📅 Fecha y hora
- 💵 Precio
- 📝 Descripción completa

👥 **Sobre el Equipo:**
- Nombre del equipo
- Organizador
- Estadísticas (si tiene partidos jugados):
  - Partidos jugados
  - Victorias
  - Derrotas
  - Empates

💡 **Consejos:**
- Verificar ubicación y fecha
- Al hacer match se ven datos de contacto
- Coordinar detalles con el organizador
- Confirmar precio y forma de pago

### 3. Sistema de Match

**Flujo para Usuarios No Autenticados:**
1. Ver solicitud → Clic en "Aceptar Partido"
2. Redirigir a `/login?returnUrl=/partidos/[id]`
3. Login exitoso → Volver a la solicitud
4. Proceder con el match

**Flujo para Usuarios Autenticados:**

```
Usuario ve solicitud
    ↓
Clic en "Aceptar Partido"
    ↓
Modal: "Selecciona tu Equipo"
    ↓
Seleccionar equipo de la lista
    ↓
Confirmar Match
    ↓
POST /api/requests/[id]/match
    ↓
Estado cambia a "matched"
    ↓
Se crea registro en tabla Match
    ↓
Se muestran datos de contacto de ambos usuarios
```

**Validaciones:**
- ✅ Usuario debe estar autenticado
- ✅ Usuario debe tener al menos un equipo
- ✅ No puede aceptar su propia solicitud
- ✅ La solicitud debe estar en estado "active"
- ✅ Una solicitud solo puede tener un match (relación 1:1)

### 4. Información de Contacto Post-Match

**Solo visible para participantes del match:**

```jsx
🤝 Match Confirmado

Equipo Solicitante:
- Nombre del Equipo A
- Contacto: [Nombre Usuario A]
- Email: [email@example.com]
- Teléfono: [123456789]

Equipo Aceptante:
- Nombre del Equipo B
- Contacto: [Nombre Usuario B]
- Email: [email@example.com]
- Teléfono: [987654321]

💡 Siguiente paso: Coordinen entre ustedes los detalles finales
```

**Privacidad:**
- Emails y teléfonos NO se muestran en la vista pública
- Solo se muestran después del match
- Solo visibles para los 2 usuarios participantes

## 🔧 APIs (Públicas)

### GET /api/public/requests

**Descripción:** Listar solicitudes de partidos (acceso público)

**Query Parameters:**
- `status`: `'active'` | `'matched'` | `'completed'` | `'cancelled'` | `'historical'` | `'all'`

**Respuesta:**
```json
[
  {
    "id": "clxxx...",
    "footballType": "11",
    "fieldAddress": "Complejo Norte",
    "fieldPrice": 5000,
    "matchDate": "2026-02-15T18:00:00.000Z",
    "league": "Liga Amateur",
    "description": "Buscamos rival competitivo",
    "status": "active",
    "createdAt": "2026-02-11T14:30:00.000Z",
    "team": {
      "id": "clyyy...",
      "name": "Los Cracks FC",
      "gamesPlayed": 10,
      "gamesWon": 6
    },
    "user": {
      "id": "clzzz...",
      "name": "Juan Pérez"
      // NO incluye email/phone en vista pública
    },
    "match": {
      "id": "clwww...",
      "status": "confirmed"
    }
  }
]
```

**Características:**
- Límite de 100 resultados por consulta
- Solo incluye datos públicos (sin emails/teléfonos)
- Ordenado por fecha de creación (más recientes primero)

### GET /api/public/requests/[id]

**Descripción:** Obtener detalle de una solicitud específica

**Respuesta:**
```json
{
  "id": "clxxx...",
  "footballType": "11",
  "fieldAddress": "Complejo Norte",
  "fieldPrice": 5000,
  "matchDate": "2026-02-15T18:00:00.000Z",
  "league": "Liga Amateur",
  "description": "Buscamos rival competitivo",
  "status": "matched",
  "team": {
    "id": "clyyy...",
    "name": "Los Cracks FC",
    "gamesPlayed": 10,
    "gamesWon": 6,
    "gamesLost": 2,
    "gamesDraw": 2
  },
  "user": {
    "id": "clzzz...",
    "name": "Juan Pérez",
    "email": "juan@example.com",  // Solo si está autenticado y es participante
    "phone": "123456789"           // Solo si está autenticado y es participante
  },
  "match": {
    "id": "clwww...",
    "teamA": { "id": "...", "name": "Los Cracks FC" },
    "teamB": { "id": "...", "name": "Rival FC" },
    "userA": {
      "id": "...",
      "name": "Juan Pérez",
      "email": "juan@example.com",  // Solo visible para participantes
      "phone": "123456789"
    },
    "userB": {
      "id": "...",
      "name": "Carlos López",
      "email": "carlos@example.com",
      "phone": "987654321"
    }
  }
}
```

**Lógica de Privacidad:**
```typescript
if (matchRequest.match && isAuthenticated) {
  const isParticipant =
    matchRequest.match.userA.id === session.user.id ||
    matchRequest.match.userB.id === session.user.id;

  if (!isParticipant) {
    // Ocultar información de contacto
    matchRequest.match.userA.email = '';
    matchRequest.match.userA.phone = null;
    matchRequest.match.userB.email = '';
    matchRequest.match.userB.phone = null;
  }
}
```

## 🔐 Restricciones Implementadas

### 1. No Puede Aceptar Propia Solicitud

```typescript
const isOwnRequest = session?.user?.id === request.user.id;
const canAccept = request.status === 'active' && !isOwnRequest;
```

**Feedback UI:**
```jsx
{isOwnRequest && (
  <div className="bg-yellow-50 border border-yellow-200">
    ℹ️ Esta es tu propia solicitud
  </div>
)}
```

### 2. Solo Un Match Por Solicitud

**Schema Prisma:**
```prisma
model MatchRequest {
  // ...
  match Match? // Relación 1-1 (opcional)
}

model Match {
  id              String       @id @default(cuid())
  matchRequestId  String       @unique // Unique constraint
  matchRequest    MatchRequest @relation(fields: [matchRequestId], references: [id])
  // ...
}
```

**Validación API:**
```typescript
// En /api/requests/[id]/match
const existingMatch = await prisma.match.findUnique({
  where: { matchRequestId: params.id },
});

if (existingMatch) {
  return NextResponse.json(
    { error: 'Esta solicitud ya tiene un match' },
    { status: 400 }
  );
}
```

### 3. Solo Estado "Active" Puede Ser Aceptado

```typescript
if (matchRequest.status !== 'active') {
  return NextResponse.json(
    { error: 'Esta solicitud no está disponible' },
    { status: 400 }
  );
}
```

## 🎨 Componentes de UI

### Header Público

```jsx
<header className="bg-primary text-white py-6">
  <Logo + Título />
  {session ? (
    <Link to="/dashboard">Mi Dashboard</Link>
  ) : (
    <>
      <Link to="/login">Iniciar Sesión</Link>
      <Link to="/register">Registrarse</Link>
    </>
  )}
</header>
```

### Status Badges

```tsx
const badges = {
  active: { text: 'Disponible', class: 'bg-green-100 text-green-800', icon: '🟢' },
  matched: { text: 'Match Hecho', class: 'bg-blue-100 text-blue-800', icon: '🤝' },
  completed: { text: 'Finalizado', class: 'bg-gray-100 text-gray-800', icon: '✅' },
  cancelled: { text: 'Cancelado', class: 'bg-red-100 text-red-800', icon: '❌' },
};
```

### Modal de Selección de Equipo

```jsx
<Modal>
  <h3>Selecciona tu Equipo</h3>
  <select>
    {userTeams.map(team => (
      <option value={team.id}>
        {team.name} ({team.gamesWon}V - {team.gamesPlayed - team.gamesWon}D/E)
      </option>
    ))}
  </select>
  <Button onClick={handleConfirmMatch}>Confirmar Match</Button>
</Modal>
```

## 🔄 Estados y Transiciones

### Diagrama de Estados

```
┌─────────┐
│ ACTIVE  │  (Verde - Disponible)
└─────────┘
     │
     │ Usuario acepta partido
     ↓
┌─────────┐
│ MATCHED │  (Azul - Match Hecho)
└─────────┘
     │
     │ Se registra resultado
     ↓
┌───────────┐
│ COMPLETED │  (Gris - Finalizado)
└───────────┘

Desde cualquier estado:
     ↓
┌───────────┐
│ CANCELLED │  (Rojo - Cancelado)
└───────────┘
```

### Cambio de Estado en Match

```typescript
// Al aceptar partido
await prisma.matchRequest.update({
  where: { id: requestId },
  data: { status: 'matched' },
});

await prisma.match.create({
  data: {
    matchRequestId: requestId,
    teamAId: matchRequest.teamId,
    teamBId: selectedTeamId,
    userAId: matchRequest.userId,
    userBId: session.user.id,
    status: 'scheduled',
  },
});
```

## 📱 Navegación

### Desde Dashboard (Usuario Autenticado)

```
DashboardNav → "Partidos Públicos" → /partidos
```

### Desde Público (Sin Autenticación)

```
Homepage (/) → Redirect → /partidos
```

### Return URL en Login

```typescript
// Al hacer clic en "Aceptar Partido" sin autenticación
router.push(`/login?returnUrl=/partidos/${id}`);

// Después del login
const returnUrl = searchParams.get('returnUrl') || '/dashboard';
router.push(returnUrl);
```

## 📊 TypeScript Interfaces

```typescript
interface MatchRequest {
  id: string;
  footballType: string | null;
  fieldAddress: string | null;
  fieldPrice: number | null;
  matchDate: string | null;
  league: string | null;
  description: string | null;
  status: 'active' | 'matched' | 'completed' | 'cancelled';
  team: Team;
  user: User;
  match?: Match;
}

interface Match {
  id: string;
  teamA: Team;
  teamB: Team;
  userA: User;
  userB: User;
  matchDate: string | null;
  status: string;
}
```

## 🚀 Testing Manual

### Test Case 1: Usuario No Autenticado Ver Partidos
1. Abrir `/partidos` sin sesión
2. ✅ Ver lista de partidos disponibles
3. ✅ Ver tab de historial
4. ✅ Ver botones "Iniciar Sesión" y "Registrarse"
5. Clic en una solicitud
6. ✅ Ver todos los detalles del partido
7. ✅ NO ver datos de contacto
8. Clic en "Aceptar Partido"
9. ✅ Redirigir a `/login?returnUrl=/partidos/[id]`

### Test Case 2: Usuario Autenticado Aceptar Partido
1. Login exitoso
2. Ir a `/partidos`
3. ✅ Ver botón "Mi Dashboard"
4. Clic en una solicitud (no propia)
5. Clic en "Aceptar Partido"
6. ✅ Abrir modal de selección de equipo
7. Seleccionar equipo
8. Confirmar
9. ✅ Estado cambia a "matched"
10. ✅ Ver datos de contacto de ambos usuarios

### Test Case 3: Intentar Aceptar Propia Solicitud
1. Login como usuario A
2. Ir a `/partidos`
3. Buscar solicitud creada por usuario A
4. Abrir detalle
5. ✅ Ver mensaje "Esta es tu propia solicitud"
6. ✅ Botón "Aceptar Partido" deshabilitado

### Test Case 4: Ver Historial
1. Ir a `/partidos`
2. Clic en tab "Historial"
3. ✅ Ver solicitudes con estado "matched", "completed", "cancelled"
4. ✅ NO ver solicitudes "active"
5. Abrir detalle de solicitud "matched"
6. ✅ Ver información del match
7. Si es participante: ✅ Ver datos de contacto
8. Si NO es participante: ✅ NO ver datos de contacto

## 🔧 Configuración

### Middleware (Sin cambios)

Las rutas `/partidos` y `/api/public/*` NO están protegidas por el middleware, permitiendo acceso público.

```typescript
export const config = {
  matcher: ['/dashboard/:path*', '/api/teams/:path*', '/api/requests/:path*', '/api/matches/:path*'],
};
```

### SessionProvider Global

```tsx
// app/layout.tsx
<NextAuthProvider>
  {children}
</NextAuthProvider>
```

Esto permite usar `useSession()` en cualquier página, incluyendo las públicas.

## 📝 Notas Adicionales

### SEO y Open Graph (Futuro)
- Agregar metadata dinámica en páginas de detalle
- Open Graph tags para compartir en redes sociales
- Descripción y preview de partidos

### Performance
- API pública limitada a 100 resultados
- Considerar paginación para grandes volúmenes
- Cache de solicitudes públicas (ISR)

### Seguridad
- Solo datos públicos en APIs públicas
- Datos de contacto solo para participantes
- Validación de permisos en backend
- Rate limiting en APIs públicas (futuro)

## ✅ Checklist de Implementación

- [x] API GET /api/public/requests
- [x] API GET /api/public/requests/[id]
- [x] Página /partidos (lista)
- [x] Página /partidos/[id] (detalle)
- [x] Filtros por estado (active/historical)
- [x] Validación: no aceptar propia solicitud
- [x] Validación: solo un match por solicitud
- [x] Modal de selección de equipo
- [x] Cambio de estado a "matched"
- [x] Mostrar datos de contacto post-match
- [x] Privacidad: ocultar contactos para no participantes
- [x] Return URL en login
- [x] SessionProvider global
- [x] Link en DashboardNav
- [x] Redirect homepage a /partidos
- [x] Empty states con CTAs
- [x] Feedback visual de estados
- [x] Responsive design

## 🎯 Próximas Mejoras

1. **Filtros Avanzados:** Por ubicación, tipo de fútbol, liga, fecha
2. **Búsqueda:** Por nombre de equipo o ubicación
3. **Mapa:** Visualizar ubicaciones de canchas
4. **Notificaciones:** Alertar cuando hay nuevo match
5. **Chat:** Comunicación in-app antes del partido
6. **Compartir:** Share links en redes sociales
7. **Favoritos:** Guardar solicitudes interesantes
8. **Calendario:** Vista de calendario con partidos
