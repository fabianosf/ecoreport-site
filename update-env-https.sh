#!/bin/bash

# Script para Atualizar .env.local para HTTPS
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 ATUALIZANDO .env.local PARA HTTPS${NC}\n"

APP_DIR="/var/www/ecoreport-site"

cd ${APP_DIR}

# Fazer backup do .env.local atual
if [ -f ".env.local" ]; then
    echo -e "${BLUE}📋 Fazendo backup do .env.local...${NC}"
    cp .env.local .env.local.backup
    echo -e "${GREEN}✅ Backup criado${NC}\n"
fi

# Atualizar NEXT_PUBLIC_SITE_URL para HTTPS
echo -e "${BLUE}🌐 Atualizando NEXT_PUBLIC_SITE_URL para HTTPS...${NC}"
if grep -q "NEXT_PUBLIC_SITE_URL=https://ecoreport.shop" .env.local 2>/dev/null; then
    echo -e "${GREEN}✅ NEXT_PUBLIC_SITE_URL já está configurado para HTTPS${NC}"
else
    # Remover linha antiga se existir
    sed -i '/NEXT_PUBLIC_SITE_URL=/d' .env.local 2>/dev/null || true
    # Adicionar nova linha
    echo "NEXT_PUBLIC_SITE_URL=https://ecoreport.shop" >> .env.local
    echo -e "${GREEN}✅ NEXT_PUBLIC_SITE_URL atualizado para HTTPS${NC}"
fi

# Mostrar arquivo atualizado
echo -e "\n${BLUE}📄 Conteúdo do .env.local:${NC}"
cat .env.local

echo -e "\n${YELLOW}⚠️  IMPORTANTE: Reiniciar PM2 para aplicar mudanças${NC}"
echo -e "${BLUE}   Execute: pm2 restart ecoreport-site${NC}\n"

