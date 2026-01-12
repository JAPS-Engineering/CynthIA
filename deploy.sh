#!/bin/bash
set -e

echo "🚀 Iniciando deployment de CynthIA..."

# Cambiar al directorio del proyecto
cd "$(dirname "$0")"

# Pull latest changes
echo "📥 Obteniendo últimos cambios..."
git pull origin main || git pull origin master

# Rebuild containers
echo "🔨 Construyendo contenedores..."
docker-compose build --no-cache

# Restart services
echo "🔄 Reiniciando servicios..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Esperando que los servicios estén listos..."
sleep 10

# Run migrations
echo "🗄️ Ejecutando migraciones..."
docker-compose exec -T backend npx prisma migrate deploy || echo "⚠️ Error en migraciones, verifica manualmente"

# Generate Prisma client
echo "🔧 Generando cliente de Prisma..."
docker-compose exec -T backend npx prisma generate || echo "⚠️ Error generando Prisma client"

# Clean up old images
echo "🧹 Limpiando imágenes antiguas..."
docker image prune -f

# Show status
echo ""
echo "✅ Deployment completado!"
echo ""
echo "📊 Estado de los servicios:"
docker-compose ps

echo ""
echo "📝 Logs recientes:"
docker-compose logs --tail=20
