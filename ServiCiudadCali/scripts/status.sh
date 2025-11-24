#!/bin/bash
# Script para verificar el estado de los despliegues usando Docker Compose
# Uso: ./status.sh

set -e

cd "$(dirname "$0")/.."

# Colores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

STABLE_PORT=8080
CANARY_PORT=8081

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Estado del Sistema${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Función para obtener estado de servicio
get_service_status() {
  local service=$1
  local profile=$2
  
  if [ -n "$profile" ]; then
    if docker-compose --profile $profile ps $service 2>/dev/null | grep -q "Up"; then
      echo -e "${GREEN}🟢 RUNNING${NC}"
    elif docker-compose --profile $profile ps -a $service 2>/dev/null | grep -q "$service"; then
      echo -e "${RED}🔴 STOPPED${NC}"
    else
      echo -e "${YELLOW}⚪ NOT DEPLOYED${NC}"
    fi
  else
    if docker-compose ps $service 2>/dev/null | grep -q "Up"; then
      echo -e "${GREEN}🟢 RUNNING${NC}"
    elif docker-compose ps -a $service 2>/dev/null | grep -q "$service"; then
      echo -e "${RED}🔴 STOPPED${NC}"
    else
      echo -e "${YELLOW}⚪ NOT DEPLOYED${NC}"
    fi
  fi
}

# Función para obtener versión
get_version() {
  local container=$1
  if docker ps | grep -q "${container}"; then
    version=$(docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' ${container} | grep VERSION | cut -d'=' -f2 2>/dev/null || echo "unknown")
    echo "${version}"
  else
    echo "N/A"
  fi
}

# Función para health check
check_health() {
  local url=$1
  if curl -sf ${url}/actuator/health > /dev/null 2>&1; then
    health=$(curl -s ${url}/actuator/health | jq -r '.status' 2>/dev/null || echo "UNKNOWN")
    if [ "$health" = "UP" ]; then
      echo -e "${GREEN}✅ UP${NC}"
    else
      echo -e "${YELLOW}⚠️  ${health}${NC}"
    fi
  else
    echo -e "${RED}❌ DOWN${NC}"
  fi
}

# Función para obtener uptime
get_uptime() {
  local container=$1
  if docker ps | grep -q "${container}"; then
    uptime=$(docker inspect --format='{{.State.StartedAt}}' ${container} | xargs -I {} date -d {} +%s 2>/dev/null || echo "0")
    now=$(date +%s)
    diff=$((now - uptime))
    
    if [ $diff -gt 0 ]; then
      hours=$((diff / 3600))
      minutes=$(((diff % 3600) / 60))
      seconds=$((diff % 60))
      echo "${hours}h ${minutes}m ${seconds}s"
    else
      echo "N/A"
    fi
  else
    echo "N/A"
  fi
}

# PRODUCCIÓN
echo -e "${CYAN}📦 PRODUCCIÓN (Stable)${NC}"
echo "───────────────────────────────────────"
echo -e "Estado:    $(get_service_status app-stable)"
echo -e "Puerto:    ${STABLE_PORT}"
echo -e "Versión:   $(get_version serviciudadcali-stable)"
echo -e "Health:    $(check_health http://localhost:${STABLE_PORT})"
echo -e "Uptime:    $(get_uptime serviciudadcali-stable)"

if docker ps | grep -q "serviciudadcali-stable"; then
  echo -e "URL:       ${GREEN}http://localhost:${STABLE_PORT}${NC}"
fi
echo ""

# CANARY
echo -e "${CYAN}🐤 CANARY (Testing)${NC}"
echo "───────────────────────────────────────"
echo -e "Estado:    $(get_service_status app-canary canary)"
echo -e "Puerto:    ${CANARY_PORT}"
echo -e "Versión:   $(get_version serviciudadcali-canary)"
echo -e "Health:    $(check_health http://localhost:${CANARY_PORT})"
echo -e "Uptime:    $(get_uptime serviciudadcali-canary)"

if docker ps | grep -q "serviciudadcali-canary"; then
  echo -e "URL:       ${GREEN}http://localhost:${CANARY_PORT}${NC}"
fi
echo ""

# SERVICIOS DOCKER COMPOSE
echo -e "${CYAN}🐳 SERVICIOS DOCKER COMPOSE${NC}"
echo "───────────────────────────────────────"
docker-compose ps
echo ""

# IMÁGENES DOCKER
echo -e "${CYAN}🖼️  IMÁGENES DOCKER${NC}"
echo "───────────────────────────────────────"
if docker images | grep -q "serviciudadcali"; then
  docker images serviciudadcali --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
else
  echo -e "${YELLOW}⚠️  No hay imágenes de serviciudadcali${NC}"
fi
echo ""

# RECURSOS
echo -e "${CYAN}💾 USO DE RECURSOS${NC}"
echo "───────────────────────────────────────"

if docker ps | grep -q "serviciudadcali-stable"; then
  echo -e "${GREEN}Producción:${NC}"
  docker stats --no-stream --format "  CPU: {{.CPUPerc}}\tMemoria: {{.MemUsage}}" serviciudadcali-stable 2>/dev/null || echo "  N/A"
fi

if docker ps | grep -q "serviciudadcali-canary"; then
  echo -e "${YELLOW}Canary:${NC}"
  docker stats --no-stream --format "  CPU: {{.CPUPerc}}\tMemoria: {{.MemUsage}}" serviciudadcali-canary 2>/dev/null || echo "  N/A"
fi
echo ""

# RECOMENDACIONES
echo -e "${CYAN}💡 ACCIONES DISPONIBLES${NC}"
echo "───────────────────────────────────────"

if docker ps | grep -q "serviciudadcali-canary"; then
  echo -e "  📊 Smoke tests:   ${GREEN}./scripts/smoke-test-canary.sh${NC}"
  echo -e "  ⬆️  Promoción:     ${GREEN}./scripts/promote-canary.sh${NC}"
  echo -e "  📝 Logs:          ${GREEN}docker-compose --profile canary logs -f app-canary${NC}"
else
  echo -e "  🚀 Deploy Canary: ${GREEN}./scripts/deploy-canary.sh${NC}"
fi

if docker ps | grep -q "serviciudadcali-stable"; then
  echo -e "  🔄 Rollback:      ${YELLOW}./scripts/rollback.sh${NC}"
  echo -e "  📝 Logs:          ${GREEN}docker-compose logs -f app-stable${NC}"
fi

echo ""
