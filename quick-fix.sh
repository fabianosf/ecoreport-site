#!/bin/bash

# Script Rápido para Corrigir 404 - EcoReport Site
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 CORRIGINDO ERRO 404...${NC}\n"

APP_DIR="/var/www/ecoreport-site"
DOMAIN="ecoreport.shop"

# 1. Ir para diretório
cd ${APP_DIR} 2>/dev/null || {
    echo -e "${RED}❌ Diretório ${APP_DIR} não existe!${NC}"
    echo -e "${YELLOW}Execute primeiro: sudo mkdir -p ${APP_DIR} && sudo chown -R \$USER:\$USER ${APP_DIR}${NC}"
    exit 1
}

# 2. Parar PM2 se existir
echo -e "${BLUE}🛑 Parando PM2...${NC}"
pm2 delete ecoreport-site 2>/dev/null || true

# 3. Build (se necessário)
if [ ! -d ".next" ]; then
    echo -e "${BLUE}🔨 Fazendo build...${NC}"
    npm install
    npm run build
fi

# 4. Iniciar com PM2
echo -e "${BLUE}🚀 Iniciando com PM2...${NC}"
pm2 start npm --name ecoreport-site -- start
pm2 save

# Aguardar iniciar
sleep 5

# 5. Verificar se está rodando
if pm2 list | grep -q "ecoreport-site.*online"; then
    echo -e "${GREEN}✅ PM2 está rodando${NC}"
else
    echo -e "${RED}❌ PM2 não está rodando! Verifique os logs:${NC}"
    pm2 logs ecoreport-site --lines 20 --nostream
    exit 1
fi

# 6. Verificar porta 3000
sleep 3
if netstat -tlnp 2>/dev/null | grep -q ":3000" || ss -tlnp 2>/dev/null | grep -q ":3000"; then
    echo -e "${GREEN}✅ Porta 3000 está ativa${NC}"
else
    echo -e "${YELLOW}⚠️  Porta 3000 não detectada ainda${NC}"
fi

# 7. Testar localmente
echo -e "${BLUE}🧪 Testando localmente...${NC}"
if curl -s http://localhost:3000 | grep -q "EcoReport"; then
    echo -e "${GREEN}✅ Aplicação responde em localhost:3000${NC}"
else
    echo -e "${YELLOW}⚠️  Aplicação não respondeu como esperado${NC}"
    curl -I http://localhost:3000 || echo "Erro ao conectar"
fi

# 8. Configurar Nginx
echo -e "${BLUE}🌐 Configurando Nginx...${NC}"
sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINXEOF

# 9. Ativar site
sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# 10. Testar e recarregar Nginx
echo -e "${BLUE}🧪 Testando Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuração Nginx OK${NC}"
    sudo systemctl reload nginx
else
    echo -e "${RED}❌ Erro na configuração Nginx!${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ CONCLUÍDO!${NC}\n"
echo -e "${BLUE}Teste: curl -I http://${DOMAIN}${NC}"

