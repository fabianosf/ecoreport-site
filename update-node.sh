#!/bin/bash

# Script para Atualizar Node.js para versão 20
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📦 ATUALIZANDO NODE.JS PARA VERSÃO 20${NC}\n"

# Verificar versão atual
CURRENT_VERSION=$(node --version 2>/dev/null || echo "não instalado")
echo -e "${YELLOW}Versão atual: ${CURRENT_VERSION}${NC}\n"

# 1. Instalar Node.js 20
echo -e "${BLUE}📦 Instalando Node.js 20...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 2. Verificar versão instalada
NEW_VERSION=$(node --version)
echo -e "\n${GREEN}✅ Node.js atualizado para: ${NEW_VERSION}${NC}\n"

# 3. Verificar npm
NPM_VERSION=$(npm --version)
echo -e "${GREEN}✅ npm versão: ${NPM_VERSION}${NC}\n"

# 4. Verificar se atende requisitos
MAJOR_VERSION=$(echo $NEW_VERSION | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$MAJOR_VERSION" -ge "20" ]; then
    echo -e "${GREEN}✅ Node.js versão 20 ou superior instalada!${NC}\n"
    echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
    echo -e "   1. cd /var/www/ecoreport-site"
    echo -e "   2. npm run build"
    echo -e "   3. pm2 restart ecoreport-site\n"
else
    echo -e "${RED}❌ Erro: Node.js ainda não está na versão 20!${NC}"
    exit 1
fi

