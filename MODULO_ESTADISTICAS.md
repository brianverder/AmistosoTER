# Módulo de Estadísticas de Equipos

## Descripción General

El módulo de estadísticas proporciona una vista completa del rendimiento de cada equipo, mostrando:
- Cantidad de partidos jugados
- Partidos ganados
- Partidos perdidos  
- Partidos empatados
- Historial detallado de encuentros

## Estructura de Archivos

### API Endpoint

**Archivo:** `app/api/teams/[id]/stats/route.ts`

**Endpoint:** `GET /api/teams/[id]/stats`

**Autenticación:** Requerida (solo el dueño del equipo puede ver las estadísticas)

**Respuesta:**
```json
{
  "team": {
    "id": "team-id",
    "name": "Nombre del Equipo",
    "gamesWon": 10,
    "gamesLost": 3,
    "gamesDrawn": 2,
    "totalGames": 15
  },
  "matchHistory": [
    {
      "id": "match-id",
      "opponent": "Equipo Rival",
      "ownScore": 3,
      "opponentScore": 2,
      "result": "won",
      "footballType": "11",
      "matchDate": "2026-02-10T18:00:00.000Z",
      "createdAt": "2026-02-01T10:00:00.000Z"
    }
  ]
}
```

**Lógica del Endpoint:**
1. Verifica que el usuario esté autenticado
2. Verifica que el equipo pertenezca al usuario
3. Obtiene las estadísticas base del equipo (gamesWon, gamesLost, gamesDrawn, totalGames)
4. Obtiene todos los matches finalizados (status: 'completed') donde el equipo participó
5. Formatea el historial incluyendo:
   - Nombre del oponente
   - Resultado (won/lost/draw)
   - Marcadores (ownScore, opponentScore)
   - Tipo de fútbol
   - Fecha del partido

### Página de Estadísticas

**Archivo:** `app/dashboard/teams/[id]/stats/page.tsx`

**Ruta:** `/dashboard/teams/[id]/stats`

**Componentes Principales:**

#### 1. Resumen de Estadísticas (Cards)
Grid de 4 cards mostrando:
- **Partidos Jugados**: Total de partidos con número grande
- **Victorias**: En verde con porcentaje de efectividad
- **Derrotas**: En rojo
- **Empates**: En gris

```tsx
<div className="grid grid-cols-1 md:grid-cols-4 gap-4">
  <!-- Cards con estadísticas -->
</div>
```

#### 2. Tabla de Historial

Tabla responsive con las siguientes columnas:
- **Fecha**: Fecha del partido (o fecha de creación si no hay matchDate)
- **Oponente**: Nombre del equipo rival
- **Resultado**: Marcador con colores según resultado
  - Verde para goles a favor en victoria
  - Rojo para goles en contra en derrota
  - Gris para empates
- **Tipo**: Tipo de fútbol (11, 7, 5, 8, otro)
- **Estado**: Badge con el resultado (🏆 Victoria / ❌ Derrota / 🤝 Empate)

**Estados Vacíos:**
Si no hay partidos finalizados, muestra un mensaje amigable:
```
📋
No hay partidos finalizados aún
Los partidos aparecerán aquí una vez que se registren los resultados
```

### Integración con Páginas Existentes

#### Página de Detalle del Equipo
**Archivo:** `app/dashboard/teams/[id]/page.tsx`

Agregado botón prominente para acceder a estadísticas:
```tsx
<Link href={`/dashboard/teams/${team.id}/stats`} className="btn-primary">
  📊 Ver Estadísticas Completas
</Link>
```

#### Página de Listado de Equipos
**Archivo:** `app/dashboard/teams/page.tsx`

Agregado botón de acceso rápido en cada card:
```tsx
<Link
  href={`/dashboard/teams/${team.id}/stats`}
  className="btn-primary flex-1 text-center text-sm"
  title="Ver estadísticas completas"
>
  📊
</Link>
```

## Diseño y Estilos

### Principios de Diseño
- **Limpio y minimalista**: Uso de espacios en blanco y tipografía clara
- **Código de colores consistente**:
  - Verde (#22c55e): Victorias y resultados positivos
  - Rojo (#ef4444): Derrotas
  - Gris: Empates
  - Azul: Información general
- **Responsive**: Grid adaptable para móviles, tablets y desktop
- **Iconos descriptivos**: Uso de emojis para mejorar la UX (⚽🏆❌🤝📊)

### Estilos Clave

**Cards de Estadísticas:**
```css
- Grid responsivo: 1 columna en móvil, 4 en desktop
- Texto grande (3xl) para números
- Alineación centrada
- Padding generoso
```

**Tabla de Historial:**
```css
- Overflow-x-auto para scroll horizontal en móviles
- Hover effects en filas (bg-gray-50)
- Bordes sutiles (border-gray-100)
- Padding consistente (py-4 px-4)
```

**Badges de Resultado:**
```css
- Border-radius redondeado (rounded-full)
- Padding compacto (px-3 py-1)
- Colores de fondo suaves (bg-green-100, bg-red-100, bg-gray-100)
- Texto contrastante
```

## Flujo de Usuario

### 1. Acceso a Estadísticas

**Desde Listado de Equipos:**
```
Dashboard > Mis Equipos > Click en 📊 > Vista de Estadísticas
```

**Desde Detalle de Equipo:**
```
Dashboard > Mis Equipos > Ver Detalles > Ver Estadísticas Completas > Vista de Estadísticas
```

### 2. Navegación en la Vista
```
Breadcrumb: ← Volver a {Nombre del Equipo}
    ↓
Título: 📊 Estadísticas de {Nombre del Equipo}
    ↓
Cards de Resumen (4 métricas principales)
    ↓
Tabla de Historial (partidos finalizados)
    ↓
Botón: Volver al Equipo
```

## Cálculos y Lógica

### Porcentaje de Efectividad
```typescript
const winRate = team.totalGames > 0 
  ? ((team.gamesWon / team.totalGames) * 100).toFixed(1)
  : '0.0';
```

### Determinación del Resultado
```typescript
let result: 'won' | 'lost' | 'draw' = 'draw';
if (match.matchResult?.winnerId) {
  if (match.matchResult.winnerId === params.id) {
    result = 'won';
  } else {
    result = 'lost';
  }
}
```

### Identificación de Oponente y Marcadores
```typescript
const isTeam1 = match.team1Id === params.id;
const opponent = isTeam1 ? match.team2 : match.team1;
const ownScore = isTeam1
  ? match.matchResult?.team1Score
  : match.matchResult?.team2Score;
const opponentScore = isTeam1
  ? match.matchResult?.team2Score
  : match.matchResult?.team1Score;
```

## Seguridad

### Validaciones en API
1. **Autenticación**: Verifica sesión activa
2. **Autorización**: Solo el dueño del equipo puede ver sus estadísticas
3. **Ownerrship**: Query con `userId: session.user.id` asegura acceso correcto
4. **Filtrado**: Solo muestra matches completados (status: 'completed')

### Manejo de Errores

**Estados de Error:**
- 401: No autorizado (sin sesión)
- 404: Equipo no encontrado
- 500: Error del servidor

**UI de Error:**
```tsx
<div className="card text-center py-12">
  <div className="text-6xl mb-4">❌</div>
  <h2 className="text-2xl font-bold text-primary mb-2">Error</h2>
  <p className="text-gray-600 mb-6">{error}</p>
  <Link href={`/dashboard/teams/${params.id}`}>Volver al Equipo</Link>
</div>
```

## Datos y Relaciones

### Consulta Principal (Prisma)
```typescript
const matches = await prisma.match.findMany({
  where: {
    OR: [
      { team1Id: params.id },
      { team2Id: params.id },
    ],
    status: 'completed',
  },
  include: {
    team1: { select: { id: true, name: true } },
    team2: { select: { id: true, name: true } },
    matchResult: {
      select: {
        team1Score: true,
        team2Score: true,
        winnerId: true,
      },
    },
    matchRequest: {
      select: {
        footballType: true,
        matchDate: true,
      },
    },
  },
  orderBy: { createdAt: 'desc' },
});
```

### Modelos Relacionados
- **Team**: Estadísticas base (gamesWon, gamesLost, gamesDrawn, totalGames)
- **Match**: Relación entre dos equipos
- **MatchResult**: Marcadores y ganador
- **MatchRequest**: Metadata del partido (tipo de fútbol, fecha)

## Testing

### Casos de Prueba

#### 1. Equipo Nuevo (Sin Partidos)
- ✅ Todas las estadísticas en 0
- ✅ Mensaje de estado vacío en historial
- ✅ No se muestra porcentaje de efectividad

#### 2. Equipo con Partidos
- ✅ Estadísticas correctas (suma de W/L/D)
- ✅ Porcentaje de efectividad calculado
- ✅ Historial ordenado por fecha (más reciente primero)
- ✅ Colores correctos según resultado

#### 3. Seguridad
- ✅ Usuario no autenticado → Redirect a login
- ✅ Usuario autenticado pero no dueño → 404
- ✅ ID de equipo inválido → Error 404

#### 4. Responsive
- ✅ Grid de 1 columna en móvil
- ✅ Grid de 4 columnas en desktop
- ✅ Tabla con scroll horizontal en móvil
- ✅ Botones apilados en móvil

## Mejoras Futuras

### Posibles Extensiones
1. **Filtros**: Por fecha, por tipo de fútbol, por oponente
2. **Exportación**: Descargar estadísticas en PDF/CSV
3. **Gráficos**: Visualización con charts (victoria/derrota por mes)
4. **Comparación**: Comparar rendimiento con otros equipos
5. **Rachas**: Mostrar rachas de victorias/derrotas
6. **Estadísticas por Tipo**: Rendimiento en Fútbol 11 vs 7 vs 5
7. **Top Oponentes**: Contra quién se ha jugado más veces
8. **Goleadores**: Si se agregan goleadores por partido
9. **Estadísticas Avanzadas**: Promedio de goles, goles en contra, diferencia de goles
10. **Timeline**: Visualización cronológica del rendimiento

### Optimizaciones
- Caché de estadísticas para equipos con muchos partidos
- Paginación del historial para más de 50 partidos
- Lazy loading de la tabla
- Skeleton loaders durante carga

## Notas Técnicas

### Dependencias
- Next.js 14 (App Router)
- Prisma ORM
- NextAuth.js
- Tailwind CSS

### Consideraciones de Rendimiento
- Query optimizado con `select` específicos
- Índices en la DB para OR queries (team1Id, team2Id)
- Ordenamiento en DB level, no en cliente
- Solo matches completados reducen el dataset

### Accesibilidad
- Emojis con significado semántico
- Colores con suficiente contraste
- Texto descriptivo en botones
- Responsive para diferentes dispositivos

## Resumen

El módulo de estadísticas proporciona una **vista completa y limpia** del rendimiento de cada equipo, con:
✅ **Resumen visual** de estadísticas clave (4 cards)
✅ **Historial detallado** en tabla responsive
✅ **Diseño limpio** con código de colores intuitivo
✅ **Navegación fácil** desde múltiples puntos de entrada
✅ **Seguridad robusta** con validación de ownership
✅ **UX optimizada** con estados vacíos y mensajes claros

El módulo está completamente integrado con el sistema existente y aprovecha las estadísticas que ya se actualizan automáticamente al registrar resultados de partidos.
