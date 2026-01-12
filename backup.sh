#!/bin/bash
set -e

# Cambiar al directorio del script
cd "$(dirname "$0")"

# Cargar variables de entorno si existe .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Configuración (usar variables de entorno o valores por defecto)
BACKUP_DIR="${BACKUP_DIR:-./backups}"
DB_USER="${DB_USER:-periti_user}"
DB_NAME="${DB_NAME:-periti_ia}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.sql.gz"
RETENTION_DAYS=7

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

# Verificar que el contenedor esté corriendo
if ! docker-compose ps postgres | grep -q "Up"; then
    echo "❌ Error: El contenedor de PostgreSQL no está corriendo"
    echo "   Ejecuta: docker-compose up -d postgres"
    exit 1
fi

echo "🗄️ Iniciando backup de la base de datos..."
echo "   Usuario: $DB_USER"
echo "   Base de datos: $DB_NAME"
echo "   Destino: $BACKUP_FILE"

# Hacer backup
docker-compose exec -T postgres pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup creado exitosamente: $BACKUP_FILE"
    
    # Obtener tamaño del archivo
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "📦 Tamaño del backup: $SIZE"
    
    # Eliminar backups antiguos (mantener solo los últimos N días)
    echo "🧹 Limpiando backups antiguos (más de $RETENTION_DAYS días)..."
    find "$BACKUP_DIR" -name "backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
    
    echo "✅ Proceso de backup completado"
else
    echo "❌ Error al crear el backup"
    exit 1
fi
