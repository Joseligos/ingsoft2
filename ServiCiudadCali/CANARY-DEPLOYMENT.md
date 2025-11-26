# Flujo de Despliegue Canary - ServiCiudadCali

## 🎯 Concepto Canary Deployment

El despliegue Canary permite probar una **nueva versión** del servicio en producción con un **subconjunto limitado de tráfico**, mientras la **versión anterior (stable)** sigue atendiendo la mayoría del tráfico.

## 📊 Arquitectura de Imágenes

```
┌─────────────────────────────────────────────────────┐
│  GitHub Actions Pipeline                            │
├─────────────────────────────────────────────────────┤
│                                                      │
│  1. Build nueva imagen → serviciudadcali:latest     │
│                                                      │
│  2. Canary Deploy:                                  │
│     ├─ Etiquetar: latest → canary                  │
│     └─ Deploy en puerto 8081 (NUEVA versión)       │
│                                                      │
│  3. Stable sigue corriendo:                         │
│     └─ Puerto 8080 (VERSIÓN ANTERIOR)              │
│                                                      │
│  4. Promoción (si tests OK):                        │
│     ├─ Backup: stable → rollback                   │
│     ├─ Etiquetar: latest → stable                  │
│     ├─ Detener versión anterior                    │
│     └─ Deploy nueva versión en 8080                │
│                                                      │
└─────────────────────────────────────────────────────┘
```

## 🔄 Flujo Paso a Paso

### Estado Inicial
```bash
Puerto 8080: serviciudadcali:stable (v1.0.100) ← Versión actual en producción
Puerto 8081: (vacío)
```

### Después de Push a Main
1. **Pipeline construye nueva imagen**
   ```bash
   serviciudadcali:latest (v1.0.101) ← NUEVA versión
   ```

2. **Canary Deploy (Job 3)**
   ```bash
   Puerto 8080: serviciudadcali:stable (v1.0.100) ← Sigue en producción
   Puerto 8081: serviciudadcali:canary (v1.0.101) ← NUEVA versión en prueba
   ```
   - Smoke tests se ejecutan contra puerto 8081
   - Tráfico de prueba dirigido a 8081
   - Versión anterior sigue estable en 8080

3. **Promoción (Job 4 - si Canary OK)**
   ```bash
   # Backup de versión actual
   serviciudadcali:rollback (v1.0.100) ← Guardada por si hay problemas
   
   # Promoción
   Puerto 8080: serviciudadcali:stable (v1.0.101) ← NUEVA versión promovida
   Puerto 8081: (apagado) ← Canary limpiado
   ```

4. **Rollback (Job 5 - si falla promoción)**
   ```bash
   Puerto 8080: serviciudadcali:rollback (v1.0.100) ← Versión anterior restaurada
   ```

## 📁 Archivos Docker Compose

### `docker-compose.build.yml`
**Propósito:** Solo para construir la imagen en el pipeline
```yaml
services:
  app-build:
    build:
      context: .
      dockerfile: Dockerfile
    image: serviciudadcali:latest
```

### `docker-compose.yml`
**Propósito:** Despliegue de servicios stable y canary
```yaml
services:
  app-stable:
    image: serviciudadcali:stable  # ← NO build, usa imagen pre-existente
    ports:
      - "8080:8080"
  
  app-canary:
    image: serviciudadcali:canary  # ← NO build, usa imagen pre-existente
    ports:
      - "8081:8080"
    profiles:
      - canary
```

**Clave:** Los servicios `app-stable` y `app-canary` **NO tienen `build`**, solo usan imágenes pre-construidas con tags diferentes.

## 🎯 Diferencia Clave con Implementación Anterior

### ❌ Implementación Incorrecta (Antes)
```yaml
# docker-compose.yml
app-stable:
  build: .              # ← Construye imagen
  image: serviciudadcali:latest

app-canary:
  build: .              # ← Construye LA MISMA imagen
  image: serviciudadcali:latest
```
**Problema:** Ambos servicios usan la misma imagen → No hay versión vieja vs nueva

### ✅ Implementación Correcta (Ahora)
```yaml
# docker-compose.yml
app-stable:
  image: serviciudadcali:stable    # ← Versión anterior (ya desplegada)

app-canary:
  image: serviciudadcali:canary    # ← Versión nueva (en prueba)
```
**Ventaja:** Cada servicio usa un tag diferente → Versiones realmente distintas

## 🚀 Comandos Clave del Pipeline

```bash
# 1. Build (Job 2)
docker compose -f docker-compose.build.yml build
docker tag serviciudadcali:latest serviciudadcali:canary

# 2. Canary Deploy (Job 3)
docker compose --profile canary up -d app-canary  # Puerto 8081

# 3. Promoción (Job 4)
docker tag serviciudadcali-stable:current serviciudadcali:rollback  # Backup
docker tag serviciudadcali:canary serviciudadcali:stable            # Promoción
docker compose up -d app-stable                                      # Puerto 8080

# 4. Rollback (Job 5)
docker tag serviciudadcali:rollback serviciudadcali:stable
docker compose up -d app-stable
```

## 📊 Verificación Local

### Ver imágenes disponibles
```bash
docker images | grep serviciudadcali
```

Deberías ver:
```
serviciudadcali   stable     abc123   v1.0.100 (producción)
serviciudadcali   canary     def456   v1.0.101 (prueba)
serviciudadcali   latest     def456   v1.0.101 (última build)
serviciudadcali   rollback   abc123   v1.0.100 (backup)
```

### Ver servicios corriendo
```bash
docker compose ps
```

### Probar ambas versiones
```bash
# Versión STABLE (anterior)
curl http://localhost:8080/actuator/health

# Versión CANARY (nueva)
curl http://localhost:8081/actuator/health
```

## 🎓 Cumplimiento con Requisitos del Enunciado

✅ **"Existencia de al menos dos versiones del servicio"**
- `app-stable` (puerto 8080): Versión anterior en producción
- `app-canary` (puerto 8081): Versión nueva en prueba

✅ **"Capacidad de dirigir el tráfico hacia la nueva versión de forma controlada"**
- Tráfico normal → puerto 8080 (stable)
- Smoke tests y pruebas → puerto 8081 (canary)
- Control mediante puertos diferentes

✅ **"Posibilidad de revertir rápidamente a la versión estable"**
- Imagen backup con tag `rollback`
- Job 5 automático de rollback
- Comando: `docker compose up -d app-stable` con imagen rollback

## 🔍 Notas Importantes

1. **Primera ejecución:** Si no hay versión `stable` previa, el pipeline la detecta y continúa sin hacer backup

2. **Tags de imágenes:**
   - `latest`: Última imagen construida (siempre la más reciente)
   - `canary`: Versión en prueba (puerto 8081)
   - `stable`: Versión en producción (puerto 8080)
   - `rollback`: Backup de versión anterior
   - `v1.0.X`: Tag con número de versión específico

3. **Profiles de Docker Compose:**
   - Por defecto: solo levanta `mysql` y `app-stable`
   - Con `--profile canary`: levanta también `app-canary`

4. **Healthchecks:** Ambas versiones tienen healthchecks automáticos para detectar fallos

## 📚 Referencias

- [Canary Deployment Pattern](https://martinfowler.com/bliki/CanaryRelease.html)
- [Docker Compose Profiles](https://docs.docker.com/compose/profiles/)
- [GitHub Actions Artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
