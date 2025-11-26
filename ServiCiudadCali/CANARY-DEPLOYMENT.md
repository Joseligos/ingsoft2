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

### Primer Despliegue (Inicialización)
```bash
Push #1 → Pipeline construye v1.0.101
           ↓
        NO hay stable → Imagen se despliega como STABLE
           ↓
        Puerto 8080: serviciudadcali:stable (v1.0.101)
        Puerto 8081: (vacío - no hay Canary aún)
```

### Segundo Despliegue (Verdadero Canary)
```bash
Push #2 → Pipeline construye v1.0.102 (NUEVA)
           ↓
        YA hay stable (v1.0.101) corriendo
           ↓
        Puerto 8080: serviciudadcali:stable (v1.0.101) ← VIEJA (sigue corriendo)
        Puerto 8081: serviciudadcali:canary (v1.0.102) ← NUEVA (en prueba)
```

### Después de Promoción
```bash
Smoke tests OK → Promoción
           ↓
        Backup: stable v1.0.101 → rollback
        Promoción: canary v1.0.102 → stable
           ↓
        Puerto 8080: serviciudadcali:stable (v1.0.102) ← Nueva versión promovida
        Puerto 8081: (apagado - Canary limpiado)
```

### Tercer Despliegue (Siguiente Canary)
```bash
Push #3 → Pipeline construye v1.0.103 (NUEVA)
           ↓
        YA hay stable (v1.0.102) corriendo
           ↓
        Puerto 8080: serviciudadcali:stable (v1.0.102) ← VIEJA (del push anterior)
        Puerto 8081: serviciudadcali:canary (v1.0.103) ← NUEVA (en prueba)
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
# 1. Build (Job 2) - Construye NUEVA versión
docker compose -f docker-compose.build.yml build
docker tag serviciudadcali:latest serviciudadcali:canary  # ← Esta es la NUEVA

# 2. Canary Deploy (Job 3)
# PRIMER DESPLIEGUE (no hay stable):
docker tag serviciudadcali:canary serviciudadcali:stable
docker compose up -d app-stable  # Puerto 8080

# DESPLIEGUES POSTERIORES (ya hay stable):
# stable sigue corriendo (versión VIEJA)
docker compose --profile canary up -d app-canary  # Puerto 8081 (versión NUEVA)

# 3. Promoción (Job 4)
docker tag serviciudadcali-stable:current serviciudadcali:rollback  # Backup de VIEJA
docker tag serviciudadcali:canary serviciudadcali:stable            # Promoción: NUEVA → stable
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

1. **Primer despliegue:** La primera vez que se ejecuta el pipeline, NO hay versión stable previa. Por lo tanto, la imagen construida se despliega directamente como stable (puerto 8080). El Canary real ocurre en el SEGUNDO push.

2. **Segundo despliegue en adelante:** 
   - Stable (puerto 8080): Versión del push ANTERIOR (ya en producción)
   - Canary (puerto 8081): Versión del push ACTUAL (nueva, en prueba)

3. **Tags de imágenes:**
   - `canary`: Siempre es la versión NUEVA que acabas de construir
   - `stable`: Es la versión que está en producción (fue canary en el push anterior)
   - `rollback`: Backup de la versión stable antes de promoción
   - `v1.0.X`: Tag con número de versión específico

4. **Diferencia clave con implementación anterior:**
   - ❌ **ANTES:** Se construía UNA imagen y se usaba para ambos (stable y canary) → Ambas eran la misma versión nueva
   - ✅ **AHORA:** 
     - Stable = Contenedor que YA está corriendo (versión anterior)
     - Canary = Imagen nueva que acabas de construir
     - → Son versiones DIFERENTES (vieja vs nueva)

5. **Profiles de Docker Compose:**
   - Por defecto: solo levanta `mysql` y `app-stable`
   - Con `--profile canary`: levanta también `app-canary`

6. **Healthchecks:** Ambas versiones tienen healthchecks automáticos para detectar fallos

## 📚 Referencias

- [Canary Deployment Pattern](https://martinfowler.com/bliki/CanaryRelease.html)
- [Docker Compose Profiles](https://docs.docker.com/compose/profiles/)
- [GitHub Actions Artifacts](https://docs.github.com/en/actions/using-workflows/storing-workflow-data-as-artifacts)
