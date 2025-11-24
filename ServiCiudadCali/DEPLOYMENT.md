# 📋 Guía de Despliegue CI/CD con Docker Compose

## 📚 Índice
1. [Arquitectura](#arquitectura)
2. [Docker Compose](#docker-compose)
3. [Estrategia Canary](#estrategia-canary)
4. [Comandos de Despliegue](#comandos-de-despliegue)
5. [Scripts Automatizados](#scripts-automatizados)
6. [Monitoreo](#monitoreo)
7. [Troubleshooting](#troubleshooting)

---

## 🏗️ Arquitectura

### Estrategia Canary Deployment

```
┌──────────────────────────────────────────────────────┐
│                   Docker Compose                      │
│                                                       │
│  ┌─────────────────────────────────────────────────┐│
│  │  MySQL (Base de Datos)                          ││
│  └─────────────────────────────────────────────────┘│
│                           │                          │
│           ┌───────────────┴───────────────┐          │
│           ▼                               ▼          │
│  ┌──────────────────┐          ┌──────────────────┐ │
│  │  app-stable      │          │  app-canary      │ │
│  │  (Production)    │          │  (Testing)       │ │
│  │  Port: 8080      │          │  Port: 8081      │ │
│  │  Profile: prod   │          │  Profile: canary │ │
│  └──────────────────┘          └──────────────────┘ │
│                                                       │
└──────────────────────────────────────────────────────┘
```

### Servicios Docker Compose

| Servicio | Puerto | Perfil | Estado | Propósito |
|----------|--------|--------|--------|-----------|
| **mysql** | 3306 | default | always | Base de datos compartida |
| **app-stable** | 8080 | default | production | Versión estable en producción |
| **app-canary** | 8081 | canary | testing | Nueva versión en testing |

---

## 🐳 Docker Compose

### Archivo `docker-compose.yml`

El archivo está configurado con:

- **3 servicios**: MySQL, app-stable (producción), app-canary (testing)
- **Perfiles**: app-canary usa el perfil `canary` para despliegue condicional
- **Health checks**: Automáticos para MySQL y aplicaciones
- **Redes**: Red compartida `serviciudadcali-network`
- **Volúmenes**: Persistencia de datos MySQL
- **Variables de entorno**: Configurables por servicio

### Comandos Básicos

```bash
# Iniciar solo producción (stable + mysql)
docker-compose up -d

# Iniciar todo incluyendo canary
docker-compose --profile canary up -d

# Ver estado de servicios
docker-compose ps

# Ver logs
docker-compose logs -f app-stable
docker-compose --profile canary logs -f app-canary

# Detener servicios
docker-compose stop

# Detener y eliminar contenedores
docker-compose down

# Rebuild de imágenes
docker-compose build

# Escalar servicios (si es necesario)
docker-compose up -d --scale app-stable=2
```

---

## 🐤 Estrategia Canary

### Flujo de Despliegue Canary

```
┌─────────────────┐
│  1. Deploy      │  Deploy nueva versión en puerto 8081
│     Canary      │  Profile: canary
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  2. Health      │  Verificar health checks automáticos
│     Check       │  Max 10 intentos con reintentos
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  3. Smoke       │  Ejecutar suite de tests
│     Tests       │  Validar endpoints críticos
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  4. Manual      │  Revisión manual de logs y métricas
│     Review      │  Confirmación para promoción
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  5. Promote     │  Promover a stable (puerto 8080)
│     to Stable   │  Backup automático de versión anterior
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  6. Cleanup     │  Remover contenedor canary
│     Canary      │  Mantener imagen para rollback
└─────────────────┘
```

### Ventajas

1. ✅ **Zero Downtime**: Producción permanece activa durante testing
2. ✅ **Rollback Rápido**: Versión anterior siempre disponible
3. ✅ **Testing Real**: Canary usa misma DB y configuración
4. ✅ **Validación Gradual**: Smoke tests antes de afectar usuarios
5. ✅ **Gestión Declarativa**: Docker Compose maneja orquestación

---

## 🚀 Comandos de Despliegue

### Despliegue Completo Paso a Paso

#### 1. Desplegar Canary

```bash
# Opción A: Usar script automatizado (recomendado)
./scripts/deploy-canary.sh [version]

# Opción B: Manual con Docker Compose
mvn clean package -DskipTests
VERSION=1.0.0 docker-compose build app-canary
VERSION=1.0.0 docker-compose --profile canary up -d app-canary
```

**Qué hace:**
- Compila el proyecto Maven
- Construye imagen Docker
- Despliega contenedor en puerto 8081
- Ejecuta health check automático

#### 2. Verificar Estado

```bash
# Ver estado completo del sistema
./scripts/status.sh

# Ver logs en tiempo real
docker-compose --profile canary logs -f app-canary

# Health check manual
curl http://localhost:8081/actuator/health
```

#### 3. Ejecutar Smoke Tests

```bash
./scripts/smoke-test-canary.sh
```

**Tests ejecutados:**
- ✅ Health check endpoint
- ✅ Info endpoint
- ✅ Endpoints de API principales
- ✅ Validación de códigos HTTP
- ✅ Validación de respuestas JSON

#### 4. Promover a Producción

```bash
# Promoción con confirmación
./scripts/promote-canary.sh
```

**Qué hace:**
- Crea backup de stable actual
- Detiene stable anterior
- Promociona imagen canary → latest
- Despliega nueva versión en puerto 8080
- Health check con rollback automático si falla
- Limpia contenedor canary

#### 5. Rollback (si es necesario)

```bash
# Rollback con confirmación
./scripts/rollback.sh
```

**Qué hace:**
- Detiene versión actual
- Restaura imagen de backup
- Despliega versión anterior
- Valida health check

---

## 📜 Scripts Automatizados

### 1. `deploy-canary.sh`

**Uso:**
```bash
./scripts/deploy-canary.sh [version]

# Ejemplos:
./scripts/deploy-canary.sh 1.2.0
./scripts/deploy-canary.sh  # usa version de git
```

**Pasos:**
1. 🏗️ Compila proyecto Maven
2. 🐳 Build imagen con Docker Compose
3. 🛑 Detiene canary anterior
4. 🚀 Despliega nuevo canary
5. 🔍 Health check (30s + 10 reintentos)

**Salida exitosa:**
```
🎉 ¡Despliegue Canary completado exitosamente!

📋 Información del despliegue:
  🔗 URL: http://localhost:8081
  📦 Versión: 1.2.0
  🐳 Servicio: app-canary

📋 Próximos pasos:
  1. Monitorear logs: docker-compose --profile canary logs -f app-canary
  2. Ejecutar smoke tests: ./scripts/smoke-test-canary.sh
  3. Verificar estado: ./scripts/status.sh
  4. Promover a producción: ./scripts/promote-canary.sh
```

### 2. `smoke-test-canary.sh`

**Uso:**
```bash
./scripts/smoke-test-canary.sh
```

**Tests:**
- Health Check
- Info endpoint
- Deuda consolidada (404 esperado)
- Root endpoint
- Listar clientes
- Facturas acueducto (404 esperado)
- Facturas energía (404 esperado)

**Salida exitosa:**
```
========================================
  Resumen de Smoke Tests
========================================

  Total de tests: 7
  ✅ Exitosos: 7
  ❌ Fallidos: 0
  📊 Tasa de éxito: 100%

🎉 ¡Todos los smoke tests pasaron!
✅ Canary está listo para promoción
```

### 3. `promote-canary.sh`

**Uso:**
```bash
./scripts/promote-canary.sh
```

**Confirmación requerida:**
```
⚠️  ¿Está seguro de promover Canary a Producción?
   Esto reemplazará la versión actual en producción.
   [y/N]:
```

**Pasos:**
1. 📦 Backup de stable actual
2. 🛑 Detiene stable
3. 🐳 Promociona imagen canary
4. 🚀 Despliega en puerto 8080
5. 🔍 Health check con rollback automático

### 4. `rollback.sh`

**Uso:**
```bash
./scripts/rollback.sh
```

**Requisito:** Debe existir imagen de backup (creada en promoción anterior)

### 5. `status.sh`

**Uso:**
```bash
./scripts/status.sh
```

**Información mostrada:**
```
📦 PRODUCCIÓN (Stable)
───────────────────────────────────────
Estado:    🟢 RUNNING
Puerto:    8080
Versión:   1.2.0
Health:    ✅ UP
Uptime:    2h 30m 15s
URL:       http://localhost:8080

🐤 CANARY (Testing)
───────────────────────────────────────
Estado:    🟢 RUNNING
Puerto:    8081
Versión:   1.2.1
Health:    ✅ UP
Uptime:    15m 30s
URL:       http://localhost:8081

🐳 SERVICIOS DOCKER COMPOSE
───────────────────────────────────────
NAME                      IMAGE                    STATUS
serviciudadcali-mysql     mysql:8.0                Up
serviciudadcali-stable    serviciudadcali:latest   Up
serviciudadcali-canary    serviciudadcali:canary   Up

💡 ACCIONES DISPONIBLES
───────────────────────────────────────
  📊 Smoke tests:   ./scripts/smoke-test-canary.sh
  ⬆️  Promoción:     ./scripts/promote-canary.sh
  📝 Logs:          docker-compose --profile canary logs -f app-canary
```

---

## 📊 Monitoreo

### Health Checks

```bash
# Production
curl http://localhost:8080/actuator/health

# Canary
curl http://localhost:8081/actuator/health

# Respuesta esperada
{
  "status": "UP"
}
```

### Logs en Tiempo Real

```bash
# Production
docker-compose logs -f app-stable

# Canary
docker-compose --profile canary logs -f app-canary

# Todos los servicios
docker-compose logs -f

# Últimas 100 líneas
docker-compose logs --tail=100 app-stable
```

### Métricas de Recursos

```bash
# Ver CPU y memoria de todos los contenedores
docker stats

# Ver solo servicios de la app
docker stats serviciudadcali-stable serviciudadcali-canary

# Una sola medición
docker stats --no-stream
```

### Endpoints de Actuator

| Endpoint | Descripción |
|----------|-------------|
| `/actuator/health` | Estado de salud |
| `/actuator/info` | Información de la app |
| `/actuator/metrics` | Métricas disponibles |
| `/actuator/metrics/jvm.memory.used` | Uso de memoria JVM |
| `/actuator/metrics/http.server.requests` | Estadísticas de requests |

```bash
# Ver métricas de memoria
curl http://localhost:8080/actuator/metrics/jvm.memory.used

# Ver estadísticas de requests
curl http://localhost:8080/actuator/metrics/http.server.requests
```

---

## 🔧 Troubleshooting

### Problema: Canary no inicia

**Síntomas:**
```
❌ ERROR: Canary no responde al health check
```

**Solución:**
```bash
# 1. Ver logs
docker-compose --profile canary logs app-canary

# 2. Verificar estado del contenedor
docker-compose --profile canary ps app-canary

# 3. Verificar puerto disponible
netstat -tuln | grep 8081

# 4. Rebuild desde cero
docker-compose --profile canary down app-canary
docker-compose build app-canary
./scripts/deploy-canary.sh
```

### Problema: Errores de compilación Maven

**Síntomas:**
```
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin
```

**Solución:**
```bash
# 1. Limpiar todo
mvn clean

# 2. Verificar versión de Java
java -version  # Debe ser Java 21

# 3. Compilar con verbose
mvn clean package -X

# 4. Saltar tests si es necesario
mvn clean package -DskipTests
```

### Problema: Puerto ya en uso

**Síntomas:**
```
Error: bind: address already in use
```

**Solución:**
```bash
# 1. Identificar proceso
sudo lsof -i :8080
sudo lsof -i :8081

# 2. Detener servicios Docker Compose
docker-compose stop
docker-compose --profile canary stop

# 3. O matar proceso específico
kill -9 <PID>
```

### Problema: Base de datos no conecta

**Síntomas:**
```
com.mysql.cj.jdbc.exceptions.CommunicationsException: Communications link failure
```

**Solución:**
```bash
# 1. Verificar MySQL está running
docker-compose ps mysql

# 2. Ver logs de MySQL
docker-compose logs mysql

# 3. Verificar health de MySQL
docker-compose exec mysql mysqladmin ping -h 127.0.0.1 -uroot -proot

# 4. Restart MySQL
docker-compose restart mysql

# 5. Wait for healthy
docker-compose up -d mysql
sleep 10
```

### Problema: Smoke tests fallan

**Síntomas:**
```
❌ Algunos tests fallaron
```

**Solución:**
```bash
# 1. Verificar que Canary esté UP
curl -v http://localhost:8081/actuator/health

# 2. Ver logs de la aplicación
docker-compose --profile canary logs --tail=50 app-canary

# 3. Probar endpoints manualmente
curl -v http://localhost:8081/
curl -v http://localhost:8081/api/v1/deuda-consolidada/12345

# 4. Verificar configuración de profile
docker-compose --profile canary exec app-canary env | grep SPRING_PROFILES_ACTIVE
```

### Problema: Promoción falla con rollback automático

**Síntomas:**
```
❌ ERROR: Producción no responde al health check
🔄 Iniciando rollback automático...
```

**Causa:** La nueva versión no pasó health check en producción

**Solución:**
1. Revisar logs del intento fallido
2. Verificar que Canary funcionaba correctamente
3. Revisar diferencias de configuración entre profiles
4. Verificar recursos suficientes (memoria, CPU)
5. Probar nuevamente después de corregir

### Problema: No existe imagen de rollback

**Síntomas:**
```
❌ ERROR: No existe imagen de backup (rollback)
```

**Causa:** No se ha hecho ninguna promoción previa

**Solución:**
```bash
# Crear backup manual de versión actual
docker tag serviciudadcali:latest serviciudadcali:rollback

# O verificar imágenes disponibles
docker images | grep serviciudadcali

# Usar una versión específica si existe
docker tag serviciudadcali:v1.0.0 serviciudadcali:rollback
```

### Problema: Docker out of space

**Síntomas:**
```
Error: no space left on device
```

**Solución:**
```bash
# 1. Ver espacio usado
docker system df

# 2. Limpiar contenedores detenidos, redes, imágenes dangling
docker system prune

# 3. Limpiar TODO (cuidado - elimina todas las imágenes no usadas)
docker system prune -a

# 4. Limpiar solo volúmenes
docker volume prune

# 5. Limpiar imágenes específicas del proyecto
docker images | grep serviciudadcali | awk '{print $3}' | xargs docker rmi -f
```

---

## 📋 Checklist de Despliegue

### Pre-despliegue
- [ ] Código committed en git
- [ ] Tests locales pasan: `mvn test`
- [ ] Cobertura ≥80%: `mvn verify`
- [ ] MySQL running: `docker-compose ps mysql`

### Despliegue Canary
- [ ] Canary desplegado: `./scripts/deploy-canary.sh`
- [ ] Health check OK: `curl http://localhost:8081/actuator/health`
- [ ] Smoke tests pasan: `./scripts/smoke-test-canary.sh`
- [ ] Logs sin errores: `docker-compose --profile canary logs app-canary`
- [ ] Revisión manual completada

### Promoción a Producción
- [ ] Canary funcionando correctamente
- [ ] Aprobación del equipo
- [ ] Backup confirmado
- [ ] Promoción ejecutada: `./scripts/promote-canary.sh`
- [ ] Health check de stable OK
- [ ] Canary limpiado automáticamente

### Post-despliegue
- [ ] Monitoreo activo: `./scripts/status.sh`
- [ ] Logs de producción OK
- [ ] Métricas normales
- [ ] Verificación funcional en producción

---

## 🔗 Referencia Rápida

### Comandos Esenciales

```bash
# Deployment completo
./scripts/deploy-canary.sh
./scripts/smoke-test-canary.sh
./scripts/status.sh
./scripts/promote-canary.sh

# Docker Compose
docker-compose up -d                          # Iniciar producción
docker-compose --profile canary up -d         # Iniciar con canary
docker-compose ps                             # Ver estado
docker-compose logs -f app-stable             # Logs production
docker-compose --profile canary logs -f app-canary  # Logs canary
docker-compose stop                           # Detener todo
docker-compose down                           # Detener y eliminar

# Monitoreo
curl http://localhost:8080/actuator/health    # Health production
curl http://localhost:8081/actuator/health    # Health canary
docker stats                                  # Recursos
./scripts/status.sh                           # Estado completo

# Mantenimiento
mvn clean verify                              # Test + coverage
docker system prune                           # Limpiar Docker
./scripts/rollback.sh                         # Rollback
```

### Variables de Entorno

```bash
# En docker-compose.yml o export
VERSION=1.2.0                    # Versión de la aplicación
SPRING_PROFILES_ACTIVE=production  # Profile de Spring
JAVA_OPTS=-Xms512m -Xmx1024m    # Opciones JVM
DB_HOST=mysql                    # Host de base de datos
DB_PORT=3306                     # Puerto MySQL
```

### Puertos

- **8080**: Production (app-stable)
- **8081**: Canary (app-canary)
- **3306**: MySQL (mysql)

---

## 📞 Soporte

Para problemas o preguntas:
1. Revisar logs: `docker-compose logs`
2. Verificar estado: `./scripts/status.sh`
3. Consultar esta documentación
4. Revisar Issues de GitHub Actions

---

**Última actualización**: Noviembre 2024  
**Versión**: 2.0.0 (Docker Compose)
