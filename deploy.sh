#!/bin/bash
set -e

echo "🚀 Iniciando deployment de CynthIA..."

# Cambiar al directorio del proyecto
cd "$(dirname "$0")"

# Detectar si usar docker compose o docker-compose
if docker compose version > /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose version > /dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    echo "❌ Error: No se encontró docker compose ni docker-compose"
    exit 1
fi

# Pull latest changes
echo "📥 Obteniendo últimos cambios..."
git pull origin main || git pull origin master

# Rebuild containers
echo "🔨 Construyendo contenedores..."
$DOCKER_COMPOSE build --no-cache

# Restart services
echo "🔄 Reiniciando servicios..."
$DOCKER_COMPOSE up -d

# Wait for services to be ready
echo "⏳ Esperando que los servicios estén listos..."
sleep 15

# Wait for postgres to be healthy
echo "⏳ Esperando que PostgreSQL esté listo..."
timeout=60
counter=0
while [ $counter -lt $timeout ]; do
    if $DOCKER_COMPOSE ps postgres | grep -q "healthy"; then
        echo "✅ PostgreSQL está listo"
        break
    fi
    sleep 2
    counter=$((counter + 2))
done

# Wait for backend to be running (not restarting)
echo "⏳ Esperando que el backend esté listo..."
timeout=60
counter=0
backend_ready=false
while [ $counter -lt $timeout ]; do
    backend_status=$($DOCKER_COMPOSE ps backend 2>/dev/null | tail -n 1 | awk '{print $7}' || echo "")
    if echo "$backend_status" | grep -qE "Up|running"; then
        if ! echo "$backend_status" | grep -q "Restarting"; then
            echo "✅ Backend está ejecutándose"
            backend_ready=true
            sleep 5  # Dar un poco más de tiempo para que termine de inicializar
            break
        fi
    fi
    sleep 2
    counter=$((counter + 2))
done

if [ "$backend_ready" = false ]; then
    echo "⚠️ Backend no está listo después de $timeout segundos"
    echo "📋 Revisa los logs con: $DOCKER_COMPOSE logs backend"
else
    # Run migrations (opcional, ya que el backend las ejecuta automáticamente en start.sh)
    echo "🗄️ Ejecutando migraciones (opcional, el backend las ejecuta automáticamente)..."
    $DOCKER_COMPOSE exec -T backend npx prisma migrate deploy 2>/dev/null || echo "⚠️ Migraciones ya ejecutadas o error (el backend las ejecuta automáticamente)"
    
    # Generate Prisma client (opcional, ya que se genera en el build del Dockerfile)
    echo "🔧 Verificando cliente de Prisma (opcional, se genera en el build)..."
    $DOCKER_COMPOSE exec -T backend npx prisma generate 2>/dev/null || echo "⚠️ Cliente de Prisma ya generado o error (se genera en el build)"
fi

# Clean up old images
echo "🧹 Limpiando imágenes antiguas..."
docker image prune -f

# Show status
echo ""
echo "✅ Deployment completado!"
echo ""
echo "📊 Estado de los servicios:"
$DOCKER_COMPOSE ps

echo ""
echo "📝 Logs recientes:"
$DOCKER_COMPOSE logs --tail=20
