# Scripts de Despliegue Canary

Scripts para gestionar despliegues Canary de ServiCiudadCali usando Docker Compose y GitHub Container Registry (GHCR).

## 📋 Requisitos Previos

### 1. Docker y Docker Compose
```bash
docker --version
docker compose version
```

### 2. Login en GHCR (para persistencia de imágenes)
```bash
./scripts/ghcr-login.sh
```

O manualmente:
```bash
# Crear token en: https://github.com/settings/tokens/new
# Permisos necesarios: write:packages, read:packages
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin
```

## 🚀 Flujo de Despliegue

### Primer Despliegue

```bash
# Desplegar la primera versión como STABLE
./scripts/deploy-canary.sh v1.0.0

# Esto desplegará:
# - Puerto 8080: STABLE v1.0.0
# - La imagen se sube a GHCR como :stable
```

### Despliegues Posteriores (Canary)

```bash
# Desplegar nueva versión como CANARY
./scripts/deploy-canary.sh v1.1.0

# Esto desplegará:
# - Puerto 8080: STABLE v1.0.0 (descargada de GHCR - push anterior)
# - Puerto 8081: CANARY v1.1.0 (nueva versión - push actual)
```

**🔑 Punto Clave:** Ahora `STABLE` es del push anterior y `CANARY` es del push actual, gracias a GHCR.

### Ejecutar Smoke Tests

```bash
./scripts/smoke-test-canary.sh
```

### Verificar Estado

```bash
./scripts/status.sh
```

### Promover Canary a Producción

```bash
./scripts/promote-canary.sh

# Esto:
# 1. Hace backup de STABLE actual → :rollback en GHCR
# 2. Promueve CANARY → STABLE (local y GHCR)
# 3. Despliega nueva STABLE en puerto 8080
# 4. Limpia CANARY
```

### Rollback (si algo falla)

```bash
./scripts/rollback.sh

# Esto:
# 1. Descarga :rollback desde GHCR
# 2. Restaura como :stable
# 3. Despliega versión anterior
```

## 📊 Arquitectura del Flujo

### Sin GHCR (Problema Anterior)
```
Push #1: build v1 → stable=v1, canary=v1 ❌ (ambos iguales)
Push #2: build v2 → stable=v2, canary=v2 ❌ (ambos iguales)
```

### Con GHCR (Solución Actual)
```
Push #1: build v1 → stable=v1 ✅
                  → upload :stable a GHCR

Push #2: build v2 → download :stable (v1) desde GHCR
                  → stable=v1 (puerto 8080) ✅
                  → canary=v2 (puerto 8081) ✅
                  → upload :canary (v2) a GHCR

Promote: canary (v2) → stable
       → upload :stable (v2) a GHCR
       → backup v1 → :rollback en GHCR
```

## 🐳 Imágenes en GHCR

Las imágenes se almacenan en:
```
ghcr.io/joseligos/ingsoft2/serviciudadcali:stable   # Versión en producción
ghcr.io/joseligos/ingsoft2/serviciudadcali:canary   # Versión en prueba
ghcr.io/joseligos/ingsoft2/serviciudadcali:rollback # Backup para rollback
ghcr.io/joseligos/ingsoft2/serviciudadcali:1.0.X    # Versiones específicas
```

## 📝 Scripts Disponibles

| Script | Descripción |
|--------|-------------|
| `ghcr-login.sh` | Login en GitHub Container Registry |
| `deploy-canary.sh [version]` | Desplegar nueva versión como Canary |
| `smoke-test-canary.sh` | Ejecutar smoke tests en Canary |
| `status.sh` | Ver estado de todos los servicios y GHCR |
| `promote-canary.sh` | Promover Canary a Producción |
| `rollback.sh` | Revertir a versión anterior |

## 🔍 Verificación de Estado

### Ver servicios locales
```bash
docker compose ps
docker compose --profile canary ps
```

### Ver imágenes locales
```bash
docker images serviciudadcali
```

### Ver imágenes en GHCR
```bash
./scripts/status.sh
```

### Health checks
```bash
# STABLE (producción)
curl http://localhost:8080/actuator/health

# CANARY (testing)
curl http://localhost:8081/actuator/health
```

### Logs
```bash
# STABLE
docker compose logs -f app-stable

# CANARY
docker compose --profile canary logs -f app-canary
```

## ⚠️ Notas Importantes

1. **Login en GHCR es necesario** para que los scripts funcionen correctamente
   - Sin login: las imágenes solo estarán disponibles localmente
   - Con login: las imágenes persisten en GHCR entre despliegues

2. **STABLE siempre es del push anterior** (descargada de GHCR)
   - En el primer despliegue no hay push anterior, por eso STABLE = versión actual

3. **CANARY siempre es del push actual** (recién construida)

4. **Rollback requiere que exista :rollback en GHCR**
   - Se crea automáticamente al hacer promote

5. **Los scripts manejan gracefully** la ausencia de GHCR
   - Si no hay login, funcionan localmente pero sin persistencia

## 🔧 Troubleshooting

### Error: "no tiene permisos para subir a GHCR"
```bash
./scripts/ghcr-login.sh
```

### Error: "no hay imagen stable en GHCR"
Es normal en el primer despliegue. El script lo manejará automáticamente.

### Error: "canary no responde al health check"
```bash
# Ver logs
docker compose --profile canary logs app-canary

# Verificar que MySQL esté listo
docker compose logs mysql
```

### Limpiar todo y empezar de cero
```bash
docker compose --profile canary down
docker compose down
docker volume rm serviciudadcali_mysql_data
docker rmi serviciudadcali:stable serviciudadcali:canary serviciudadcali:rollback
```

## 🎯 Ejemplo Completo

```bash
# 1. Login a GHCR (una sola vez)
./scripts/ghcr-login.sh

# 2. Primer despliegue
./scripts/deploy-canary.sh v1.0.0
# → Puerto 8080: STABLE v1.0.0

# 3. Segundo despliegue (Canary real)
./scripts/deploy-canary.sh v1.1.0
# → Puerto 8080: STABLE v1.0.0 (del push anterior)
# → Puerto 8081: CANARY v1.1.0 (del push actual) ✅

# 4. Verificar estado
./scripts/status.sh

# 5. Ejecutar tests
./scripts/smoke-test-canary.sh

# 6. Promover a producción
./scripts/promote-canary.sh
# → Puerto 8080: STABLE v1.1.0

# 7. Si hay problemas, rollback
./scripts/rollback.sh
# → Puerto 8080: STABLE v1.0.0 (restaurada)
```

## 🔗 Referencias

- [GitHub Container Registry Docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Compose Profiles](https://docs.docker.com/compose/profiles/)
- [Canary Deployment Pattern](https://martinfowler.com/bliki/CanaryRelease.html)
