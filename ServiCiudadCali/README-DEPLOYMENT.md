# 🚀 Inicio Rápido - Despliegue con Docker Compose

## Comandos Esenciales

### 🏗️ Primer Despliegue

```bash
# 1. Iniciar base de datos y producción
docker-compose up -d

# 2. Verificar que todo esté corriendo
docker-compose ps

# 3. Ver logs
docker-compose logs -f app-stable
```

### 🐤 Despliegue Canary (Nueva Versión)

```bash
# 1. Desplegar canary
./scripts/deploy-canary.sh

# 2. Ejecutar smoke tests
./scripts/smoke-test-canary.sh

# 3. Ver estado
./scripts/status.sh

# 4. Promover a producción
./scripts/promote-canary.sh
```

### 📊 Monitoreo

```bash
# Estado completo del sistema
./scripts/status.sh

# Logs en tiempo real
docker-compose logs -f app-stable              # Production
docker-compose --profile canary logs -f app-canary  # Canary

# Health checks
curl http://localhost:8080/actuator/health     # Production
curl http://localhost:8081/actuator/health     # Canary
```

### 🔄 Rollback

```bash
# Rollback a versión anterior
./scripts/rollback.sh
```

### 🧹 Limpieza

```bash
# Detener todo
docker-compose --profile canary down

# Limpiar imágenes Docker
docker system prune -a
```

---

## 📖 Documentación Completa

Ver [DEPLOYMENT.md](DEPLOYMENT.md) para la guía completa.

---

## 🎯 Flujo de Trabajo

```
Desarrollo → Build → Deploy Canary → Tests → Promote → Production
                          ↓                        ↓
                      Puerto 8081             Puerto 8080
```

---

## 🆘 Ayuda Rápida

**Canary no inicia:**
```bash
docker-compose --profile canary logs app-canary
```

**Puerto en uso:**
```bash
docker-compose stop
```

**Rebuild todo:**
```bash
docker-compose build
./scripts/deploy-canary.sh
```

---

**Versión**: 2.0.0 (Docker Compose)
