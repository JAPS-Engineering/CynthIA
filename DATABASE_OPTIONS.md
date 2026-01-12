# 🗄️ Opciones de Base de Datos para CynthIA

Tienes dos opciones para la base de datos en Digital Ocean:

## Opción 1: Base de Datos en Contenedor Docker (Incluida)

### ✅ Ventajas
- **Gratis**: No hay costo adicional
- **Fácil de configurar**: Ya está incluida en `docker-compose.yml`
- **Rápida de levantar**: Todo funciona con un solo comando
- **Perfecta para desarrollo y pruebas**

### ⚠️ Desventajas
- **Sin backups automáticos**: Debes hacerlos manualmente
- **Menos escalable**: Limitada por los recursos del Droplet
- **Mantenimiento manual**: Tú eres responsable de las actualizaciones
- **Riesgo de pérdida de datos**: Si se elimina el volumen, se pierden los datos

### 📝 Configuración

Ya está configurada en `docker-compose.yml`. Solo necesitas:

1. Configurar las variables en `.env`:
```env
DB_USER=periti_user
DB_PASSWORD=tu_password_segura
DB_NAME=periti_ia
```

2. Levantar los servicios:
```bash
docker-compose up -d
```

### 💾 Backups Manuales

Usa el script incluido:
```bash
./backup.sh
```

O manualmente:
```bash
docker-compose exec postgres pg_dump -U periti_user periti_ia > backup.sql
```

---

## Opción 2: Managed Database de Digital Ocean (Recomendado para Producción)

### ✅ Ventajas
- **Backups automáticos**: Backups diarios automáticos
- **Alta disponibilidad**: Configuración de réplicas
- **Escalable**: Puedes aumentar recursos fácilmente
- **Mantenimiento automático**: Digital Ocean maneja las actualizaciones
- **Monitoreo**: Dashboard con métricas y alertas
- **Seguridad**: Firewall integrado y conexiones SSL

### ⚠️ Desventajas
- **Costo adicional**: ~$15/mes para el plan básico
- **Configuración adicional**: Requiere algunos pasos extra
- **Dependencia externa**: Dependes del servicio de Digital Ocean

### 📝 Configuración Paso a Paso

#### 1. Crear Managed Database en Digital Ocean

1. Ve a tu panel de Digital Ocean
2. Click en "Databases" → "Create Database Cluster"
3. Configuración recomendada:
   - **Engine**: PostgreSQL 15
   - **Plan**: Basic ($15/mes) o Professional según necesidades
   - **Region**: Misma región que tu Droplet
   - **Database Name**: `periti_ia` (o el que prefieras)
   - **User**: `periti_user` (o el que prefieras)

4. Anota las credenciales que te proporcionan

#### 2. Configurar Firewall

1. En la configuración de la base de datos, ve a "Trusted Sources"
2. Agrega tu Droplet como fuente permitida:
   - Selecciona tu Droplet de la lista, O
   - Agrega la IP de tu Droplet manualmente

#### 3. Obtener Connection String

1. En la configuración de la base de datos, ve a "Connection Details"
2. Copia la "Connection String" que se ve así:
```
postgresql://periti_user:password@db-postgresql-nyc3-12345.db.ondigitalocean.com:25060/periti_ia?sslmode=require
```

#### 4. Actualizar docker-compose.yml

Tienes dos opciones:

**Opción A: Comentar el servicio postgres**

Edita `docker-compose.yml` y comenta el servicio postgres:

```yaml
services:
  # postgres:
  #   image: postgres:15-alpine
  #   ... (comentar todo el servicio)

  backend:
    # ... resto de la configuración
    environment:
      DATABASE_URL: ${DATABASE_URL}  # Usar la variable directamente
```

**Opción B: Crear docker-compose.prod.yml**

Crea un archivo `docker-compose.prod.yml` que extienda el original:

```yaml
version: '3.8'

services:
  postgres:
    # Deshabilitar el servicio postgres
    profiles: ["never"]

  backend:
    environment:
      DATABASE_URL: ${DATABASE_URL}
```

Luego usa:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

#### 5. Actualizar archivo .env

```env
# Usar la connection string completa de Digital Ocean
DATABASE_URL=postgresql://periti_user:password@db-postgresql-nyc3-12345.db.ondigitalocean.com:25060/periti_ia?sslmode=require

# Ya no necesitas estas variables si usas la connection string completa
# DB_USER=periti_user
# DB_PASSWORD=tu_password
# DB_NAME=periti_ia
```

#### 6. Reiniciar Servicios

```bash
docker-compose down
docker-compose up -d
```

#### 7. Ejecutar Migraciones

```bash
docker-compose exec backend npx prisma migrate deploy
```

---

## 🤔 ¿Cuál Opción Elegir?

### Usa Base de Datos en Contenedor si:
- ✅ Estás empezando o en desarrollo
- ✅ Tienes un presupuesto limitado
- ✅ No necesitas alta disponibilidad
- ✅ Puedes hacer backups manuales regularmente
- ✅ Tu aplicación es pequeña/mediana

### Usa Managed Database si:
- ✅ Es una aplicación en producción
- ✅ Tienes usuarios que dependen del servicio
- ✅ Necesitas backups automáticos
- ✅ Quieres alta disponibilidad
- ✅ Prefieres que Digital Ocean maneje el mantenimiento
- ✅ Tienes presupuesto para el costo adicional

---

## 💰 Comparación de Costos

### Opción 1: Contenedor Docker
- **Costo**: $0 adicional
- **Total con Droplet básico**: ~$12-24/mes

### Opción 2: Managed Database
- **Costo de BD**: ~$15/mes (plan básico)
- **Total con Droplet básico**: ~$27-39/mes

---

## 🔄 Migrar de Contenedor a Managed Database

Si empiezas con contenedor y luego quieres migrar a Managed Database:

1. **Crear Managed Database** (ver pasos arriba)

2. **Hacer backup de la base de datos actual**:
```bash
docker-compose exec postgres pg_dump -U periti_user periti_ia > backup.sql
```

3. **Restaurar en Managed Database**:
```bash
# Conectarte a la managed database desde tu máquina local
psql "postgresql://user:pass@host:port/db?sslmode=require" < backup.sql

# O desde el servidor usando un cliente temporal
docker run --rm -i postgres:15-alpine psql "connection_string" < backup.sql
```

4. **Actualizar configuración** (ver pasos arriba)

5. **Reiniciar servicios**

---

## 📊 Recomendación Final

**Para empezar**: Usa la base de datos en contenedor. Es gratis y fácil de configurar.

**Para producción**: Migra a Managed Database cuando:
- Tengas usuarios reales
- Necesites garantías de disponibilidad
- Tengas presupuesto para el costo adicional

Puedes migrar en cualquier momento sin perder datos si haces el backup correctamente.
