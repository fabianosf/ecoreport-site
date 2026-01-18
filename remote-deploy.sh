#!/bin/bash

# Script de Deploy Remoto - EcoReport Site
# Conecta ao servidor e faz deploy automático

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variáveis
SERVER_IP="92.113.33.16"
SERVER_USER="fabianosf"
APP_DIR="/var/www/ecoreport-site"

echo -e "${BLUE}🚀 Deploy Remoto - EcoReport Site${NC}\n"

# 1. Build local primeiro
echo -e "${BLUE}📦 Fazendo build local...${NC}"
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erro no build! Corrija antes de fazer deploy.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build local concluído!${NC}\n"

# 2. Deploy no servidor
echo -e "${BLUE}📤 Fazendo deploy no servidor...${NC}"

ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
cd /var/www/ecoreport-site
git pull origin main
npm install --production
npm run build
pm2 restart ecoreport-site || pm2 start npm --name ecoreport-site -- start
pm2 save
echo "✅ Deploy concluído no servidor!"
ENDSSH

echo -e "${GREEN}✅ Deploy remoto concluído!${NC}\n"
echo -e "${BLUE}🌐 Acesse: https://ecoreport.shop${NC}"

