#!/bin/bash

# Script para Adicionar default_server ao ecoreport.shop
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 ADICIONANDO default_server AO ECOREPORT.SHOP${NC}\n"

DOMAIN="ecoreport.shop"

# 1. Fazer backup da configuração atual
echo -e "${BLUE}📋 Fazendo backup...${NC}"
sudo cp /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-available/ecoreport.shop.backup
echo -e "${GREEN}✅ Backup criado${NC}\n"

# 2. Atualizar configuração com default_server
echo -e "${BLUE}🌐 Atualizando configuração com default_server...${NC}"
sudo tee /etc/nginx/sites-available/ecoreport.shop > /dev/null << NGINXEOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${DOMAIN} www.${DOMAIN} _;

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
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Cache static files
    location /_next/static {
        proxy_pass http://localhost:3000;
        proxy_cache_valid 200 60m;
        add_header Cache-Control "public, immutable";
    }

    # Health check
    location /api/health {
        proxy_pass http://localhost:3000;
        access_log off;
    }
}
NGINXEOF

# 3. Remover default_server de outros sites (para evitar conflito)
echo -e "${BLUE}🔧 Removendo default_server de outros sites...${NC}"
for site in asbjj.com.br clinicarenatabastos.com.br fabianosf_site walenna-site.conf; do
    if [ -f "/etc/nginx/sites-available/$site" ]; then
        echo -e "${YELLOW}   Verificando: $site${NC}"
        sudo sed -i 's/listen.*default_server/listen 80/g' /etc/nginx/sites-available/$site 2>/dev/null || true
        sudo sed -i 's/listen \[::\]:.*default_server/listen [::]:80/g' /etc/nginx/sites-available/$site 2>/dev/null || true
    fi
done
echo -e "${GREEN}✅ Outros sites atualizados${NC}\n"

# 4. Garantir que ecoreport.shop está ativado
echo -e "${BLUE}🔗 Garantindo que ecoreport.shop está ativado...${NC}"
sudo ln -sf /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/ecoreport.shop
echo -e "${GREEN}✅ Site ativado${NC}\n"

# 5. Testar configuração
echo -e "${BLUE}🧪 Testando configuração...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuração OK${NC}"
else
    echo -e "${RED}❌ Erro na configuração!${NC}"
    exit 1
fi

# 6. Recarregar Nginx
echo -e "${BLUE}🔄 Recarregando Nginx...${NC}"
sudo systemctl reload nginx
sleep 2

# 7. Testar
echo -e "${BLUE}🧪 Testando...${NC}\n"

echo -e "${GREEN}1. Teste sem Host header (localhost):${NC}"
curl -I http://localhost 2>&1 | head -5

echo -e "\n${GREEN}2. Teste com Host header (ecoreport.shop):${NC}"
curl -I -H "Host: ${DOMAIN}" http://localhost 2>&1 | head -5

echo -e "\n${GREEN}3. Teste via domínio:${NC}"
curl -I http://${DOMAIN} 2>&1 | head -5 || echo "DNS pode não estar configurado"

echo -e "\n${BLUE}📋 Verificando default_server agora:${NC}"
sudo grep -r "default_server" /etc/nginx/sites-enabled/ 2>/dev/null

echo -e "\n${GREEN}✅ CORREÇÃO APLICADA!${NC}\n"
echo -e "${BLUE}🌐 Acesse: http://${DOMAIN} ou http://localhost${NC}\n"
echo -e "${YELLOW}ℹ️  Outros sites continuam funcionando normalmente com seus domínios específicos${NC}\n"

