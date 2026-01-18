#!/bin/bash

# Script para Corrigir ecoreport.shop SEM Remover Outros Sites
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 CORRIGINDO ECOREPORT.SHOP (Mantendo outros sites)${NC}\n"

DOMAIN="ecoreport.shop"

# 1. Verificar se aplicação está rodando
echo -e "${BLUE}🔍 Verificando aplicação...${NC}"
if pm2 list | grep -q "ecoreport-site.*online"; then
    echo -e "${GREEN}✅ PM2 está rodando${NC}"
else
    echo -e "${RED}❌ PM2 não está rodando! Inicie primeiro:${NC}"
    echo -e "   cd /var/www/ecoreport-site && pm2 start npm --name ecoreport-site -- start"
    exit 1
fi

# 2. Verificar porta 3000
if netstat -tlnp 2>/dev/null | grep -q ":3000" || ss -tlnp 2>/dev/null | grep -q ":3000"; then
    echo -e "${GREEN}✅ Porta 3000 está ativa${NC}"
else
    echo -e "${RED}❌ Porta 3000 não está ativa!${NC}"
    exit 1
fi

# 3. Testar localmente
echo -e "${BLUE}🧪 Testando localhost:3000...${NC}"
if curl -s http://localhost:3000 | grep -q "EcoReport"; then
    echo -e "${GREEN}✅ Aplicação responde em localhost:3000${NC}\n"
else
    echo -e "${YELLOW}⚠️  Aplicação não respondeu como esperado${NC}\n"
fi

# 4. Atualizar configuração do ecoreport.shop (SEM remover outros sites)
echo -e "${BLUE}🌐 Atualizando configuração do Nginx para ecoreport.shop...${NC}"
sudo tee /etc/nginx/sites-available/ecoreport.shop > /dev/null << NGINXEOF
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

# 5. Garantir que site está ativado (sem remover outros)
echo -e "${BLUE}🔗 Garantindo que ecoreport.shop está ativado...${NC}"
sudo ln -sf /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/ecoreport.shop

# 6. Verificar configuração
echo -e "${BLUE}🧪 Testando configuração Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuração OK${NC}"
else
    echo -e "${RED}❌ Erro na configuração!${NC}"
    exit 1
fi

# 7. Recarregar Nginx
echo -e "${BLUE}🔄 Recarregando Nginx...${NC}"
sudo systemctl reload nginx
sleep 2

# 8. Testar
echo -e "${BLUE}🧪 Testando...${NC}\n"

echo -e "${GREEN}1. Teste via Host header (simulando ecoreport.shop):${NC}"
curl -I -H "Host: ${DOMAIN}" http://localhost 2>&1 | head -5

echo -e "\n${GREEN}2. Teste via IP direto (deve funcionar se DNS estiver OK):${NC}"
curl -I http://${DOMAIN} 2>&1 | head -5 || echo "DNS pode não estar configurado ainda"

echo -e "\n${GREEN}3. Verificar se site está ativado:${NC}"
if sudo ls -la /etc/nginx/sites-enabled/ | grep -q "ecoreport.shop"; then
    echo -e "${GREEN}✅ ecoreport.shop está ativado${NC}"
else
    echo -e "${RED}❌ ecoreport.shop NÃO está ativado!${NC}"
fi

echo -e "\n${BLUE}📋 Sites ativos (mantidos intactos):${NC}"
sudo ls -la /etc/nginx/sites-enabled/

echo -e "\n${GREEN}✅ CONFIGURAÇÃO APLICADA!${NC}\n"
echo -e "${BLUE}🌐 Acesse: http://${DOMAIN}${NC}\n"
echo -e "${YELLOW}⚠️  NOTA: Outros sites permanecem ativos e funcionando${NC}\n"

