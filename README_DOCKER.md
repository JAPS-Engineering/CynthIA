# 🐳 Guía Rápida de Docker para CynthIA

Esta es una guía rápida para levantar CynthIA con Docker en tu entorno local o servidor.

## 📋 Requisitos Previos

- Docker instalado
- Docker Compose instalado
- Git (para clonar el repositorio)

## 🚀 Inicio Rápido

### 1. Configurar Variables de Entorno

```bash
# Copiar el archivo de ejemplo
cp env.example .env

# Editar con tus valores
nano .env
```

**Configuración mínima para desarrollo local:**

```env
DB_USER=periti_user
DB_PASSWORD=password123
DB_NAME=periti_ia

JWT_SECRET=tu-secret-key-super-segura-aqui-minimo-32-caracteres
JWT_EXPIRES_IN=7d

GEMINI_API_KEY=tu-gemini-api-key

FRONTEND_URL=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:3000/api
```

### 2. Construir y Levantar los Servicios

```bash
# Construir las imágenes
docker-compose build

# Levantar los servicios en segundo plano
docker-compose up -d

# Ver los logs
docker-compose logs -f
```

### 3. Verificar que Todo Funciona

```bash
# Ver estado de los contenedores
docker-compose ps

# Probar backend
curl http://localhost:3000/health

# Probar frontend
curl http://localhost:3001
```

### 4. Acceder a la Aplicación

- **Frontend**: http://localhost:3001
- **Backend API**: http://localhost:3000/api
- **Health Check**: http://localhost:3000/health

## 📝 Comandos Útiles

### Ver Logs

```bash
# Todos los servicios
docker-compose logs -f

# Solo un servicio
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f postgres
```

### Reiniciar Servicios

```bash
# Reiniciar todos
docker-compose restart

# Reiniciar uno específico
docker-compose restart backend
```

### Detener Servicios

```bash
# Detener sin eliminar
docker-compose stop

# Detener y eliminar contenedores
docker-compose down

# Detener, eliminar contenedores y volúmenes (¡CUIDADO! Elimina la BD)
docker-compose down -v
```

### Ejecutar Comandos en los Contenedores

```bash
# Entrar al contenedor del backend
docker-compose exec backend sh

# Ejecutar migraciones manualmente
docker-compose exec backend npx prisma migrate deploy

# Ejecutar seed de base de datos
docker-compose exec backend npm run prisma:seed

# Ver base de datos con Prisma Studio
docker-compose exec backend npm run prisma:studio
# Luego accede a http://localhost:5555
```

### Reconstruir Imágenes

```bash
# Reconstruir sin cache
docker-compose build --no-cache

# Reconstruir y levantar
docker-compose up -d --build
```

## 🗄️ Base de Datos

### Acceder a PostgreSQL

```bash
# Conectarse a la base de datos
docker-compose exec postgres psql -U periti_user -d periti_ia
```

### Hacer Backup

```bash
# Backup manual
docker-compose exec postgres pg_dump -U periti_user periti_ia > backup.sql
```

### Restaurar Backup

```bash
# Restaurar desde backup
cat backup.sql | docker-compose exec -T postgres psql -U periti_user -d periti_ia
```

## 🔧 Troubleshooting

### Los contenedores no inician

```bash
# Ver logs detallados
docker-compose logs

# Verificar configuración
docker-compose config

# Verificar que los puertos no estén en uso
netstat -tulpn | grep -E '3000|3001|5432'
```

### Error de conexión a base de datos

```bash
# Verificar que PostgreSQL está corriendo
docker-compose ps postgres

# Ver logs de PostgreSQL
docker-compose logs postgres

# Verificar variables de entorno
docker-compose exec backend env | grep DATABASE_URL
```

### Frontend no se conecta al backend

1. Verificar que `NEXT_PUBLIC_API_URL` en `.env` apunta a `http://localhost:3000/api`
2. Verificar que el backend está corriendo: `docker-compose ps backend`
3. Verificar logs del backend: `docker-compose logs backend`

### Limpiar Todo y Empezar de Nuevo

```bash
# ⚠️ CUIDADO: Esto elimina TODO, incluyendo la base de datos
docker-compose down -v
docker system prune -a
docker-compose build --no-cache
docker-compose up -d
```

## 📦 Estructura de Servicios

- **postgres**: Base de datos PostgreSQL (puerto 5432)
- **backend**: API Express (puerto 3000)
- **frontend**: Aplicación Next.js (puerto 3001)

Todos los servicios están en la misma red Docker (`cynthia_network`) y se comunican usando los nombres de los servicios como hostnames.

## 🔄 Actualizar la Aplicación

Si usas el script de deployment:

```bash
./deploy.sh
```

O manualmente:

```bash
git pull
docker-compose build
docker-compose up -d
docker-compose exec backend npx prisma migrate deploy
```

## 📚 Más Información

Para deployment en producción, consulta [DEPLOYMENT.md](./DEPLOYMENT.md)
