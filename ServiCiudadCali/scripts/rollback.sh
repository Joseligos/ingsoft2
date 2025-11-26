#!/bin/bash
# Script para hacer rollback a la versión anterior usando Docker Compose
# Uso: ./rollback.sh

set -e

cd "$(dirname "$0")/.."

# Colores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

STABLE_PORT=8080
REGISTRY="ghcr.io"
IMAGE_NAME="joseligos/ingsoft2/serviciudadcali"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Rollback a Versión Anterior${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Intentar descargar imagen de rollback desde GHCR
echo -e "${CYAN}🔍 Buscando imagen de rollback en GHCR...${NC}"
if docker pull ${REGISTRY}/${IMAGE_NAME}:rollback 2>/dev/null; then
  echo -e "${GREEN}✅ Imagen de rollback descargada de GHCR${NC}"
  docker tag ${REGISTRY}/${IMAGE_NAME}:rollback serviciudadcali:rollback
elif docker images | grep -q "serviciudadcali.*rollback"; then
  echo -e "${YELLOW}⚠️  Usando imagen de rollback local${NC}"
else
  echo -e "${RED}❌ ERROR: No existe imagen de backup (rollback)${NC}"
  echo -e "${YELLOW}💡 No hay versión anterior disponible para restaurar${NC}"
  exit 1
fi
echo ""

# Obtener versión actual (si existe)
if docker compose ps app-stable | grep -q "Up"; then
  CURRENT_VERSION=$(docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' serviciudadcali-stable | grep VERSION | cut -d'=' -f2 || echo "unknown")
  echo -e "${CYAN}📦 Versión actual: ${CURRENT_VERSION}${NC}"
else
  echo -e "${YELLOW}⚠️  No hay versión activa en producción${NC}"
fi
echo ""

# Confirmación
echo -e "${YELLOW}⚠️  ¿Está seguro de hacer rollback?${NC}"
echo -e "${YELLOW}   Esto revertirá a la versión anterior.${NC}"
echo -e "${YELLOW}   [y/N]:${NC} "
read -r confirmation

if [ "$confirmation" != "y" ] && [ "$confirmation" != "Y" ]; then
  echo -e "${RED}❌ Rollback cancelado${NC}"
  exit 0
fi

echo ""

# Paso 1: Detener versión actual
echo -e "${CYAN}🛑 Paso 1/4: Deteniendo versión actual...${NC}"
docker compose stop app-stable 2>/dev/null || true
docker compose rm -f app-stable 2>/dev/null || true
echo -e "${GREEN}✅ Versión actual detenida${NC}"
echo ""

# Paso 2: Restaurar imagen de rollback como stable (local y GHCR)
echo -e "${CYAN}🔄 Paso 2/4: Restaurando versión anterior...${NC}"
docker tag serviciudadcali:rollback serviciudadcali:stable

# Actualizar stable en GHCR también
echo -e "${CYAN}📤 Actualizando STABLE en GHCR...${NC}"
docker tag serviciudadcali:rollback ${REGISTRY}/${IMAGE_NAME}:stable
if docker push ${REGISTRY}/${IMAGE_NAME}:stable 2>/dev/null; then
  echo -e "${GREEN}✅ STABLE restaurada en GHCR${NC}"
else
  echo -e "${YELLOW}⚠️  Solo restaurada localmente${NC}"
fi

docker compose up -d app-stable

echo -e "${GREEN}✅ Versión anterior desplegada${NC}"
echo ""

# Paso 3: Esperar inicio
echo -e "${CYAN}⏳ Paso 3/4: Esperando inicio de la aplicación...${NC}"
sleep 30
echo ""

# Paso 4: Health Check
echo -e "${CYAN}🔍 Paso 4/4: Verificando health de producción...${NC}"

MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if curl -sf http://localhost:${STABLE_PORT}/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Versión anterior está saludable!${NC}"
    break
  fi
  
  RETRY_COUNT=$((RETRY_COUNT + 1))
  
  if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}❌ ERROR: La versión anterior no responde${NC}"
    echo -e "${YELLOW}⚠️  Se requiere intervención manual${NC}"
    exit 1
  fi
  
  echo -e "${YELLOW}⏳ Intento ${RETRY_COUNT}/${MAX_RETRIES} - Reintentando en 5 segundos...${NC}"
  sleep 5
done

echo ""

# Éxito
echo -e "${GREEN}🎉 ¡Rollback completado exitosamente!${NC}"
echo ""
echo -e "${CYAN}📋 Información del despliegue:${NC}"
echo -e "  🔗 URL: http://localhost:${STABLE_PORT}"
echo -e "  📦 Versión: rollback"
echo -e "  🐳 Servicio: app-stable"
echo ""
echo -e "${CYAN}📋 Comandos útiles:${NC}"
echo -e "  📝 Ver logs: docker compose logs -f app-stable"
echo -e "  📊 Ver estado: docker compose ps"
echo -e "  💊 Health: curl http://localhost:${STABLE_PORT}/actuator/health"
echo ""
echo -e "${YELLOW}⚠️  Nota: Se ha restaurado la versión anterior${NC}"
echo -e "${YELLOW}   Investigue la causa del problema antes de volver a desplegar${NC}"
echo ""
