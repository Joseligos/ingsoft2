#!/bin/bash
# Script para promover Canary a Producción usando Docker Compose
# Uso: ./promote-canary.sh

set -e

cd "$(dirname "$0")/.."

# Colores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

STABLE_PORT=8080

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Promoción Canary → Producción${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Verificar que Canary esté corriendo
if ! docker compose --profile canary ps app-canary | grep -q "Up"; then
  echo -e "${RED}❌ ERROR: No hay ninguna versión Canary activa${NC}"
  echo -e "${YELLOW}💡 Primero despliegue Canary con: ./scripts/deploy-canary.sh${NC}"
  exit 1
fi

# Obtener versión de Canary
CANARY_VERSION=$(docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' serviciudadcali-canary | grep VERSION | cut -d'=' -f2 || echo "unknown")

echo -e "${CYAN}📦 Versión Canary: ${CANARY_VERSION}${NC}"
echo ""

# Confirmación
echo -e "${YELLOW}⚠️  ¿Está seguro de promover Canary a Producción?${NC}"
echo -e "${YELLOW}   Esto reemplazará la versión actual en producción.${NC}"
echo -e "${YELLOW}   [y/N]:${NC} "
read -r confirmation

if [ "$confirmation" != "y" ] && [ "$confirmation" != "Y" ]; then
  echo -e "${RED}❌ Promoción cancelada${NC}"
  exit 0
fi

echo ""

# Paso 1: Crear backup etiquetando imagen actual
echo -e "${CYAN}📦 Paso 1/5: Creando backup de versión actual...${NC}"
if docker compose ps app-stable | grep -q "Up"; then
  CURRENT_IMAGE=$(docker inspect serviciudadcali-stable --format='{{.Image}}' 2>/dev/null || echo "")
  if [ -n "$CURRENT_IMAGE" ]; then
    docker tag $CURRENT_IMAGE serviciudadcali:rollback
    echo -e "${GREEN}✅ Backup creado como serviciudadcali:rollback${NC}"
  else
    echo -e "${YELLOW}⚠️  No se pudo hacer backup${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  No hay versión en producción para hacer backup${NC}"
fi
echo ""

# Paso 2: Detener producción actual
echo -e "${CYAN}🛑 Paso 2/5: Deteniendo versión actual en producción...${NC}"
docker compose stop app-stable 2>/dev/null || true
docker compose rm -f app-stable 2>/dev/null || true
echo -e "${GREEN}✅ Versión anterior detenida${NC}"
echo ""

# Paso 3: Etiquetar imagen canary como stable
echo -e "${CYAN}🐳 Paso 3/5: Promoviendo imagen Canary...${NC}"
docker tag serviciudadcali:canary serviciudadcali:stable
echo -e "${GREEN}✅ Imagen promovida: serviciudadcali:canary → serviciudadcali:stable${NC}"
echo ""

# Paso 4: Desplegar en producción
echo -e "${CYAN}🚀 Paso 4/5: Desplegando en producción...${NC}"
VERSION=${CANARY_VERSION} docker compose up -d app-stable

echo -e "${GREEN}✅ Nueva versión desplegada en producción${NC}"
echo ""

# Paso 5: Health Check
echo -e "${CYAN}🔍 Paso 5/5: Verificando health de producción...${NC}"
sleep 30

MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if curl -sf http://localhost:${STABLE_PORT}/actuator/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Producción está saludable!${NC}"
    break
  fi
  
  RETRY_COUNT=$((RETRY_COUNT + 1))
  
  if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}❌ ERROR: Producción no responde al health check${NC}"
    echo -e "${YELLOW}🔄 Iniciando rollback automático...${NC}"
    
    # Rollback automático
    docker compose stop app-stable
    docker compose rm -f app-stable
    docker tag serviciudadcali:rollback serviciudadcali:stable
    docker compose up -d app-stable
    
    echo -e "${GREEN}✅ Rollback completado - Versión anterior restaurada${NC}"
    exit 1
  fi
  
  echo -e "${YELLOW}⏳ Intento ${RETRY_COUNT}/${MAX_RETRIES} - Reintentando en 5 segundos...${NC}"
  sleep 5
done

echo ""

# Limpiar Canary
echo -e "${CYAN}🧹 Limpiando versión Canary...${NC}"
docker compose --profile canary stop app-canary 2>/dev/null || true
docker compose --profile canary rm -f app-canary 2>/dev/null || true
echo -e "${GREEN}✅ Canary removido${NC}"
echo ""

# Éxito
echo -e "${GREEN}🎉 ¡Promoción completada exitosamente!${NC}"
echo ""
echo -e "${CYAN}📋 Información del despliegue:${NC}"
echo -e "  🔗 URL: http://localhost:${STABLE_PORT}"
echo -e "  📦 Versión: ${CANARY_VERSION}"
echo -e "  🐳 Servicio: app-stable"
echo ""
echo -e "${CYAN}📋 Comandos útiles:${NC}"
echo -e "  📝 Ver logs: docker compose logs -f app-stable"
echo -e "  📊 Ver estado: docker compose ps"
echo -e "  🔄 Rollback: ./scripts/rollback.sh"
echo ""
