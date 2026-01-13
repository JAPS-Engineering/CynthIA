# 🔧 Solución para Error 504 Gateway Time-out

## Problema

Al generar un informe, aparece el error:
```
POST https://www.cynthia.lat/api/reports/cases/.../generate-report net::ERR_FAILED 504 (Gateway Time-out)
```

**Pero el informe SÍ se crea** - al recargar la página aparece correctamente.

## Solución Implementada

### 1. ✅ Frontend con Polling Automático

El frontend ahora detecta automáticamente los timeouts y hace polling para verificar si el informe se creó. **Ya está implementado y funcionando.**

### 2. ⚙️ Configurar Nginx (Recomendado)

Para evitar el timeout completamente, configura Nginx con timeouts más largos:

**Edita el archivo de configuración de Nginx:**

```bash
sudo nano /etc/nginx/sites-available/cynthia
```

**Agrega estas configuraciones en el bloque `location /api`:**

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name cynthia.lat www.cynthia.lat;

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

    # Backend API - CONFIGURACIÓN PARA TIMEOUTS LARGOS
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # ⚠️ IMPORTANTE: Aumentar timeouts para generación de reportes
        proxy_connect_timeout 600s;      # 10 minutos para conectar
        proxy_send_timeout 600s;         # 10 minutos para enviar
        proxy_read_timeout 600s;         # 10 minutos para leer respuesta
        send_timeout 600s;                # 10 minutos para enviar al cliente
        
        # Aumentar tamaño máximo de body para archivos grandes
        client_max_body_size 100M;
        client_body_buffer_size 128k;
        
        # Buffering para evitar timeouts
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3000;
    }
}
```

**Si usas HTTPS, también configura el bloque para el puerto 443:**

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name cynthia.lat www.cynthia.lat;

    # Certificados SSL (ajusta las rutas según tu configuración)
    ssl_certificate /etc/letsencrypt/live/cynthia.lat/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/cynthia.lat/privkey.pem;

    # Configuración SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

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

    # Backend API - CONFIGURACIÓN PARA TIMEOUTS LARGOS
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # ⚠️ IMPORTANTE: Aumentar timeouts para generación de reportes
        proxy_connect_timeout 600s;      # 10 minutos para conectar
        proxy_send_timeout 600s;         # 10 minutos para enviar
        proxy_read_timeout 600s;         # 10 minutos para leer respuesta
        send_timeout 600s;                # 10 minutos para enviar al cliente
        
        # Aumentar tamaño máximo de body para archivos grandes
        client_max_body_size 100M;
        client_body_buffer_size 128k;
        
        # Buffering para evitar timeouts
        proxy_buffering off;
        proxy_request_buffering off;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:3000;
    }
}

# Redireccionar HTTP a HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name cynthia.lat www.cynthia.lat;
    return 301 https://$server_name$request_uri;
}
```

### 3. Verificar y Recargar Nginx

Después de editar la configuración:

```bash
# Verificar que la configuración sea válida
sudo nginx -t

# Si es válida, recargar Nginx
sudo systemctl reload nginx

# O reiniciar si es necesario
sudo systemctl restart nginx
```

## Cómo Funciona Ahora

### Con la Solución Implementada:

1. **Usuario hace clic en "Generar Informe"**
2. **Si hay timeout (504):**
   - El frontend detecta automáticamente el error
   - Muestra un mensaje: "La generación está tomando más tiempo del esperado. Verificando estado..."
   - Inicia polling automático cada 10 segundos
   - Verifica si se creó un nuevo informe
   - Cuando encuentra el informe, lo muestra y redirige automáticamente
   - Si después de 5 minutos no encuentra nada, muestra un mensaje y recarga los datos

3. **Si NO hay timeout:**
   - Funciona normalmente como antes

### Ventajas:

- ✅ **No se pierde el informe** - aunque haya timeout, el frontend lo encuentra automáticamente
- ✅ **Mejor experiencia de usuario** - no necesita recargar manualmente
- ✅ **Funciona incluso si Nginx tiene timeouts cortos** - el polling lo resuelve

## Explicación de los Timeouts en Nginx

- `proxy_connect_timeout 600s`: Tiempo máximo para conectar con el backend (10 minutos)
- `proxy_send_timeout 600s`: Tiempo máximo para enviar datos al backend (10 minutos)
- `proxy_read_timeout 600s`: Tiempo máximo para leer respuesta del backend (10 minutos) ⚠️ **Este es el más importante**
- `send_timeout 600s`: Tiempo máximo para enviar respuesta al cliente (10 minutos)
- `proxy_buffering off`: Desactiva el buffering para evitar problemas con respuestas largas

## Troubleshooting

Si aún tienes problemas:

1. **Verifica los logs de Nginx:**
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

2. **Verifica los logs del backend:**
   ```bash
   docker-compose logs -f backend
   ```

3. **Verifica que el backend esté corriendo:**
   ```bash
   curl http://localhost:3000/health
   ```

4. **Verifica que Nginx esté corriendo:**
   ```bash
   sudo systemctl status nginx
   ```

5. **Verifica la configuración de Nginx:**
   ```bash
   sudo nginx -t
   ```

## Notas Importantes

- El frontend ahora maneja automáticamente los timeouts, así que **funcionará incluso sin cambiar Nginx**
- Cambiar Nginx es **recomendado** para evitar el timeout completamente
- El proceso de generación puede tardar varios minutos dependiendo del tamaño de los archivos y la carga de Gemini API
- El polling verifica cada 10 segundos durante máximo 5 minutos (30 intentos)
