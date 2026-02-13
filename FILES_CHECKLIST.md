# 📝 Lista de Archivos - Refactorización a Arquitectura Limpia

## ✅ Archivos CREADOS

### Capa de Repositorios
- ✅ `lib/repositories/users.repository.ts` (~130 líneas)
- ✅ `lib/repositories/teams.repository.ts` (~280 líneas)
- ✅ `lib/repositories/requests.repository.ts` (~280 líneas)
- ✅ `lib/repositories/matches.repository.ts` (~250 líneas)
- ✅ `lib/repositories/results.repository.ts` (~120 líneas)
- ✅ `lib/repositories/index.ts` (~10 líneas)

### Capa de Servicios (Server-Side)
- ✅ `lib/services-server/teams.service.ts` (~230 líneas)
- ✅ `lib/services-server/requests.service.ts` (~280 líneas)
- ✅ `lib/services-server/matches.service.ts` (~310 líneas)
- ✅ `lib/services-server/index.ts` (~5 líneas)

### Sistema de Errores
- ✅ `lib/errors.ts` (~150 líneas)

### Documentación
- ✅ `REFACTORING_SUMMARY.md` - Resumen de cambios
- ✅ `ARCHITECTURE_GUIDE.md` - Guía completa de arquitectura
- ✅ `FILES_CHECKLIST.md` - Este archivo

**Total creados:** 14 archivos (~2,045 líneas de código)

---

## ✏️ Archivos MODIFICADOS

### API Routes Refactorizadas
- ✅ `app/api/teams/route.ts`
  - Cambio: Usa `TeamsService.getUserTeams()` y `TeamsService.createTeam()`
  - Ahora usa: `handleApiError()` para manejo de errores
  
- ✅ `app/api/teams/[id]/route.ts`
  - Cambio: Usa `TeamsService.getTeamById()`, `updateTeam()`, `deleteTeam()`
  - Código reducido de ~140 líneas a ~90 líneas
  
- ✅ `app/api/requests/route.ts`
  - Cambio: Usa `MatchRequestsService.getUserRequests()` y `createRequest()`
  - Ahora implementa paginación con query params
  
- ✅ `app/api/matches/route.ts`
  - Cambio: Usa `MatchesService.getUserMatches()`
  - Ahora soporta filtro por status

**Total modificados:** 4 archivos

---

## 🔜 Archivos PENDIENTES de Modificar

### API Routes que Necesitan Refactorización

#### Solicitudes (Match Requests)
- ⏳ `app/api/requests/[id]/route.ts`
  - **Métodos:** GET, PATCH, DELETE
  - **Cambio sugerido:** Usar `MatchRequestsService.getRequestById()`, `updateRequest()`, `cancelRequest()`, `deleteRequest()`
  
- ⏳ `app/api/requests/[id]/match/route.ts`
  - **Métodos:** POST (aceptar solicitud)
  - **Cambio sugerido:** Usar `MatchesService.createMatchFromRequest()`

#### Partidos (Matches)
- ⏳ `app/api/matches/[id]/route.ts`
  - **Métodos:** GET, PATCH, DELETE
  - **Cambio sugerido:** Usar `MatchesService.getMatchById()`, `confirmMatch()`, `cancelMatch()`
  
- ⏳ `app/api/matches/[id]/result/route.ts`
  - **Métodos:** POST
  - **Cambio sugerido:** Usar `MatchesService.registerResult()`

#### Equipos (Teams)
- ⏳ `app/api/teams/[id]/stats/route.ts`
  - **Métodos:** GET
  - **Cambio sugerido:** Usar `TeamsService.getTeamStats()`

#### Vista Pública
- ⏳ `app/api/public/requests/route.ts`
  - **Métodos:** GET
  - **Cambio sugerido:** Usar `MatchRequestsService.getAvailableRequests()` sin autenticación requerida
  
- ⏳ `app/api/public/requests/[id]/route.ts`
  - **Métodos:** GET
  - **Cambio sugerido:** Crear `MatchRequestsService.getPublicRequestById()`

**Total pendientes:** 7 archivos

---

## ⚠️ Archivos a EVALUAR para Eliminación

### Servicios del Cliente (Frontend)
Estos archivos actualmente solo envuelven llamadas `fetch()`. Si no tienen lógica adicional, pueden simplificarse o eliminarse.

#### Para Revisar:
1. **`lib/services/teams.service.ts`**
   - Contenido típico:
     ```typescript
     export async function getTeams() {
       const response = await fetch('/api/teams');
       return response.json();
     }
     ```
   - **Opciones:**
     - ✂️ Eliminar y llamar `fetch` directamente desde componentes
     - 🔄 Mantener si agrega transformación de datos o caché
     - 📦 Convertir a React Query hooks

2. **`lib/services/requests.service.ts`**
   - Similar a teams.service.ts
   - **Mismas opciones**

3. **`lib/services/matches.service.ts`**
   - Similar a teams.service.ts
   - **Mismas opciones**

#### Recomendación:
```typescript
// OPCIÓN 1: Llamada directa (más simple)
// En el componente:
const teams = await fetch('/api/teams').then(r => r.json());

// OPCIÓN 2: Mantener servicios si tienen lógica adicional
// lib/services/teams.service.ts
export async function getTeams() {
  const response = await fetch('/api/teams');
  const teams = await response.json();
  
  // Transformación de datos
  return teams.map(team => ({
    ...team,
    winRate: calculateWinRate(team.wins, team.losses, team.draws),
    displayName: team.name.toUpperCase(),
  }));
}

// OPCIÓN 3: Usar React Query (recomendado para proyectos grandes)
// lib/hooks/useTeams.ts
import { useQuery } from '@tanstack/react-query';

export function useTeams() {
  return useQuery({
    queryKey: ['teams'],
    queryFn: async () => {
      const response = await fetch('/api/teams');
      if (!response.ok) throw new Error('Failed to fetch teams');
      return response.json();
    },
  });
}
```

**Decisión:** El usuario debe revisar estos archivos y decidir si eliminarlos o mantenerlos.

---

## 🗂️ Estructura Final del Proyecto

```
d:/bverdier/Documents/Amistoso TER Web/
│
├── app/
│   ├── api/
│   │   ├── auth/
│   │   │   └── [...nextauth]/route.ts
│   │   ├── teams/
│   │   │   ├── route.ts ✅ REFACTORIZADO
│   │   │   └── [id]/
│   │   │       ├── route.ts ✅ REFACTORIZADO
│   │   │       └── stats/route.ts ⏳ PENDIENTE
│   │   ├── requests/
│   │   │   ├── route.ts ✅ REFACTORIZADO
│   │   │   └── [id]/
│   │   │       ├── route.ts ⏳ PENDIENTE
│   │   │       └── match/route.ts ⏳ PENDIENTE
│   │   ├── matches/
│   │   │   ├── route.ts ✅ REFACTORIZADO
│   │   │   └── [id]/
│   │   │       ├── route.ts ⏳ PENDIENTE
│   │   │       └── result/route.ts ⏳ PENDIENTE
│   │   └── public/
│   │       └── requests/
│   │           ├── route.ts ⏳ PENDIENTE
│   │           └── [id]/route.ts ⏳ PENDIENTE
│   ├── dashboard/
│   ├── login/
│   ├── register/
│   └── partidos/
│
├── lib/
│   ├── repositories/ ✅ NUEVO
│   │   ├── users.repository.ts
│   │   ├── teams.repository.ts
│   │   ├── requests.repository.ts
│   │   ├── matches.repository.ts
│   │   ├── results.repository.ts
│   │   └── index.ts
│   │
│   ├── services-server/ ✅ NUEVO
│   │   ├── teams.service.ts
│   │   ├── requests.service.ts
│   │   ├── matches.service.ts
│   │   └── index.ts
│   │
│   ├── services/ ⚠️ EVALUAR
│   │   ├── teams.service.ts
│   │   ├── requests.service.ts
│   │   └── matches.service.ts
│   │
│   ├── errors.ts ✅ NUEVO
│   ├── auth.ts
│   └── prisma.ts
│
├── prisma/
│   └── schema.prisma
│
├── REFACTORING_SUMMARY.md ✅ NUEVO
├── ARCHITECTURE_GUIDE.md ✅ NUEVO
├── FILES_CHECKLIST.md ✅ NUEVO (este archivo)
├── ARCHITECTURE.md (original)
├── MODULO_ESTADISTICAS.md
├── MODULO_SOLICITUDES.md
├── SISTEMA_RESULTADOS.md
└── VISTA_PUBLICA.md
```

---

## 📊 Resumen de Cambios

| Categoría | Cantidad | Estado |
|-----------|----------|--------|
| Archivos CREADOS | 14 | ✅ Completo |
| Archivos MODIFICADOS | 4 | ✅ Completo |
| Archivos PENDIENTES | 7 | ⏳ Por hacer |
| Archivos A EVALUAR | 3 | ⚠️ Decisión del usuario |
| **Total Afectados** | **28** | **~39% completado** |

---

## ✅ Checklist de Implementación

### Fase 1: Fundamentos (✅ COMPLETADA)
- [x] Crear capa de repositorios (6 archivos)
- [x] Crear capa de servicios (4 archivos)
- [x] Crear sistema de errores (1 archivo)
- [x] Refactorizar API routes principales (4 archivos)
- [x] Documentar arquitectura (3 archivos)

### Fase 2: Completar Refactorización (⏳ PENDIENTE)
- [ ] Refactorizar `app/api/requests/[id]/route.ts`
- [ ] Refactorizar `app/api/requests/[id]/match/route.ts`
- [ ] Refactorizar `app/api/matches/[id]/route.ts`
- [ ] Refactorizar `app/api/matches/[id]/result/route.ts`
- [ ] Refactorizar `app/api/teams/[id]/stats/route.ts`
- [ ] Refactorizar `app/api/public/requests/route.ts`
- [ ] Refactorizar `app/api/public/requests/[id]/route.ts`

### Fase 3: Limpieza (⏳ PENDIENTE)
- [ ] Revisar `lib/services/teams.service.ts` (decidir mantener/eliminar)
- [ ] Revisar `lib/services/requests.service.ts` (decidir mantener/eliminar)
- [ ] Revisar `lib/services/matches.service.ts` (decidir mantener/eliminar)
- [ ] Actualizar imports en componentes React si se eliminan servicios

### Fase 4: Testing y Validación (⏳ PENDIENTE)
- [ ] Probar endpoints refactorizados
- [ ] Verificar autorización en todos los endpoints
- [ ] Validar manejo de errores
- [ ] Probar flujo completo: crear equipo → crear solicitud → aceptar → registrar resultado
- [ ] Verificar que estadísticas se actualizan correctamente

### Fase 5: Documentación Final (⏳ PENDIENTE)
- [ ] Actualizar README.md con nueva arquitectura
- [ ] Crear ejemplos de uso de servicios
- [ ] Documentar endpoints de API (OpenAPI/Swagger opcional)
- [ ] Agregar comentarios JSDoc a métodos públicos

---

## 🎯 Próximos Pasos Recomendados

1. **Completar Fase 2:** Refactorizar las 7 rutas pendientes usando los servicios ya creados.

2. **Decidir sobre `lib/services/`:** 
   - Si solo hacen `fetch()`, eliminar y llamar directamente desde componentes.
   - Si tienen lógica, mantener.
   - Considerar migrar a React Query para mejor manejo de caché.

3. **Testing:**
   ```bash
   npm run build  # Verificar errores de TypeScript
   npm run dev    # Probar la aplicación
   ```

4. **Migración de datos (si aplica):**
   ```bash
   node scripts/migrate-to-mysql.js
   ```

---

## 📞 Comando Rápido de Revisión

```bash
# Ver todos los archivos nuevos
git status --porcelain | grep "^??"

# Ver todos los archivos modificados
git status --porcelain | grep "^ M"

# Contar líneas de código agregadas
find lib/repositories lib/services-server -name "*.ts" | xargs wc -l
```

---

**Fecha de creación:** [Fecha actual]  
**Última actualización:** [Fecha actual]  
**Versión:** 1.0.0
