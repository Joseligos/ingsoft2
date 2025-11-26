# 🚀 Demo Rápida - Entregable Final

## Verificación en 5 Pasos (< 5 minutos)

---

### Paso 1: Verificar Cobertura de Código (30 segundos)

```bash
cd /home/joseligo/ING-SOFTWARE-2/ServiCiudadCali
mvn verify
```

**Resultado Esperado:**
```
[INFO] --- jacoco:0.8.12:check (check) @ ServiCiudadCali ---
[INFO] All coverage checks have been met.
[INFO] BUILD SUCCESS

✅ Cobertura: 88% (Supera el 80% requerido)
```

**Ver Reporte HTML:**
```bash
firefox target/site/jacoco/index.html
# o
google-chrome target/site/jacoco/index.html
```

---

### Paso 2: Verificar Pipeline CI/CD (10 segundos)

```bash
cat /home/joseligo/ING-SOFTWARE-2/.github/workflows/CI-CD-Canary.yml | head -30
```

**Verificar que contiene:**
- ✅ `on: push: branches: ["main"]` - Trigger automático
- ✅ `build-and-test` - Job de compilación y tests
- ✅ `mvn test jacoco:report` - Ejecución de tests
- ✅ `mvn jacoco:check` - Verificación de cobertura
- ✅ `canary-deploy` - Job de despliegue Canary
- ✅ `promote-to-production` - Job de promoción
- ✅ `rollback` - Job de rollback

---

### Paso 3: Verificar Despliegue Canary (2 minutos)

```bash
cd /home/joseligo/ING-SOFTWARE-2/ServiCiudadCali

# Desplegar Canary
./scripts/deploy-canary.sh
```

**Resultado Esperado:**
```
🎉 ¡Despliegue Canary completado exitosamente!

📋 Información del despliegue:
  🔗 URL: http://localhost:8081
  📦 Versión: [version]
  🐳 Servicio: app-canary
```

**Verificar Canary está UP:**
```bash
curl http://localhost:8081/actuator/health
```

**Resultado Esperado:**
```json
{"status":"UP","components":{"db":{"status":"UP"},...}}
```

---

### Paso 4: Ejecutar Smoke Tests (30 segundos)

```bash
./scripts/smoke-test-canary.sh
```

**Resultado Esperado:**
```
========================================
  Resumen de Smoke Tests
========================================

  Total de tests: 4
  ✅ Exitosos: 4
  ❌ Fallidos: 0
  📊 Tasa de éxito: 100%

🎉 ¡Todos los smoke tests pasaron!
✅ Canary está listo para promoción
```

---

### Paso 5: Verificar Estado del Sistema (10 segundos)

```bash
./scripts/status.sh
```

**Resultado Esperado:**
```
========================================
  Estado del Sistema
========================================

📦 PRODUCCIÓN (Stable)
───────────────────────────────────────
Estado:    🟢 RUNNING
Puerto:    8080
Health:    ✅ UP

🐤 CANARY (Testing)
───────────────────────────────────────
Estado:    🟢 RUNNING
Puerto:    8081
Health:    ✅ UP

🐳 SERVICIOS DOCKER COMPOSE
───────────────────────────────────────
serviciudadcali-mysql    Up (healthy)
serviciudadcali-stable   Up (healthy)
serviciudadcali-canary   Up (healthy)
```

---

## ✅ Checklist de Verificación Rápida

Marcar cada item después de verificar:

### Requisito 1: Pruebas y Cobertura
- [ ] `mvn verify` completa exitosamente
- [ ] Cobertura ≥ 80% (Actual: 88%)
- [ ] Reporte HTML generado en `target/site/jacoco/`
- [ ] Tests unitarios ejecutan sin errores

### Requisito 2: Pipeline CI/CD
- [ ] Archivo `.github/workflows/CI-CD-Canary.yml` existe
- [ ] Contiene job `build-and-test` con `mvn test`
- [ ] Contiene verificación de cobertura con `jacoco:check`
- [ ] Pipeline configurado para fallar si cobertura < 80%

### Requisito 3: Despliegue Canary
- [ ] `docker-compose.yml` con servicios `app-stable` y `app-canary`
- [ ] Script `deploy-canary.sh` funciona correctamente
- [ ] Canary desplegado en puerto 8081
- [ ] Stable desplegado en puerto 8080
- [ ] Ambos servicios responden al health check
- [ ] Job `canary-deploy` existe en pipeline
- [ ] Job `promote-to-production` existe en pipeline
- [ ] Job `rollback` existe en pipeline

### Requisito 4: Promoción y Rollback
- [ ] Script `promote-canary.sh` funciona
- [ ] Script `rollback.sh` funciona
- [ ] Backup automático antes de promoción
- [ ] Rollback completa en < 1 minuto

---

## 🎬 Demo Completa (Opcional - 10 minutos)

Si quieres demostrar el flujo completo de Canary:

### 1. Desplegar Canary
```bash
./scripts/deploy-canary.sh
```

### 2. Ejecutar Smoke Tests
```bash
./scripts/smoke-test-canary.sh
```

### 3. Ver Estado
```bash
./scripts/status.sh
```

### 4. Promover a Producción
```bash
./scripts/promote-canary.sh
# Responder 'y' cuando pregunte
```

### 5. Verificar Producción
```bash
curl http://localhost:8080/actuator/health
docker ps | grep serviciudadcali
```

### 6. Demo de Rollback (Opcional)
```bash
./scripts/rollback.sh
# Responder 'y' cuando pregunte
```

---

## 📊 Comandos de Verificación Adicionales

### Ver Tests Disponibles
```bash
find src/test -name "*Test.java" -type f
```

### Ver Cobertura por Paquete
```bash
cat target/site/jacoco/index.html | grep -E "package|Total" | head -20
```

### Ver Imágenes Docker
```bash
docker images | grep serviciudadcali
```

### Ver Contenedores Activos
```bash
docker ps | grep serviciudadcali
```

### Ver Logs de Canary
```bash
docker logs serviciudadcali-canary --tail 50
```

### Ver Logs de Stable
```bash
docker logs serviciudadcali-stable --tail 50
```

---

## 🔗 URLs para Pruebas

Después de desplegar:

### Stable (Producción - Puerto 8080)
- Health: http://localhost:8080/actuator/health
- Info: http://localhost:8080/actuator/info
- Metrics: http://localhost:8080/actuator/metrics
- App: http://localhost:8080/

### Canary (Testing - Puerto 8081)
- Health: http://localhost:8081/actuator/health
- Info: http://localhost:8081/actuator/info
- Metrics: http://localhost:8081/actuator/metrics
- App: http://localhost:8081/

---

## ⚡ Comandos de Limpieza (Después de la demo)

```bash
# Detener todos los servicios
docker-compose --profile canary down

# Limpiar contenedores
docker-compose rm -f

# Opcional: Limpiar imágenes
docker rmi serviciudadcali:canary serviciudadcali:latest serviciudadcali:rollback
```

---

## 📝 Notas Importantes

1. **MySQL debe estar corriendo** para que la aplicación funcione
2. **Puertos 8080 y 8081** deben estar libres
3. **Java 21** es requerido para compilar
4. **Docker y Docker Compose** deben estar instalados
5. **Primer despliegue** puede tardar más por descarga de imágenes base

---

## 🆘 Troubleshooting Rápido

### Error: Puerto ocupado
```bash
# Ver qué usa el puerto
sudo lsof -i :8080
sudo lsof -i :8081

# Detener MariaDB si está usando 3306
sudo systemctl stop mariadb
```

### Error: MySQL no conecta
```bash
# Verificar MySQL
docker-compose ps mysql
docker-compose logs mysql

# Restart MySQL
docker-compose restart mysql
sleep 10
```

### Error: Health check falla
```bash
# Ver logs de la aplicación
docker-compose logs app-stable --tail 50
docker-compose --profile canary logs app-canary --tail 50

# Verificar que actuator está configurado
grep "actuator" src/main/resources/application.properties
```

---

**Tiempo Total de Verificación:** < 5 minutos  
**Última actualización:** 24 de noviembre de 2025
