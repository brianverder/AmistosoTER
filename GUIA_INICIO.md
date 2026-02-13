# 🚀 Guía de Inicio Rápido - Tercer Tiempo

## 📋 Pre-requisitos

- Node.js 18 o superior
- npm o yarn

## 🛠️ Instalación y Configuración

### 1. Instalar dependencias

```bash
npm install
```

### 2. Configurar base de datos

El archivo `.env` ya está configurado para usar SQLite en desarrollo.

```bash
# Generar cliente de Prisma
npx prisma generate

# Crear/actualizar la base de datos
npx prisma db push
```

### 3. Iniciar el servidor de desarrollo

```bash
npm run dev
```

La aplicación estará disponible en [http://localhost:3000](http://localhost:3000)

## 📱 Uso de la Aplicación

### Primera vez

1. **Registrarse**: Ve a `/register` o haz clic en "Regístrate" desde la página de login
2. **Completar datos**: Ingresa tu nombre, email, contraseña y opcionalmente tu teléfono
3. **Iniciar sesión**: Usa tus credenciales para acceder

### Flujo Principal

#### 1. Crear un Equipo
- Navega a "Mis Equipos"
- Clic en "➕ Nuevo Equipo"
- Ingresa el nombre de tu equipo
- El equipo aparecerá en tu lista con estadísticas en 0

#### 2. Publicar una Solicitud de Partido
- Ve a "Solicitudes"
- Clic en "➕ Nueva Solicitud"
- Completa los campos (solo el equipo es obligatorio):
  - Equipo solicitante
  - Tipo de fútbol (11, 7, 5, futsal)
  - Dirección de la cancha
  - Precio
  - Fecha y hora
  - Descripción/notas
- La solicitud aparecerá como "Activa"

#### 3. Buscar y Hacer Match
- En "Solicitudes", ve a la pestaña "🔍 Disponibles"
- Explora las solicitudes de otros usuarios
- Clic en "🤝 Hacer Match" en la solicitud que te interese
- Selecciona uno de tus equipos
- Confirma el match
- Serás redirigido a la página de detalles del match

#### 4. Coordinar el Partido
- En la página del match verás:
  - Los equipos que participan
  - Información del partido
  - Datos de contacto del rival
- Coordina con el rival por email/teléfono

#### 5. Registrar el Resultado
- Después del partido, ve a "Matches"
- Abre el match correspondiente
- En el formulario lateral, ingresa los marcadores:
  - Goles del Equipo 1
  - Goles del Equipo 2
- Clic en "✅ Guardar Resultado"
- Las estadísticas se actualizarán automáticamente

#### 6. Ver Estadísticas
- Ve a "Estadísticas" para ver:
  - Resumen general de todos tus equipos
  - Partidos jugados, ganados, perdidos, empatados
  - Porcentaje de efectividad
  - Estadísticas individuales por equipo
  - Gráficos de rendimiento

## 🎯 Características Principales

### ✅ Completadas

- **Autenticación**: Registro e inicio de sesión seguro
- **Gestión de Equipos**: CRUD completo (crear, ver, editar, eliminar)
- **Solicitudes de Partidos**: Publicar y buscar partidos amistosos
- **Sistema de Match**: Conectar dos equipos para coordinar un partido
- **Registro de Resultados**: Guardar marcadores y determinar ganador
- **Estadísticas Automáticas**: 
  - Por equipo: partidos ganados, perdidos, empatados
  - Globales: resumen de todos los equipos del usuario
  - Porcentaje de efectividad
- **Dashboard Interactivo**: Acceso rápido a todas las funcionalidades
- **Diseño Responsivo**: Funciona en desktop, tablet y móvil
- **UI Deportiva**: Diseño minimalista en blanco y negro con acentos verdes

## 🗂️ Estructura de Archivos Principales

```
├── app/
│   ├── api/                    # API Routes
│   │   ├── auth/              # Autenticación (register, nextauth)
│   │   ├── teams/             # CRUD de equipos
│   │   ├── requests/          # CRUD de solicitudes
│   │   └── matches/           # Gestión de matches y resultados
│   ├── dashboard/             # Páginas del dashboard
│   │   ├── teams/            # Gestión de equipos
│   │   ├── requests/         # Solicitudes de partidos
│   │   ├── matches/          # Matches coordinados
│   │   └── stats/            # Estadísticas
│   ├── login/                 # Página de login
│   ├── register/              # Página de registro
│   └── globals.css           # Estilos globales
├── components/
│   └── DashboardNav.tsx      # Navegación del dashboard
├── lib/
│   ├── auth.ts               # Configuración de NextAuth
│   └── prisma.ts             # Cliente de Prisma
├── prisma/
│   └── schema.prisma         # Modelos de base de datos
└── types/
    └── next-auth.d.ts        # Tipos de TypeScript para NextAuth
```

## 🔧 Comandos Útiles

```bash
# Instalar dependencias
npm install

# Desarrollo
npm run dev

# Producción
npm run build
npm start

# Linting
npm run lint

# Prisma
npx prisma studio          # Abrir UI de base de datos
npx prisma db push         # Sincronizar schema con BD
npx prisma generate        # Generar cliente
npx prisma migrate dev     # Crear migración (para producción)
```

## 🎨 Guía de Estilos

La aplicación usa Tailwind CSS con clases personalizadas:

- **Botones**: `.btn-primary`, `.btn-secondary`, `.btn-accent`, `.btn-danger`
- **Cards**: `.card`
- **Inputs**: `.input` con `.label`
- **Container**: `.container-custom`

Colores principales:
- Primary (Negro): `#000000`
- Secondary (Blanco): `#ffffff`
- Accent (Verde): `#22c55e`
- Danger (Rojo): `#ef4444`

## 🐛 Solución de Problemas

### Error: Prisma Client not generated
```bash
npx prisma generate
```

### Error: Database connection
Verifica que el archivo `.env` existe y contiene la variable `DATABASE_URL`

### Error al hacer login
Asegúrate de haber ejecutado `npx prisma db push` para crear las tablas

### Puerto 3000 en uso
```bash
# Cambiar el puerto
PORT=3001 npm run dev
```

## 📝 Notas Importantes

- **SQLite en desarrollo**: La base de datos se guarda en `prisma/dev.db`
- **Cambiar a PostgreSQL en producción**: Actualiza `DATABASE_URL` en `.env` y el provider en `schema.prisma`
- **NEXTAUTH_SECRET**: Cambia este valor antes de desplegar a producción
- **Datos de prueba**: Los usuarios pueden crear múltiples equipos
- **Validaciones**: Todos los formularios tienen validación en cliente y servidor

## 🚀 Despliegue a Producción

### Vercel (Recomendado)

1. Instala Vercel CLI: `npm i -g vercel`
2. Configura una base de datos PostgreSQL (ej: Vercel Postgres, Supabase)
3. Actualiza `schema.prisma` cambiando `provider = "sqlite"` a `provider = "postgresql"`
4. Configura variables de entorno en Vercel:
   - `DATABASE_URL`
   - `NEXTAUTH_URL`
   - `NEXTAUTH_SECRET`
5. Despliega: `vercel --prod`

## 📧 Soporte

Para cualquier duda o problema, revisa:
- La documentación de [Next.js](https://nextjs.org/docs)
- La documentación de [Prisma](https://www.prisma.io/docs)
- La documentación de [NextAuth.js](https://next-auth.js.org/)

---

¡Disfruta organizando tus partidos amistosos con **Tercer Tiempo**! ⚽🎉
