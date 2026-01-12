# 💾 Guía del Volumen de Base de Datos

## 📍 Ubicación del Volumen

El volumen de PostgreSQL se almacena en el disco del servidor usando el driver local de Docker. Por defecto, Docker almacena los volúmenes en:

```bash
/var/lib/docker/volumes/cynthia_postgres_data/_data
```

## 🔍 Verificar el Volumen

### Ver información del volumen

```bash
# Listar todos los volúmenes
docker volume ls

# Ver detalles del volumen específico
docker volume inspect cynthia_postgres_data

# Ver el tamaño del volumen
docker system df -v | grep postgres_data
```

### Ver la ubicación física

```bash
# Ver dónde está montado el volumen
docker volume inspect cynthia_postgres_data | grep Mountpoint
```

## 📊 Monitorear el Tamaño

```bash
# Ver tamaño de todos los volúmenes
docker system df

# Ver tamaño específico del volumen de BD
du -sh /var/lib/docker/volumes/cynthia_postgres_data/_data
```

## 💾 Backups del Volumen

### Opción 1: Backup usando pg_dump (Recomendado)

Este es el método recomendado porque:
- ✅ Solo respalda los datos, no archivos temporales
- ✅ Es más rápido
- ✅ Puedes restaurar en cualquier versión de PostgreSQL
- ✅ Puedes restaurar en Managed Database si migras

```bash
# Usar el script incluido
./backup.sh

# O manualmente
docker-compose exec postgres pg_dump -U periti_user periti_ia | gzip > backup.sql.gz
```

### Opción 2: Backup del volumen completo

Si necesitas hacer un backup completo del volumen (incluye archivos temporales, logs, etc.):

```bash
# Detener el contenedor
docker-compose stop postgres

# Hacer backup del volumen
sudo tar -czf postgres_volume_backup_$(date +%Y%m%d).tar.gz \
  /var/lib/docker/volumes/cynthia_postgres_data/_data

# Reiniciar el contenedor
docker-compose start postgres
```

## 🔄 Restaurar desde Backup

### Restaurar desde pg_dump

```bash
# Restaurar desde backup comprimido
gunzip < backup_20240101_120000.sql.gz | \
  docker-compose exec -T postgres psql -U periti_user -d periti_ia

# O desde backup sin comprimir
docker-compose exec -T postgres psql -U periti_user -d periti_ia < backup.sql
```

### Restaurar volumen completo

```bash
# ⚠️ CUIDADO: Esto reemplazará todos los datos actuales

# Detener el contenedor
docker-compose stop postgres

# Eliminar el volumen actual
docker volume rm cynthia_postgres_data

# Restaurar desde backup
sudo tar -xzf postgres_volume_backup_20240101.tar.gz -C /

# Reiniciar el contenedor
docker-compose start postgres
```

## 🗑️ Eliminar el Volumen

### Eliminar solo los datos (mantener la estructura)

```bash
# Detener el contenedor
docker-compose stop postgres

# Eliminar el volumen
docker volume rm cynthia_postgres_data

# Reiniciar (creará un nuevo volumen vacío)
docker-compose up -d postgres
```

### Eliminar todo (contenedores + volúmenes)

```bash
# ⚠️ CUIDADO: Esto elimina TODO, incluyendo la base de datos
docker-compose down -v
```

## 📈 Migrar a Otro Servidor

Si necesitas mover la base de datos a otro servidor:

### Método 1: Usando pg_dump (Recomendado)

```bash
# En el servidor origen
docker-compose exec postgres pg_dump -U periti_user periti_ia | gzip > backup.sql.gz

# Transferir el archivo al nuevo servidor
scp backup.sql.gz usuario@nuevo-servidor:/ruta/destino/

# En el nuevo servidor
gunzip < backup.sql.gz | docker-compose exec -T postgres psql -U periti_user -d periti_ia
```

### Método 2: Copiar el volumen completo

```bash
# En el servidor origen
docker-compose stop postgres
sudo tar -czf postgres_volume.tar.gz /var/lib/docker/volumes/cynthia_postgres_data/_data

# Transferir al nuevo servidor
scp postgres_volume.tar.gz usuario@nuevo-servidor:/ruta/destino/

# En el nuevo servidor
docker-compose stop postgres
sudo tar -xzf postgres_volume.tar.gz -C /
docker-compose start postgres
```

## 🔧 Cambiar la Ubicación del Volumen

Si quieres almacenar el volumen en otra ubicación (por ejemplo, un disco externo):

### Opción 1: Usar bind mount en docker-compose.yml

Edita `docker-compose.yml`:

```yaml
services:
  postgres:
    # ... otras configuraciones ...
    volumes:
      - /ruta/personalizada/postgres_data:/var/lib/postgresql/data
      # En lugar de:
      # - postgres_data:/var/lib/postgresql/data
```

### Opción 2: Crear volumen con ubicación específica

```bash
# Crear volumen en ubicación específica
docker volume create --driver local \
  --opt type=none \
  --opt device=/ruta/personalizada/postgres_data \
  --opt o=bind \
  cynthia_postgres_data

# Luego usar en docker-compose.yml normalmente
```

## ⚠️ Importante

1. **Backups regulares**: Haz backups regulares usando `./backup.sh` o configúralo con cron
2. **Espacio en disco**: Monitorea el espacio en disco del servidor
3. **No eliminar sin backup**: Nunca elimines el volumen sin hacer backup primero
4. **Permisos**: El volumen es propiedad de root, necesitas sudo para acceder directamente

## 📅 Configurar Backups Automáticos

Agrega a crontab para backups diarios:

```bash
# Editar crontab
crontab -e

# Agregar línea para backup diario a las 2 AM
0 2 * * * cd /opt/cynthia && ./backup.sh >> /var/log/cynthia-backup.log 2>&1
```

## 🔍 Verificar Integridad de la Base de Datos

```bash
# Verificar la base de datos
docker-compose exec postgres psql -U periti_user -d periti_ia -c "SELECT pg_database_size('periti_ia');"

# Ver tablas y su tamaño
docker-compose exec postgres psql -U periti_user -d periti_ia -c "
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```
