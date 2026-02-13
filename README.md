# Tercer Tiempo

Plataforma web para coordinar partidos amistosos de fútbol amateur.

## 🚀 Características

- Autenticación de usuarios con NextAuth
- Gestión de equipos por usuario
- Publicación de solicitudes de partidos amistosos
- Sistema de match entre equipos
- Registro de resultados y estadísticas
- Diseño minimalista y deportivo

## 🛠️ Tecnologías

- Next.js 14 (App Router)
- React 18
- TypeScript
- Prisma ORM
- SQLite (desarrollo) / PostgreSQL (producción)
- Tailwind CSS
- NextAuth.js

## 📦 Instalación

1. Clonar el repositorio
2. Instalar dependencias:
```bash
npm install
```

3. Configurar variables de entorno:
```bash
cp .env.example .env
```

4. Generar cliente de Prisma y crear base de datos:
```bash
npx prisma generate
npx prisma db push
```

5. Iniciar servidor de desarrollo:
```bash
npm run dev
```

6. Abrir [http://localhost:3000](http://localhost:3000)

## 📁 Estructura del Proyecto

```
├── app/                    # App Router de Next.js 14
│   ├── (auth)/            # Rutas de autenticación
│   ├── (dashboard)/       # Rutas protegidas del dashboard
│   └── api/               # API Routes
├── components/            # Componentes reutilizables
├── lib/                   # Utilidades y configuraciones
├── prisma/               # Schemas y migraciones de Prisma
└── public/               # Archivos estáticos
```

## 🎯 Flujo de Usuario

1. Registro/Login de usuario
2. Creación de equipos
3. Publicación de solicitud de partido amistoso
4. Búsqueda y visualización de solicitudes
5. Match entre equipos
6. Coordinación del partido
7. Registro de resultado
8. Visualización de estadísticas

## 📄 Licencia

MIT
