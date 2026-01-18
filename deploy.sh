#!/bin/bash

# Script de Deploy para Servidor - EcoReport Site
# Servidor: 92.113.33.16
# Domínio: ecoreport.shop

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Iniciando deploy do EcoReport Site...${NC}\n"

# Variáveis
SERVER_IP="92.113.33.16"
SERVER_USER="fabianosf"
DOMAIN="ecoreport.shop"
APP_DIR="/var/www/ecoreport-site"
REPO_URL="https://github.com/fabianosf/ecoreport-site.git"

# 1. Build local
echo -e "${BLUE}📦 Fazendo build de produção...${NC}"
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erro no build! Corrija os erros antes de fazer deploy.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build concluído com sucesso!${NC}\n"

# 2. Verificar se .env.local existe
if [ ! -f ".env.local" ]; then
    echo -e "${YELLOW}⚠️  Arquivo .env.local não encontrado!${NC}"
    echo -e "${YELLOW}   Certifique-se de criar o arquivo .env.local no servidor.${NC}\n"
fi

# 3. Instruções para deploy no servidor
echo -e "${BLUE}📋 PRÓXIMOS PASSOS NO SERVIDOR:${NC}\n"
echo -e "${GREEN}1. Conecte-se ao servidor:${NC}"
echo -e "   ssh ${SERVER_USER}@${SERVER_IP}\n"

echo -e "${GREEN}2. Execute os seguintes comandos no servidor:${NC}"
echo -e "   cd ${APP_DIR}"
echo -e "   git pull origin main"
echo -e "   npm install --production"
echo -e "   npm run build"
echo -e "   pm2 restart ecoreport-site || pm2 start npm --name ecoreport-site -- start\n"

echo -e "${GREEN}3. Ou use o script de setup automático:${NC}"
echo -e "   ./server-setup.sh\n"

echo -e "${BLUE}✅ Código pronto para deploy!${NC}"
echo -e "${BLUE}📝 Commit enviado para GitHub:${NC}"
git log -1 --oneline

