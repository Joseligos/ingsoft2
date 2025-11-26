#!/bin/bash
# Script para hacer login en GitHub Container Registry (GHCR)
# Uso: ./ghcr-login.sh [github_username] [github_token]

set -e

# Colores
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REGISTRY="ghcr.io"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  Login a GitHub Container Registry${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Obtener credenciales
if [ -n "$1" ] && [ -n "$2" ]; then
  GITHUB_USERNAME="$1"
  GITHUB_TOKEN="$2"
else
  echo -e "${YELLOW}Para hacer login en GHCR necesitas:${NC}"
  echo -e "${YELLOW}  1. Tu username de GitHub${NC}"
  echo -e "${YELLOW}  2. Un Personal Access Token (PAT) con permisos:${NC}"
  echo -e "${YELLOW}     - write:packages${NC}"
  echo -e "${YELLOW}     - read:packages${NC}"
  echo ""
  echo -e "${CYAN}Crear token: https://github.com/settings/tokens/new${NC}"
  echo ""
  
  read -p "GitHub Username: " GITHUB_USERNAME
  read -sp "GitHub Token (PAT): " GITHUB_TOKEN
  echo ""
  echo ""
fi

# Validar credenciales
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo -e "${RED}❌ ERROR: Username y token son requeridos${NC}"
  exit 1
fi

# Login
echo -e "${CYAN}🔐 Haciendo login en ${REGISTRY}...${NC}"
if echo "$GITHUB_TOKEN" | docker login $REGISTRY -u "$GITHUB_USERNAME" --password-stdin 2>/dev/null; then
  echo -e "${GREEN}✅ Login exitoso en GHCR${NC}"
  echo ""
  echo -e "${GREEN}Ahora puedes:${NC}"
  echo -e "  📤 Subir imágenes: docker push ${REGISTRY}/[usuario]/[repo]/[imagen]:[tag]"
  echo -e "  📥 Descargar imágenes: docker pull ${REGISTRY}/[usuario]/[repo]/[imagen]:[tag]"
  echo ""
  echo -e "${CYAN}💡 Los scripts deploy-canary.sh, promote-canary.sh y rollback.sh${NC}"
  echo -e "${CYAN}   ahora pueden subir/descargar imágenes a/desde GHCR${NC}"
  echo ""
else
  echo -e "${RED}❌ ERROR: Login falló${NC}"
  echo -e "${YELLOW}Verifica:${NC}"
  echo -e "  - Username correcto"
  echo -e "  - Token válido con permisos: write:packages, read:packages"
  echo -e "  - Token no expirado"
  exit 1
fi
