# 🚀 Guía de Deployment en Digital Ocean

Esta guía te ayudará a desplegar CynthIA en un Droplet de Digital Ocean usando Docker y Docker Compose.

## 📋 Tabla de Contenidos

1. [Preparación del Servidor](#preparación-del-servidor)
2. [Configuración de Base de Datos](#configuración-de-base-de-datos)
3. [Configuración del Proyecto](#configuración-del-proyecto)
4. [Deployment](#deployment)
5. [Configuración de Dominio y SSL](#configuración-de-dominio-y-ssl)
6. [Mantenimiento](#mantenimiento)

---

## 1. Preparación del Servidor

### 1.1 Crear Droplet en Digital Ocean

1. Ve a [Digital Ocean](https://www.digitalocean.com/)
2. Crea un nuevo Droplet:
   - **Imagen**: Ubuntu 22.04 LTS
   - **Plan**: Al menos 2GB RAM / 1 vCPU (recomendado: 4GB RAM para mejor rendimiento)
   - **Región**: Elige la más cercana a tus usuarios
   - **Autenticación**: SSH keys (recomendado) o password
   - **Hostname**: `cynthia-server` (o el que prefieras)

### 1.2 Conectarse al Servidor

```bash
ssh root@TU_IP_DEL_SERVIDOR
# O si usas un usuario:
ssh usuario@TU_IP_DEL_SERVIDOR
```

### 1.3 Actualizar el Sistema

```bash
sudo apt update && sudo apt upgrade -y
```

### 1.4 Instalar Docker y Docker Compose

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario actual al grupo docker (si no eres root)
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalación
docker --version
docker-compose --version
```

### 1.5 Instalar Git (si no está instalado)

```bash
sudo apt install git -y
```

---

## 2. Configuración de Base de Datos

Tienes dos opciones para la base de datos:

### Opción A: Base de Datos en Contenedor (Recomendado para empezar)

**Ventajas:**
- ✅ Más fácil de configurar
- ✅ No requiere configuración adicional
- ✅ Incluido en docker-compose.yml

**Desventajas:**
- ⚠️ Los datos se pierden si eliminas el volumen (a menos que hagas backups)
- ⚠️ Menos escalable

**Esta opción ya está configurada en el `docker-compose.yml`**, solo necesitas configurar las variables de entorno.

### Opción B: Base de Datos Managed de Digital Ocean (Recomendado para producción)

**Ventajas:**
- ✅ Backups automáticos
- ✅ Alta disponibilidad
- ✅ Escalable
- ✅ Mantenimiento automático

**Desventajas:**
- ⚠️ Costo adicional (~$15/mes para el plan básico)
- ⚠️ Requiere configuración adicional

#### Pasos para usar Managed Database:

1. **Crear Managed Database en Digital Ocean:**
   - Ve a tu panel de Digital Ocean
   - Crea una nueva base de datos PostgreSQL
   - Elige la misma región que tu Droplet
   - Anota la conexión string que te proporcionan

2. **Configurar Firewall:**
   - En la configuración de la base de datos, agrega tu Droplet como fuente permitida

3. **Actualizar docker-compose.yml:**
   - Comenta o elimina el servicio `postgres`
   - Actualiza `DATABASE_URL` en el archivo `.env` con la conexión string de Digital Ocean

---

## 3. Configuración del Proyecto

### 3.1 Clonar el Repositorio

```bash
# Crear directorio para la aplicación
mkdir -p /opt/cynthia
cd /opt/cynthia

# Clonar tu repositorio (reemplaza con tu URL)
git clone https://github.com/tu-usuario/CynthIA.git .

# O si ya tienes el código, puedes usar rsync o scp
```

### 3.2 Configurar Variables de Entorno

```bash
# Copiar el archivo de ejemplo
cp env.example .env

# Editar el archivo .env
nano .env
```

**Configuración mínima para producción:**

```env
# Base de datos (si usas contenedor)
DB_USER=periti_user
DB_PASSWORD=GENERA_UNA_PASSWORD_SEGURA_AQUI
DB_NAME=periti_ia

# JWT - GENERA UN SECRET SEGURO
JWT_SECRET=GENERA_UNA_CLAVE_SECRETA_MUY_LARGA_Y_SEGURA_AQUI_MINIMO_32_CARACTERES
JWT_EXPIRES_IN=7d

# Google Gemini (tu API key real)
GEMINI_API_KEY=tu-gemini-api-key

# URLs - IMPORTANTE: Cambia por tu dominio o IP
FRONTEND_URL=https://tu-dominio.com
NEXT_PUBLIC_API_URL=https://tu-dominio.com/api
```

**Generar passwords seguras:**

```bash
# Generar password para base de datos
openssl rand -base64 32

# Generar JWT secret
openssl rand -base64 64
```

### 3.3 Configurar Permisos

```bash
# Crear directorios necesarios
mkdir -p CynthIA-backend/uploads
mkdir -p CynthIA-backend/temp

# Dar permisos adecuados
chmod -R 755 CynthIA-backend/uploads
chmod -R 755 CynthIA-backend/temp
```

---

## 4. Deployment

### 4.1 Construir y Levantar los Contenedores

```bash
cd /opt/cynthia

# Construir las imágenes
docker-compose build

# Levantar los servicios
docker-compose up -d

# Ver los logs
docker-compose logs -f
```

### 4.2 Verificar que Todo Funciona

```bash
# Ver estado de los contenedores
docker-compose ps

# Verificar salud de los servicios
docker-compose ps

# Probar backend
curl http://localhost:3000/health

# Probar frontend
curl http://localhost:3001
```

### 4.3 Ejecutar Migraciones de Base de Datos

Las migraciones se ejecutan automáticamente al iniciar el backend, pero puedes ejecutarlas manualmente:

```bash
# Entrar al contenedor del backend
docker-compose exec backend sh

# Dentro del contenedor
npx prisma migrate deploy
npx prisma generate

# Salir
exit
```

---

## 5. Configuración de Dominio y SSL

### 5.1 Configurar DNS

1. En tu proveedor de dominio, crea registros A:
   - `@` → IP de tu Droplet
   - `www` → IP de tu Droplet
   - (Opcional) `api` → IP de tu Droplet (si quieres subdominio separado)

### 5.2 Instalar Nginx como Reverse Proxy

```bash
# Instalar Nginx
sudo apt install nginx -y

# Iniciar y habilitar Nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 5.3 Configurar Nginx

Crea el archivo de configuración:

```bash
sudo nano /etc/nginx/sites-available/cynthia
```

**Configuración básica (mismo dominio para frontend y backend):**

```nginx
server {
    listen 80;
    server_name tu-dominio.com www.tu-dominio.com;

    # Frontend
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3000;
    }
}
```

**O si prefieres subdominios separados:**

```nginx
# Frontend
server {
    listen 80;
    server_name tu-dominio.com www.tu-dominio.com;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Backend API
server {
    listen 80;
    server_name api.tu-dominio.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Habilitar el sitio:

```bash
sudo ln -s /etc/nginx/sites-available/cynthia /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5.4 Instalar Certbot para SSL (Let's Encrypt)

```bash
# Instalar Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtener certificado SSL
sudo certbot --nginx -d tu-dominio.com -d www.tu-dominio.com

# Renovación automática (ya está configurada por defecto)
sudo certbot renew --dry-run
```

### 5.5 Actualizar Variables de Entorno

Después de configurar el dominio, actualiza el archivo `.env`:

```env
FRONTEND_URL=https://tu-dominio.com
NEXT_PUBLIC_API_URL=https://tu-dominio.com/api
```

Y reinicia los contenedores:

```bash
docker-compose restart frontend backend
```

---

## 6. Mantenimiento

### 6.1 Script de Deployment Automático

Crea un script para facilitar el deployment:

```bash
nano /opt/cynthia/deploy.sh
```

Contenido del script (ver `deploy.sh` en el repositorio):

```bash
#!/bin/bash
set -e

echo "🚀 Iniciando deployment de CynthIA..."

cd /opt/cynthia

# Pull latest changes
echo "📥 Obteniendo últimos cambios..."
git pull origin main

# Rebuild containers
echo "🔨 Construyendo contenedores..."
docker-compose build

# Restart services
echo "🔄 Reiniciando servicios..."
docker-compose up -d

# Run migrations
echo "🗄️ Ejecutando migraciones..."
docker-compose exec -T backend npx prisma migrate deploy

# Clean up old images
echo "🧹 Limpiando imágenes antiguas..."
docker image prune -f

echo "✅ Deployment completado!"
docker-compose ps
```

Hacer ejecutable:

```bash
chmod +x /opt/cynthia/deploy.sh
```

### 6.2 Actualizar la Aplicación

```bash
cd /opt/cynthia
./deploy.sh
```

### 6.3 Ver Logs

```bash
# Todos los servicios
docker-compose logs -f

# Solo backend
docker-compose logs -f backend

# Solo frontend
docker-compose logs -f frontend

# Solo base de datos
docker-compose logs -f postgres
```

### 6.4 Hacer Backup de la Base de Datos

```bash
# Backup manual
docker-compose exec postgres pg_dump -U periti_user periti_ia > backup_$(date +%Y%m%d_%H%M%S).sql

# O crear un script de backup automático
nano /opt/cynthia/backup.sh
```

Contenido de `backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/opt/cynthia/backups"
mkdir -p $BACKUP_DIR
docker-compose exec -T postgres pg_dump -U periti_user periti_ia | gzip > $BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql.gz
# Mantener solo los últimos 7 backups
ls -t $BACKUP_DIR/*.sql.gz | tail -n +8 | xargs -r rm
```

### 6.5 Restaurar Backup

```bash
gunzip < backup_20240101_120000.sql.gz | docker-compose exec -T postgres psql -U periti_user -d periti_ia
```

### 6.6 Reiniciar Servicios

```bash
# Reiniciar todos
docker-compose restart

# Reiniciar uno específico
docker-compose restart backend
```

### 6.7 Detener Servicios

```bash
# Detener sin eliminar
docker-compose stop

# Detener y eliminar contenedores
docker-compose down

# Detener, eliminar contenedores y volúmenes (¡CUIDADO! Elimina la BD)
docker-compose down -v
```

---

## 7. Troubleshooting

### Problema: Los contenedores no inician

```bash
# Ver logs detallados
docker-compose logs

# Verificar variables de entorno
docker-compose config

# Verificar conectividad entre servicios
docker-compose exec backend ping postgres
```

### Problema: Error de conexión a base de datos

```bash
# Verificar que PostgreSQL está corriendo
docker-compose ps postgres

# Verificar logs de PostgreSQL
docker-compose logs postgres

# Probar conexión manualmente
docker-compose exec backend npx prisma db pull
```

### Problema: Frontend no se conecta al backend

1. Verificar que `NEXT_PUBLIC_API_URL` está correctamente configurado
2. Verificar que el backend está accesible desde el frontend
3. Verificar CORS en el backend (variable `FRONTEND_URL`)

---

## 8. Recomendaciones de Seguridad

1. **Firewall**: Configura un firewall (UFW) en el servidor
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

2. **Actualizaciones**: Mantén el sistema actualizado
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

3. **Backups**: Configura backups automáticos de la base de datos

4. **Monitoreo**: Considera usar herramientas de monitoreo como Uptime Robot

5. **Variables de Entorno**: Nunca commitees el archivo `.env` al repositorio

---

## 9. Costos Estimados

- **Droplet básico**: ~$12/mes (2GB RAM)
- **Droplet recomendado**: ~$24/mes (4GB RAM)
- **Managed Database** (opcional): ~$15/mes
- **Dominio**: ~$10-15/año
- **Total mínimo**: ~$12-24/mes
- **Total con BD managed**: ~$27-39/mes

---

## ✅ Checklist de Deployment

- [ ] Droplet creado y configurado
- [ ] Docker y Docker Compose instalados
- [ ] Repositorio clonado en el servidor
- [ ] Archivo `.env` configurado con valores reales
- [ ] Contenedores construidos y corriendo
- [ ] Migraciones de base de datos ejecutadas
- [ ] Dominio configurado (DNS)
- [ ] Nginx configurado como reverse proxy
- [ ] SSL configurado (Let's Encrypt)
- [ ] Firewall configurado
- [ ] Backups configurados
- [ ] Script de deployment creado
- [ ] Aplicación accesible desde internet

---

¡Feliz deployment! 🎉
