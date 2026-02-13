# Sistema de Registro de Resultados de Partidos

## 📋 Descripción General

Sistema para registrar resultados de partidos amistosos completados. **Solo el usuario que creó la solicitud original** puede registrar el resultado, asegurando que el organizador del partido tenga el control sobre la información final.

## 🎯 Reglas de Negocio

### Restricciones de Acceso

✅ **Solo el organizador puede registrar el resultado:**
- El usuario que creó la `MatchRequest` original es quien tiene permiso
- Los demás participantes solo pueden ver el formulario pero no usarlo
- Validación en backend y feedback visual en frontend

✅ **Un resultado solo puede registrarse una vez:**
- Una vez guardado, el resultado no puede modificarse
- El partido pasa a estado "completed" (finalizado)
- La solicitud también se marca como "completed"

✅ **Actualización automática de estadísticas:**
- Victorias, derrotas, empates
- Total de partidos jugados
- Aplica para ambos equipos inmediatamente

## 🔧 Componentes del Sistema

### 1. Schema de Base de Datos

**Modelo Team (Estadísticas):**
```prisma
model Team {
  id        String   @id @default(cuid())
  name      String
  userId    String
  
  // Estadísticas actualizadas automáticamente
  gamesWon      Int @default(0) // Partidos ganados
  gamesLost     Int @default(0) // Partidos perdidos
  gamesDrawn    Int @default(0) // Partidos empatados
  totalGames    Int @default(0) // Total de partidos jugados
  
  // Relaciones
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  matchesAsTeam1    Match[]         @relation("Team1Matches")
  matchesAsTeam2    Match[]         @relation("Team2Matches")
  matchResultsAsWinner MatchResult[] @relation("WinnerTeam")
  
  @@index([userId])
}
```

**Modelo MatchResult:**
```prisma
model MatchResult {
  id          String  @id @default(cuid())
  matchId     String  @unique // Relación 1:1 con Match
  team1Score  Int     // Goles del equipo 1
  team2Score  Int     // Goles del equipo 2
  winnerId    String? // ID del equipo ganador (null = empate)
  createdAt   DateTime @default(now())
  
  match  Match @relation(fields: [matchId], references: [id], onDelete: Cascade)
  winner Team? @relation("WinnerTeam", fields: [winnerId], references: [id])
  
  @@index([matchId])
  @@index([winnerId])
}
```

**Modelo Match:**
```prisma
model Match {
  id              String       @id @default(cuid())
  matchRequestId  String       @unique
  team1Id         String
  team2Id         String
  userId1         String
  userId2         String
  status          String       @default("scheduled") // "scheduled", "completed", "cancelled"
  
  // Relaciones
  matchRequest    MatchRequest @relation(fields: [matchRequestId], references: [id])
  team1           Team         @relation("Team1Matches", fields: [team1Id], references: [id])
  team2           Team         @relation("Team2Matches", fields: [team2Id], references: [id])
  user1           User         @relation(fields: [userId1], references: [id])
  matchResult     MatchResult? // Resultado del partido (opcional hasta que se registre)
}
```

### 2. API Endpoint

**POST /api/matches/[id]/result**

**Descripción:** Registra el resultado final de un partido

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Cookie": "next-auth.session-token=..."
}
```

**Body:**
```json
{
  "team1Score": 3,
  "team2Score": 2
}
```

**Validaciones:**

1. **Usuario autenticado**
```typescript
const session = await getServerSession(authOptions);
if (!session?.user) {
  return NextResponse.json({ error: 'No autenticado' }, { status: 401 });
}
```

2. **Usuario es el organizador**
```typescript
const match = await prisma.match.findUnique({
  where: { id: params.id },
  include: {
    matchRequest: {
      select: { userId: true }
    }
  }
});

if (match.matchRequest.userId !== session.user.id) {
  return NextResponse.json(
    { error: 'Solo el usuario que creó la solicitud puede registrar el resultado' },
    { status: 403 }
  );
}
```

3. **Resultado no registrado previamente**
```typescript
if (match.matchResult) {
  return NextResponse.json(
    { error: 'El resultado ya fue registrado' },
    { status: 400 }
  );
}
```

4. **Marcadores válidos**
```typescript
if (team1Score === undefined || team2Score === undefined) {
  return NextResponse.json(
    { error: 'Los marcadores son requeridos' },
    { status: 400 }
  );
}
```

**Lógica de Negocio:**

```typescript
// 1. Determinar el ganador
let winnerId = null;
if (team1Score > team2Score) {
  winnerId = match.team1Id;
} else if (team2Score > team1Score) {
  winnerId = match.team2Id;
}
// null = empate

// 2. Transacción atómica (todo o nada)
await prisma.$transaction(async (tx) => {
  // 2.1 Crear resultado
  await tx.matchResult.create({
    data: {
      matchId: params.id,
      team1Score: parseInt(team1Score),
      team2Score: parseInt(team2Score),
      winnerId,
    },
  });

  // 2.2 Actualizar match status
  await tx.match.update({
    where: { id: params.id },
    data: { status: 'completed' },
  });

  // 2.3 Actualizar solicitud
  await tx.matchRequest.update({
    where: { id: match.matchRequestId },
    data: { status: 'completed' },
  });

  // 2.4 Actualizar estadísticas según resultado
  if (winnerId === match.team1Id) {
    // Equipo 1 ganó
    await tx.team.update({
      where: { id: match.team1Id },
      data: {
        gamesWon: { increment: 1 },
        totalGames: { increment: 1 },
      },
    });
    await tx.team.update({
      where: { id: match.team2Id },
      data: {
        gamesLost: { increment: 1 },
        totalGames: { increment: 1 },
      },
    });
  } else if (winnerId === match.team2Id) {
    // Equipo 2 ganó
    await tx.team.update({
      where: { id: match.team2Id },
      data: {
        gamesWon: { increment: 1 },
        totalGames: { increment: 1 },
      },
    });
    await tx.team.update({
      where: { id: match.team1Id },
      data: {
        gamesLost: { increment: 1 },
        totalGames: { increment: 1 },
      },
    });
  } else {
    // Empate
    await tx.team.updateMany({
      where: {
        id: { in: [match.team1Id, match.team2Id] },
      },
      data: {
        gamesDrawn: { increment: 1 },
        totalGames: { increment: 1 },
      },
    });
  }
});
```

**Respuesta Exitosa (200):**
```json
{
  "id": "clxxx...",
  "status": "completed",
  "team1": {
    "id": "clyyy...",
    "name": "Los Cracks FC",
    "totalGames": 11,
    "gamesWon": 7,
    "gamesLost": 3,
    "gamesDrawn": 1
  },
  "team2": {
    "id": "clzzz...",
    "name": "Rival FC",
    "totalGames": 8,
    "gamesWon": 4,
    "gamesLost": 3,
    "gamesDrawn": 1
  },
  "matchResult": {
    "id": "clwww...",
    "matchId": "clxxx...",
    "team1Score": 3,
    "team2Score": 2,
    "winnerId": "clyyy...",
    "createdAt": "2026-02-11T15:30:00.000Z"
  }
}
```

**Errores:**
- **401:** Usuario no autenticado
- **403:** Usuario no es el organizador
- **404:** Match no encontrado
- **400:** Resultado ya registrado o marcadores inválidos
- **500:** Error del servidor

### 3. Interfaz de Usuario

**Ubicación:** `/dashboard/matches/[id]`

**Vista Sin Resultado (Organizador):**

```jsx
<div className="card">
  <h3>📝 Registrar Resultado</h3>
  
  <div className="bg-blue-50 border border-blue-200 p-3 mb-4">
    <p>👤 Organizador: Tú creaste esta solicitud</p>
  </div>
  
  <form onSubmit={handleSubmitResult}>
    <div>
      <label>{match.team1.name}</label>
      <input type="number" min="0" required />
    </div>
    
    <div>
      <label>{match.team2.name}</label>
      <input type="number" min="0" required />
    </div>
    
    <button type="submit">✅ Guardar Resultado</button>
    
    <div className="bg-green-50">
      <p><strong>📊 Actualización automática:</strong></p>
      <ul>
        <li>• Estadísticas de ambos equipos</li>
        <li>• Historial de partidos</li>
        <li>• Estado del match a "Finalizado"</li>
      </ul>
    </div>
  </form>
</div>
```

**Vista Sin Resultado (Participante No-Organizador):**

```jsx
<div className="card">
  <h3>📝 Registrar Resultado</h3>
  
  <div className="bg-yellow-50 border-2 border-yellow-300 p-4">
    <span>ℹ️</span>
    <div>
      <p><strong>Solo el organizador puede registrar el resultado</strong></p>
      <p>El usuario que creó la solicitud original debe ingresar el resultado del partido.</p>
    </div>
  </div>
</div>
```

**Vista Con Resultado (Todos):**

```jsx
<div className="card bg-green-50 border-2 border-accent">
  <span>✅</span>
  <div>
    <h3>Partido Finalizado</h3>
    <div>
      <p><strong>Resultado final:</strong> Los Cracks FC 3 - 2 Rival FC</p>
      <p><strong>Ganador:</strong> 🏆 Los Cracks FC</p>
      <p>✓ Las estadísticas de ambos equipos han sido actualizadas</p>
    </div>
  </div>
</div>
```

**Marcador Visual (VS/Resultado):**

```jsx
<div className="card text-center">
  <div className="flex items-center justify-center gap-8">
    {/* Equipo 1 */}
    <div>
      <div>⚽</div>
      <p className="text-2xl font-bold">{match.team1.name}</p>
      <p className="text-sm">Tu equipo</p>
    </div>
    
    {/* Marcador o VS */}
    <div>
      {match.matchResult ? (
        <>
          <div className="flex gap-4">
            <span className="text-5xl font-bold">{matchResult.team1Score}</span>
            <span className="text-3xl">-</span>
            <span className="text-5xl font-bold">{matchResult.team2Score}</span>
          </div>
          {matchResult.winnerId === userTeam.id ? (
            <span className="text-accent">🏆 ¡Victoria!</span>
          ) : matchResult.winnerId === opponentTeam.id ? (
            <span className="text-accent-red">❌ Derrota</span>
          ) : (
            <span className="text-gray-600">🤝 Empate</span>
          )}
        </>
      ) : (
        <span className="text-5xl text-gray-400">vs</span>
      )}
    </div>
    
    {/* Equipo 2 */}
    <div>
      <div>⚽</div>
      <p className="text-2xl font-bold">{match.team2.name}</p>
      <p className="text-sm">Rival</p>
    </div>
  </div>
</div>
```

### 4. Flujo Completo

```
┌─────────────────────────────────────────┐
│ 1. Partido Aceptado (Match Created)    │
│    - Estado: "scheduled"                │
│    - matchResult: null                  │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│ 2. Partido Se Juega (Offline)          │
│    - Equipos se encuentran              │
│    - Juegan el partido                  │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│ 3. Organizador Accede al Match         │
│    - Ve formulario de resultado         │
│    - Otros ven mensaje informativo     │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│ 4. Organizador Ingresa Marcadores      │
│    - Input: Equipo1 Score              │
│    - Input: Equipo2 Score              │
│    - Click: "Guardar Resultado"        │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│ 5. POST /api/matches/[id]/result       │
│    - Valida organizador                │
│    - Valida no duplicado               │
│    - Calcula ganador                   │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│ 6. Transacción Atómica                 │
│    ✓ Crear MatchResult                 │
│    ✓ Update Match → "completed"        │
│    ✓ Update MatchRequest → "completed" │
│    ✓ Update Team1 stats                │
│    ✓ Update Team2 stats                │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│ 7. Vista Actualizada                   │
│    - Mostrar resultado final           │
│    - Mostrar ganador/empate            │
│    - Ocultar formulario                │
│    - Confirmar actualización stats     │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│ 8. Efectos en el Sistema               │
│    ✓ Estadísticas actualizadas         │
│    ✓ Match en historial               │
│    ✓ Solicitud completada              │
│    ✓ Visible en stats globales         │
└─────────────────────────────────────────┘
```

## 📊 Actualización de Estadísticas

### Caso 1: Victoria

**Equipo Ganador:**
```typescript
{
  gamesWon: +1,
  totalGames: +1,
  // gamesLost: sin cambios
  // gamesDrawn: sin cambios
}
```

**Equipo Perdedor:**
```typescript
{
  gamesLost: +1,
  totalGames: +1,
  // gamesWon: sin cambios
  // gamesDrawn: sin cambios
}
```

### Caso 2: Empate

**Ambos Equipos:**
```typescript
{
  gamesDrawn: +1,
  totalGames: +1,
  // gamesWon: sin cambios
  // gamesLost: sin cambios
}
```

### Visualización en Dashboard

**Card de Estadísticas:**
```jsx
<div className="card">
  <h3>{team.name}</h3>
  <div className="grid grid-cols-4">
    <div>
      <p className="text-3xl font-bold">{team.totalGames}</p>
      <p className="text-sm">Partidos</p>
    </div>
    <div>
      <p className="text-3xl font-bold text-green-600">{team.gamesWon}</p>
      <p className="text-sm">Victorias</p>
    </div>
    <div>
      <p className="text-3xl font-bold text-red-600">{team.gamesLost}</p>
      <p className="text-sm">Derrotas</p>
    </div>
    <div>
      <p className="text-3xl font-bold text-gray-600">{team.gamesDrawn}</p>
      <p className="text-sm">Empates</p>
    </div>
  </div>
</div>
```

## 🔐 Seguridad

### Validaciones Implementadas

✅ **1. Autenticación:**
- Requiere sesión activa
- Token JWT validado

✅ **2. Autorización:**
- Solo organizador puede registrar
- Validación basada en `matchRequest.userId`

✅ **3. Integridad de Datos:**
- Transacción atómica (rollback en error)
- Constraint `@unique` en `matchResult.matchId`
- Validación de tipos (parseInt)

✅ **4. Prevención de Duplicados:**
- Check de `matchResult` existente
- Error 400 si ya existe resultado

### Posibles Ataques y Defensas

**Intento de registro múltiple:**
```typescript
// Defensa: Check antes de transacción
if (match.matchResult) {
  return NextResponse.json(
    { error: 'El resultado ya fue registrado' },
    { status: 400 }
  );
}
```

**Usuario no autorizado:**
```typescript
// Defensa: Validación de organizador
if (match.matchRequest.userId !== session.user.id) {
  return NextResponse.json(
    { error: 'Solo el usuario que creó la solicitud puede registrar el resultado' },
    { status: 403 }
  );
}
```

**Marcadores negativos:**
```typescript
// Defensa: Validación en frontend
<input type="number" min="0" required />

// Defensa adicional en backend (recomendado)
if (team1Score < 0 || team2Score < 0) {
  return NextResponse.json(
    { error: 'Los marcadores deben ser positivos' },
    { status: 400 }
  );
}
```

## 🧪 Testing Manual

### Test Case 1: Organizador Registra Resultado (Victoria)
1. Login como Usuario A (creador de solicitud)
2. Crear solicitud
3. Usuario B acepta → Match creado
4. Ambos juegan el partido (offline)
5. Usuario A accede a `/dashboard/matches/[id]`
6. ✅ Ver formulario de resultado
7. Ingresar: Equipo A: 3, Equipo B: 2
8. Click "Guardar Resultado"
9. ✅ Ver resultado actualizado con "🏆 ¡Victoria!" para Equipo A
10. ✅ Verificar stats: Equipo A +1 victoria, Equipo B +1 derrota

### Test Case 2: Organizador Registra Resultado (Empate)
1. Login como Usuario A (organizador)
2. Acceder a match existente sin resultado
3. Ingresar: Equipo A: 2, Equipo B: 2
4. Click "Guardar Resultado"
5. ✅ Ver "🤝 Empate"
6. ✅ Verificar stats: Ambos equipos +1 empate

### Test Case 3: Participante No-Organizador Intenta Registrar
1. Login como Usuario B (aceptante, no organizador)
2. Acceder a `/dashboard/matches/[id]`
3. ✅ Ver mensaje: "Solo el organizador puede registrar el resultado"
4. ✅ NO ver formulario
5. Intentar POST directo (con herramienta)
6. ✅ Recibir error 403: "Solo el usuario que creó la solicitud puede registrar el resultado"

### Test Case 4: Intento de Registro Duplicado
1. Login como Usuario A (organizador)
2. Registrar resultado (primera vez)
3. ✅ Guardado exitoso
4. Refrescar página
5. ✅ Ya no ver formulario
6. ✅ Ver card de "Partido Finalizado"
7. Intentar POST directo (con herramienta)
8. ✅ Recibir error 400: "El resultado ya fue registrado"

### Test Case 5: Marcadores Inválidos
1. Login como Usuario A (organizador)
2. Acceder a formulario
3. Dejar un campo vacío
4. ✅ HTML5 validation: "Este campo es obligatorio"
5. Intentar número negativo (si es posible)
6. ✅ HTML5 validation: "Valor debe ser mayor o igual a 0"

## 📈 Impacto en Otras Páginas

### `/dashboard/stats`
- Muestra estadísticas actualizadas
- Ranking de equipos refleja resultados
- Contadores totales incrementan

### `/dashboard/teams/[id]`
- Estadísticas del equipo actualizadas
- Historial de matches incluye resultado
- Porcentaje de victorias recalculado

### `/dashboard/matches`
- Matches completados se marcan con ✅
- Badge "Finalizado" en lista
- Ordenamiento por estado

### `/partidos` (Vista Pública)
- Solicitud se mueve a tab "Historial"
- Badge cambia a "✅ Finalizado"
- Ya no aparece en "Disponibles"

## ✅ Checklist de Implementación

- [x] Schema Prisma con estadísticas
- [x] API POST /api/matches/[id]/result
- [x] Validación: solo organizador
- [x] Validación: no duplicados
- [x] Transacción atómica
- [x] Actualización de estadísticas (victoria)
- [x] Actualización de estadísticas (derrota)
- [x] Actualización de estadísticas (empate)
- [x] Cambio de estado Match → "completed"
- [x] Cambio de estado MatchRequest → "completed"
- [x] Formulario en frontend (organizador)
- [x] Mensaje informativo (no-organizador)
- [x] Vista de resultado finalizado
- [x] Marcador visual (vs/resultado)
- [x] Indicador de victoria/derrota/empate
- [x] Manejo de errores con feedback
- [x] Loading states

## 🔄 Próximas Mejoras

1. **Confirmación de Resultado:**
   - Ambos usuarios deben confirmar el resultado
   - Solo se aplica cuando ambos confirman
   - Mecanismo de disputa si no coinciden

2. **Edición de Resultado:**
   - Permitir corrección dentro de las 24 horas
   - Requiere notificación al otro usuario
   - Log de cambios

3. **Detalles del Partido:**
   - Goleadores
   - Tarjetas amarillas/rojas
   - MVP del partido
   - Fotos/videos

4. **Notificaciones:**
   - Email cuando se registra resultado
   - Push notification en app
   - Resumen semanal de partidos

5. **Análisis Avanzado:**
   - Gráficos de rendimiento
   - Comparación con otros equipos
   - Predicciones basadas en historial
   - Racha de victorias/derrotas
