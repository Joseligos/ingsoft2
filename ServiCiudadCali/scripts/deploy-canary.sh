#!/bin/bash
# Script para desplegar versión Canary usando Docker Compose
# Uso: ./deploy-canary.sh [version]

set -e

# Colores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variables
VERSION=${1:-$(git describe --tags --always --dirty 2>/dev/null || echo "dev-$(date +%Y%m%d-%H%M%S)")}
CANARY_PORT=8081

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Despliegue Canary - ServiCiudadCali${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Versión: ${VERSION}${NC}"
echo ""

# Verificar si stable está corriendo
if ! docker ps | grep -q "serviciudadcali-stable"; then
  echo -e "${YELLOW}========================================${NC}"
  echo -e "${YELLOW}⚠️  PRIMER DESPLIEGUE - No hay versión stable${NC}"
  echo -e "${YELLOW}========================================${NC}"
  echo ""
  echo -e "${YELLOW}Este parece ser el primer despliegue. En un despliegue Canary:${NC}"
  echo -e "${YELLOW}- STABLE (puerto 8080): Versión actual en producción (vieja)${NC}"
  echo -e "${YELLOW}- CANARY (puerto 8081): Versión nueva en prueba${NC}"
  echo ""
  echo -e "${CYAN}¿Desea desplegar esta versión como STABLE inicial? [y/N]:${NC} "
  read -r deploy_stable
  
  if [ "$deploy_stable" = "y" ] || [ "$deploy_stable" = "Y" ]; then
    echo ""
    echo -e "${CYAN}🚀 Desplegando como versión STABLE inicial...${NC}"
    
    # Compilar y construir imagen
    mvn clean package -DskipTests
    VERSION=${VERSION} docker compose -f docker-compose.build.yml build
    
    # En el primer despliegue, la nueva imagen se convierte en stable
    docker tag serviciudadcali:latest serviciudadcali:stable
    
    # Desplegar MySQL
    docker compose up -d mysql
    sleep 10
    
    # Desplegar como stable
    VERSION=${VERSION} docker compose up -d app-stable
    
    echo -e "${GREEN}✅ Primera versión desplegada como STABLE en puerto 8080${NC}"
    echo ""
    echo -e "${CYAN}ℹ️  Nota: Este es el primer despliegue${NC}"
    echo -e "${CYAN}ℹ️  En el próximo despliegue:${NC}"
    echo -e "${CYAN}   - Esta versión será STABLE (vieja) en puerto 8080${NC}"
    echo -e "${CYAN}   - La nueva versión será CANARY (nueva) en puerto 8081${NC}"
    echo ""
    
    # Health check
    sleep 30
    if curl -sf http://localhost:8080/actuator/health > /dev/null 2>&1; then
      echo -e "${GREEN}✅ Versión STABLE está saludable!${NC}"
      echo -e "${GREEN}🔗 URL: http://localhost:8080${NC}"
    else
      echo -e "${RED}❌ Error: La versión no responde${NC}"
      exit 1
    fi
    
    exit 0
  else
    echo -e "${RED}❌ Despliegue cancelado${NC}"
    echo -e "${YELLOW}💡 Para configurar manualmente:${NC}"
    echo -e "${YELLOW}   1. Construir imagen: docker compose -f docker-compose.build.yml build${NC}"
    echo -e "${YELLOW}   2. Etiquetar como stable: docker tag serviciudadcali:latest serviciudadcali:stable${NC}"
    echo -e "${YELLOW}   3. Desplegar: docker compose up -d app-stable${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ DESPLIEGUE CANARY - Stable ya existe${NC}"
echo -e "${GREEN}========================================${NC}"

# Obtener versión de stable actual (la vieja)
STABLE_VERSION=$(docker inspect serviciudadcali-stable --format='{{range .Config.Env}}{{println .}}{{end}}' | grep VERSION | cut -d'=' -f2 || echo "unknown")
echo -e "${CYAN}📦 Versión STABLE actual (vieja): ${STABLE_VERSION}${NC}"
echo -e "${CYAN}📦 Versión CANARY nueva: ${VERSION}${NC}"
echo ""

echo -e "${YELLOW}Se desplegará la NUEVA versión como Canary en paralelo:${NC}"
echo -e "${YELLOW}  Puerto 8080: STABLE v${STABLE_VERSION} (versión VIEJA)${NC}"
echo -e "${YELLOW}  Puerto 8081: CANARY v${VERSION} (versión NUEVA)${NC}"
echo ""

# Paso 1: Build del proyecto Maven
echo -e "${CYAN}🏗️  Paso 1/5: Compilando proyecto Maven...${NC}"
cd "$(dirname "$0")/.."
mvn clean package -DskipTests
echo -e "${GREEN}✅ Proyecto compilado${NC}"
echo ""

# Paso 2: Build de la imagen con Docker Compose
echo -e "${CYAN}🐳 Paso 2/5: Construyendo imagen Docker...${NC}"
VERSION=${VERSION} docker compose -f docker-compose.build.yml build
docker tag serviciudadcali:latest serviciudadcali:canary
echo -e "${GREEN}✅ Imagen construida y etiquetada como canary${NC}"
echo ""

# Paso 3: Detener Canary anterior
echo -e "${CYAN}🛑 Paso 3/5: Deteniendo Canary anterior (si existe)...${NC}"
docker compose --profile canary stop app-canary 2>/dev/null || true
docker compose --profile canary rm -f app-canary 2>/dev/null || true
echo -e "${GREEN}✅ Canary anterior removido${NC}"
echo ""

# Paso 4: Desplegar nueva versión Canary
echo -e "${CYAN}🚀 Paso 4/5: Desplegando nueva versión Canary...${NC}"
VERSION=${VERSION} docker compose --profile canary up -d app-canary
echo -e "${GREEN}✅ Canary desplegado en puerto ${CANARY_PORT}${NC}"
echo ""

# Paso 5: Esperar inicialización
echo -e "${CYAN}⏳ Paso 5/5: Esperando inicialización (30 segundos)...${NC}"
sleep 30
echo ""

# Health Check
echo -e "${CYAN}🔍 Verificando health...${NC}"
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if curl -sf http://localhost:${CANARY_PORT}/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Canary está saludable!${NC}"
    echo ""
    echo -e "${GREEN}🎉 Despliegue Canary completado exitosamente!${NC}"
    echo ""
    echo -e "${CYAN}📋 Información del despliegue:${NC}"
    echo -e "  🔗 URL: http://localhost:${CANARY_PORT}"
    echo -e "  📦 Versión: ${VERSION}"
    echo -e "  🐳 Servicio: app-canary"
    echo ""
    echo -e "${YELLOW}📋 Próximos pasos:${NC}"
    echo -e "  1. Monitorear logs: docker compose --profile canary logs -f app-canary"
    echo -e "  2. Ejecutar smoke tests: ./scripts/smoke-test-canary.sh"
    echo -e "  3. Verificar estado: ./scripts/status.sh"
    echo -e "  4. Promover a producción: ./scripts/promote-canary.sh"
    echo ""
    exit 0
  fi
  
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo -e "${YELLOW}⏳ Intento ${RETRY_COUNT}/${MAX_RETRIES} - Reintentando en 5 segundos...${NC}"
  sleep 5
done

echo -e "${RED}❌ ERROR: Canary no responde al health check después de ${MAX_RETRIES} intentos${NC}"
echo -e "${YELLOW}📝 Mostrando últimos logs:${NC}"
docker compose --profile canary logs --tail 50 app-canary
echo ""
echo -e "${RED}🛑 Deteniendo Canary fallido...${NC}"
docker compose --profile canary stop app-canary
docker compose --profile canary rm -f app-canary
exit 1
