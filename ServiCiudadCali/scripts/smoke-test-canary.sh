#!/bin/bash
# Script para ejecutar smoke tests en Canary
# Uso: ./smoke-test-canary.sh

set -e

# Colores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variables
CANARY_URL="http://localhost:8081"
FAILED_TESTS=0
TOTAL_TESTS=0

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Smoke Tests - Versión Canary${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Verificar que Canary esté corriendo
if ! docker ps | grep -q serviciudadcali-canary; then
  echo -e "${RED}❌ ERROR: No hay ninguna versión Canary activa${NC}"
  exit 1
fi

# Función para ejecutar test
run_test() {
  local test_name=$1
  local endpoint=$2
  local expected_status=${3:-200}
  
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  
  echo -e "${CYAN}🧪 Test ${TOTAL_TESTS}: ${test_name}${NC}"
  echo -e "   Endpoint: ${endpoint}"
  
  # Ejecutar request
  response=$(curl -s -w "\n%{http_code}" "${CANARY_URL}${endpoint}" 2>&1 || echo "000")
  http_code=$(echo "$response" | tail -n1)
  body=$(echo "$response" | sed '$d')
  
  # Validar código HTTP
  if [ "$http_code" -eq "$expected_status" ]; then
    echo -e "${GREEN}   ✅ Status: ${http_code} (esperado: ${expected_status})${NC}"
    
    # Validar respuesta JSON (si aplica) - solo si jq está instalado
    if [ "$expected_status" -eq 200 ] && [ -n "$body" ] && command -v jq &> /dev/null; then
      if echo "$body" | jq empty 2>/dev/null; then
        echo -e "${GREEN}   ✅ Respuesta JSON válida${NC}"
      fi
    fi
    
    echo ""
    return 0
  else
    echo -e "${RED}   ❌ Status: ${http_code} (esperado: ${expected_status})${NC}"
    echo -e "${RED}   Body: ${body}${NC}"
    echo ""
    FAILED_TESTS=$((FAILED_TESTS + 1))
    return 1
  fi
}

# Smoke Tests
echo -e "${CYAN}Ejecutando smoke tests...${NC}"
echo ""

# Test 1: Health Check
run_test "Health Check" "/actuator/health" 200

# Test 2: Info endpoint
run_test "Info Endpoint" "/actuator/info" 200

# Test 3: Consultar deuda sin cliente (404 esperado)
run_test "Deuda sin cliente existente" "/api/deudaConsolidada/ObtenerDeudaConsolidadaPorClienteId/99999" 404

# Test 4: Root endpoint (si existe)
run_test "Root Endpoint" "/" 200

# Resumen
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Resumen de Smoke Tests${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

PASSED_TESTS=$((TOTAL_TESTS - FAILED_TESTS))
PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))

echo -e "  Total de tests: ${TOTAL_TESTS}"
echo -e "  ✅ Exitosos: ${PASSED_TESTS}"
echo -e "  ❌ Fallidos: ${FAILED_TESTS}"
echo -e "  📊 Tasa de éxito: ${PASS_RATE}%"
echo ""

# Resultado final
if [ $FAILED_TESTS -eq 0 ]; then
  echo -e "${GREEN}🎉 ¡Todos los smoke tests pasaron!${NC}"
  echo -e "${GREEN}✅ Canary está listo para promoción${NC}"
  echo ""
  exit 0
else
  echo -e "${RED}❌ Algunos tests fallaron${NC}"
  echo -e "${YELLOW}⚠️  Revise los errores antes de promover a producción${NC}"
  echo ""
  exit 1
fi
