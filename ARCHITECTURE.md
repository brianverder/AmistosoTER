# 🏗️ Arquitectura del Proyecto - Tercer Tiempo

## 📁 Estructura de Carpetas

```
tercer-tiempo/
│
├── app/                          # Next.js App Router
│   ├── (auth)/                   # Grupo de rutas de autenticación
│   │   ├── login/
│   │   └── register/
│   ├── (public)/                 # Grupo de rutas públicas
│   │   └── partidos/
│   ├── (dashboard)/              # Grupo de rutas protegidas
│   │   ├── dashboard/
│   │   ├── teams/
│   │   ├── requests/
│   │   ├── matches/
│   │   ├── stats/
│   │   └── help/
│   ├── api/                      # API Routes
│   │   ├── auth/
│   │   ├── teams/
│   │   ├── requests/
│   │   ├── matches/
│   │   ├── public/
│   │   ├── notifications/        # 🔮 Preparado para futuro
│   │   ├── payments/             # 🔮 Preparado para futuro
│   │   └── chat/                 # 🔮 Preparado para futuro
│   ├── layout.tsx
│   └── globals.css
│
├── components/                   # Componentes React
│   ├── ui/                       # Componentes base reutilizables
│   │   ├── Button.tsx
│   │   ├── Badge.tsx
│   │   ├── Card.tsx
│   │   ├── Input.tsx
│   │   ├── Modal.tsx
│   │   ├── Dropdown.tsx
│   │   └── index.ts
│   ├── layout/                   # Componentes de layout
│   │   ├── DashboardNav.tsx
│   │   ├── PublicHeader.tsx
│   │   ├── Footer.tsx
│   │   └── Sidebar.tsx
│   ├── features/                 # Componentes específicos de features
│   │   ├── teams/
│   │   │   ├── TeamCard.tsx
│   │   │   ├── TeamForm.tsx
│   │   │   └── TeamStats.tsx
│   │   ├── matches/
│   │   │   ├── MatchCard.tsx
│   │   │   ├── MatchResultForm.tsx
│   │   │   └── MatchStatusBadge.tsx
│   │   ├── requests/
│   │   │   ├── RequestCard.tsx
│   │   │   ├── RequestForm.tsx
│   │   │   └── RequestFilters.tsx
│   │   └── stats/
│   │       ├── StatCard.tsx
│   │       └── StatChart.tsx
│   └── shared/                   # Componentes compartidos
│       ├── LoadingSpinner.tsx
│       ├── EmptyState.tsx
│       └── ErrorBoundary.tsx
│
├── lib/                          # Lógica de negocio y utilidades
│   ├── services/                 # Servicios de API y lógica de negocio
│   │   ├── teams.service.ts
│   │   ├── matches.service.ts
│   │   ├── requests.service.ts
│   │   ├── auth.service.ts
│   │   ├── notifications.service.ts   # 🔮 Preparado para futuro
│   │   ├── payments.service.ts        # 🔮 Preparado para futuro
│   │   └── chat.service.ts            # 🔮 Preparado para futuro
│   ├── hooks/                    # Custom React Hooks
│   │   ├── useTeams.ts
│   │   ├── useMatches.ts
│   │   ├── useRequests.ts
│   │   ├── useAuth.ts
│   │   ├── useNotifications.ts        # 🔮 Preparado para futuro
│   │   ├── usePayments.ts             # 🔮 Preparado para futuro
│   │   ├── useChat.ts                 # 🔮 Preparado para futuro
│   │   └── index.ts
│   ├── types/                    # TypeScript Types
│   │   ├── team.types.ts
│   │   ├── match.types.ts
│   │   ├── request.types.ts
│   │   ├── user.types.ts
│   │   ├── notification.types.ts      # 🔮 Preparado para futuro
│   │   ├── payment.types.ts           # 🔮 Preparado para futuro
│   │   ├── chat.types.ts              # 🔮 Preparado para futuro
│   │   └── index.ts
│   ├── utils/                    # Funciones utilitarias
│   │   ├── formatters.ts
│   │   ├── validators.ts
│   │   ├── constants.ts
│   │   └── helpers.ts
│   ├── config/                   # Configuración
│   │   ├── app.config.ts
│   │   └── env.ts
│   ├── auth.ts                   # NextAuth config
│   └── prisma.ts                 # Prisma client
│
├── prisma/                       # Prisma ORM
│   ├── schema.prisma
│   └── migrations/
│
├── public/                       # Archivos estáticos
│   └── images/
│
└── docs/                         # Documentación
    ├── ARCHITECTURE.md           # Este archivo
    ├── API.md
    └── FEATURES.md
```

---

## 🎯 Principios de Arquitectura

### 1. **Separación de Responsabilidades**
- **Presentación** (components/): Solo UI y lógica de presentación
- **Lógica de Negocio** (lib/services/): Lógica de dominio y comunicación con API
- **Estado** (lib/hooks/): Gestión de estado y side effects
- **Tipos** (lib/types/): Definiciones de TypeScript centralizadas

### 2. **Reutilización**
- Componentes UI base en `components/ui/`
- Hooks personalizados en `lib/hooks/`
- Servicios compartidos en `lib/services/`
- Utilidades en `lib/utils/`

### 3. **Escalabilidad**
- Estructura modular por features
- Servicios preparados para futuras funcionalidades
- Tipos extensibles
- Configuración centralizada

### 4. **Mantenibilidad**
- Naming consistente y descriptivo
- Barrel exports (`index.ts`) para importaciones limpias
- Documentación inline (JSDoc)
- Separación clara de concerns

---

## 🧩 Capas de la Aplicación

### **Capa de Presentación** (Components)
```
components/
├── ui/              → Componentes atómicos reutilizables
├── layout/          → Estructura de páginas
├── features/        → Componentes específicos de dominio
└── shared/          → Componentes compartidos entre features
```

**Responsabilidades:**
- Renderizar UI
- Manejar interacciones del usuario
- Delegar lógica a hooks y servicios

**Ejemplo:**
```tsx
// components/features/teams/TeamCard.tsx
import { Card, Badge } from '@/components/ui';
import { Team } from '@/lib/types';

export function TeamCard({ team }: { team: Team }) {
  return (
    <Card>
      <h3>{team.name}</h3>
      <Badge text={`${team.gamesWon} victorias`} />
    </Card>
  );
}
```

---

### **Capa de Lógica de Negocio** (Services)
```
lib/services/
├── teams.service.ts      → CRUD y lógica de equipos
├── matches.service.ts    → Gestión de partidos
├── requests.service.ts   → Solicitudes de matches
└── [future].service.ts   → Servicios futuros
```

**Responsabilidades:**
- Comunicación con API
- Transformación de datos
- Validaciones de negocio
- Cálculos y agregaciones

**Ejemplo:**
```typescript
// lib/services/teams.service.ts
export class TeamsService {
  static async getUserTeams(): Promise<Team[]> {
    const response = await fetch('/api/teams');
    if (!response.ok) throw new Error('Error');
    return response.json();
  }
  
  static calculateWinRate(team: Team): number {
    if (team.totalGames === 0) return 0;
    return (team.gamesWon / team.totalGames) * 100;
  }
}
```

---

### **Capa de Estado** (Hooks)
```
lib/hooks/
├── useTeams.ts       → Estado y acciones de equipos
├── useMatches.ts     → Estado y acciones de partidos
└── useRequests.ts    → Estado y acciones de solicitudes
```

**Responsabilidades:**
- Gestión de estado local
- Side effects (fetch, subscriptions)
- Exponer API simple a componentes
- Manejo de loading/error states

**Ejemplo:**
```typescript
// lib/hooks/useTeams.ts
export function useTeams() {
  const [teams, setTeams] = useState<Team[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchTeams = async () => {
    const data = await TeamsService.getUserTeams();
    setTeams(data);
  };

  return { teams, loading, fetchTeams, createTeam, deleteTeam };
}
```

---

### **Capa de Tipos** (Types)
```
lib/types/
├── team.types.ts         → Domain models de equipos
├── match.types.ts        → Domain models de partidos
├── request.types.ts      → Domain models de solicitudes
└── [future].types.ts     → Tipos para futuras features
```

**Responsabilidades:**
- Definir contratos de datos
- Documentar estructuras
- Type safety en toda la app

**Ejemplo:**
```typescript
// lib/types/team.types.ts
export interface Team {
  id: string;
  name: string;
  gamesWon: number;
  // ...
}

export interface CreateTeamDTO {
  name: string;
}
```

---

### **Capa de Utilidades** (Utils)
```
lib/utils/
├── formatters.ts     → Formateo de fechas, moneda, etc.
├── validators.ts     → Validaciones comunes
├── constants.ts      → Constantes globales
└── helpers.ts        → Funciones auxiliares
```

**Responsabilidades:**
- Funciones puras y reutilizables
- Sin side effects
- Sin dependencias de estado

---

## 🔮 Preparación para Futuras Features

### **1. Sistema de Notificaciones**
```typescript
// lib/types/notification.types.ts
export interface Notification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  message: string;
  read: boolean;
  // ...
}

// lib/services/notifications.service.ts
export class NotificationsService {
  static async getNotifications(): Promise<Notification[]> { /* ... */ }
  static async markAsRead(id: string): Promise<void> { /* ... */ }
}

// lib/hooks/useNotifications.ts
export function useNotifications() {
  // Estado, fetch, mark as read, etc.
}
```

**Rutas preparadas:**
- `app/api/notifications/route.ts`
- `app/dashboard/notifications/page.tsx`

---

### **2. Sistema de Pagos**
```typescript
// lib/types/payment.types.ts
export interface Payment {
  id: string;
  amount: number;
  status: PaymentStatus;
  method: PaymentMethod;
  // ...
}

// lib/services/payments.service.ts
export class PaymentsService {
  static async createPayment(data: CreatePaymentDTO): Promise<Payment> { /* ... */ }
  static async getPaymentHistory(): Promise<Payment[]> { /* ... */ }
}

// lib/hooks/usePayments.ts
export function usePayments() {
  // Estado, create, refund, history, etc.
}
```

**Rutas preparadas:**
- `app/api/payments/route.ts`
- `app/dashboard/payments/page.tsx`

---

### **3. Sistema de Chat**
```typescript
// lib/types/chat.types.ts
export interface Message {
  id: string;
  conversationId: string;
  senderId: string;
  content: string;
  // ...
}

// lib/services/chat.service.ts
export class ChatService {
  static async getConversations(): Promise<Conversation[]> { /* ... */ }
  static async sendMessage(data: SendMessageDTO): Promise<Message> { /* ... */ }
}

// lib/hooks/useChat.ts
export function useChat(conversationId: string) {
  // Estado, messages, send, typing, etc.
}
```

**Rutas preparadas:**
- `app/api/chat/route.ts`
- `app/dashboard/chat/page.tsx`

---

## 📚 Convenciones de Naming

### **Archivos**
- Componentes: `PascalCase.tsx` (TeamCard.tsx)
- Hooks: `camelCase.ts` con prefijo `use` (useTeams.ts)
- Servicios: `camelCase.service.ts` (teams.service.ts)
- Tipos: `camelCase.types.ts` (team.types.ts)
- Utilidades: `camelCase.ts` (formatters.ts)

### **Variables y Funciones**
- Variables: `camelCase` (matchRequest, teamList)
- Funciones: `camelCase` (fetchTeams, calculateWinRate)
- Constantes: `UPPER_SNAKE_CASE` (API_ROUTES, MAX_FILE_SIZE)
- Componentes: `PascalCase` (TeamCard, MatchList)
- Tipos/Interfaces: `PascalCase` (Team, MatchRequest)

### **Clases de Servicios**
- Servicios: `PascalCase` con sufijo `Service` (TeamsService)
- Métodos estáticos para servicios stateless
- Instancias para servicios con estado (websockets, etc.)

---

## 🔄 Flujo de Datos

```
User Interaction
      ↓
Component (UI Layer)
      ↓
Hook (State Layer)
      ↓
Service (Business Logic Layer)
      ↓
API Route (Backend)
      ↓
Database (Prisma)
```

**Ejemplo Completo:**
```tsx
// 1. Usuario hace clic en botón
<Button onClick={handleCreate}>Crear Equipo</Button>

// 2. Componente llama al hook
const { createTeam } = useTeams();
await createTeam('Arsenal FC');

// 3. Hook llama al servicio
const team = await TeamsService.createTeam({ name: 'Arsenal FC' });

// 4. Servicio hace fetch a API
const response = await fetch('/api/teams', { method: 'POST', ... });

// 5. API route procesa y guarda en DB
await prisma.team.create({ data: { name: 'Arsenal FC', ... } });

// 6. Respuesta viaja de vuelta al usuario
```

---

## ✅ Ventajas de Esta Arquitectura

1. **Escalable**: Fácil agregar nuevas features sin reestructurar
2. **Testeable**: Cada capa puede testearse independientemente
3. **Mantenible**: Separación clara de responsabilidades
4. **Reutilizable**: Componentes y lógica reutilizables
5. **Type-Safe**: TypeScript en todas las capas
6. **DRY**: No repetir código, usar abstracciones
7. **Legible**: Naming consistente y estructura predecible

---

## 🚀 Próximos Pasos para Nuevas Features

1. **Definir tipos** en `lib/types/[feature].types.ts`
2. **Crear servicio** en `lib/services/[feature].service.ts`
3. **Crear hook** en `lib/hooks/use[Feature].ts`
4. **Crear API route** en `app/api/[feature]/route.ts`
5. **Crear componentes UI** en `components/features/[feature]/`
6. **Crear página** en `app/dashboard/[feature]/page.tsx`

---

## 📖 Recursos Adicionales

- [Next.js App Router](https://nextjs.org/docs/app)
- [Prisma ORM](https://www.prisma.io/docs)
- [NextAuth.js](https://next-auth.js.org)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [TypeScript](https://www.typescriptlang.org/docs)

---

**Última actualización:** Febrero 2026
**Versión:** 1.0.0
