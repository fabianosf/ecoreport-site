#!/bin/bash

# Script para Corrigir 404 do Nginx
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 CORRIGINDO 404 DO NGINX...${NC}\n"

DOMAIN="ecoreport.shop"

# 1. Verificar sites ativos
echo -e "${BLUE}📋 Sites ativos no Nginx:${NC}"
sudo ls -la /etc/nginx/sites-enabled/
echo ""

# 2. Verificar configuração atual
echo -e "${BLUE}📋 Configuração atual do ecoreport.shop:${NC}"
sudo cat /etc/nginx/sites-available/ecoreport.shop 2>/dev/null || echo "Arquivo não existe"
echo ""

# 3. Remover outras configurações conflitantes (desabilitar outros sites)
echo -e "${BLUE}🔧 Desabilitando outros sites...${NC}"
for site in /etc/nginx/sites-enabled/*; do
    if [[ "$site" != *"ecoreport.shop"* ]] && [[ "$site" != *"default"* ]]; then
        echo -e "${YELLOW}Desabilitando: $(basename $site)${NC}"
        sudo rm -f "$site"
    fi
done

# 4. Remover default
sudo rm -f /etc/nginx/sites-enabled/default

# 5. Recriar configuração ecoreport.shop com prioridade
echo -e "${BLUE}🌐 Recriando configuração do Nginx...${NC}"
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
}
NGINXEOF

# 6. Ativar site
echo -e "${BLUE}🔗 Ativando site...${NC}"
sudo ln -sf /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/

# 7. Testar configuração
echo -e "${BLUE}🧪 Testando configuração...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuração OK${NC}"
else
    echo -e "${RED}❌ Erro na configuração!${NC}"
    exit 1
fi

# 8. Recarregar Nginx
echo -e "${BLUE}🔄 Recarregando Nginx...${NC}"
sudo systemctl reload nginx
sleep 2

# 9. Testar
echo -e "${BLUE}🧪 Testando...${NC}\n"
echo -e "${GREEN}Teste via localhost:${NC}"
curl -I http://localhost 2>&1 | head -5

echo -e "\n${GREEN}Teste via IP do servidor:${NC}"
curl -I http://127.0.0.1 2>&1 | head -5

echo -e "\n${GREEN}Teste via domínio:${NC}"
curl -I http://${DOMAIN} 2>&1 | head -5 || echo "DNS pode não estar configurado"

echo -e "\n${BLUE}📋 Sites ativos agora:${NC}"
sudo ls -la /etc/nginx/sites-enabled/

echo -e "\n${GREEN}✅ CORREÇÃO APLICADA!${NC}\n"
echo -e "${BLUE}🌐 Acesse: http://${DOMAIN} ou http://localhost${NC}\n"

