#!/bin/bash

# Script para Corrigir Nginx - EcoReport Site
# Execute este script NO SERVIDOR (92.113.33.16)

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Corrigindo configuração do Nginx...${NC}\n"

# Variáveis
DOMAIN="ecoreport.shop"
APP_DIR="/var/www/ecoreport-site"

# 1. Verificar se Next.js está rodando
echo -e "${BLUE}📊 Verificando se Next.js está rodando...${NC}"
if pm2 list | grep -q "ecoreport-site"; then
    echo -e "${GREEN}✅ Aplicação Next.js está rodando (PM2)${NC}"
else
    echo -e "${YELLOW}⚠️  Aplicação Next.js NÃO está rodando!${NC}"
    echo -e "${BLUE}📦 Iniciando aplicação...${NC}"
    cd ${APP_DIR}
    pm2 start npm --name ecoreport-site -- start || pm2 restart ecoreport-site
    pm2 save
fi

# 2. Verificar se porta 3000 está aberta
echo -e "\n${BLUE}🔍 Verificando porta 3000...${NC}"
if netstat -tlnp | grep -q ":3000"; then
    echo -e "${GREEN}✅ Porta 3000 está ativa${NC}"
else
    echo -e "${RED}❌ Porta 3000 NÃO está ativa! Reiniciando aplicação...${NC}"
    cd ${APP_DIR}
    pm2 restart ecoreport-site
    sleep 3
fi

# 3. Criar configuração Nginx correta
echo -e "\n${BLUE}🌐 Configurando Nginx...${NC}"

sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    # Proxy para Next.js
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

# 4. Ativar site
echo -e "${BLUE}🔗 Ativando site...${NC}"
sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# 5. Testar configuração
echo -e "${BLUE}🧪 Testando configuração do Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuração do Nginx está correta${NC}"
else
    echo -e "${RED}❌ Erro na configuração do Nginx!${NC}"
    exit 1
fi

# 6. Recarregar Nginx
echo -e "${BLUE}🔄 Recarregando Nginx...${NC}"
sudo systemctl reload nginx || sudo systemctl restart nginx

# 7. Verificar status
echo -e "\n${BLUE}📊 Verificando status...${NC}"
echo -e "${GREEN}✅ Status do Nginx:${NC}"
sudo systemctl status nginx --no-pager -l | head -5

echo -e "\n${GREEN}✅ Status do PM2:${NC}"
pm2 status

echo -e "\n${GREEN}✅ Status da porta 3000:${NC}"
netstat -tlnp | grep :3000 || echo "Porta 3000 não está ativa!"

# 8. Testar conexão
echo -e "\n${BLUE}🧪 Testando conexão local...${NC}"
if curl -s http://localhost:3000 | grep -q "EcoReport"; then
    echo -e "${GREEN}✅ Site está acessível em http://localhost:3000${NC}"
else
    echo -e "${YELLOW}⚠️  Site não respondeu como esperado em localhost:3000${NC}"
fi

# 9. Instruções finais
echo -e "\n${GREEN}🎉 Configuração concluída!${NC}\n"
echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}\n"

echo -e "${YELLOW}1. Verificar se o site está acessível:${NC}"
echo -e "   curl -I http://${DOMAIN}\n"

echo -e "${YELLOW}2. Se ainda não funcionar, verificar:${NC}"
echo -e "   - DNS está apontando para o servidor? (nslookup ${DOMAIN})"
echo -e "   - Firewall permite porta 80? (sudo ufw status)"
echo -e "   - PM2 está rodando? (pm2 status)\n"

echo -e "${YELLOW}3. Ver logs se houver problemas:${NC}"
echo -e "   pm2 logs ecoreport-site"
echo -e "   sudo tail -f /var/log/nginx/error.log\n"

echo -e "${GREEN}🌐 Acesse: http://${DOMAIN}${NC}"

