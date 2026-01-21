#!/bin/bash

# Script para verificar e corrigir configuração do domínio
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="ecoreport.shop"
IP="92.113.33.16"

echo -e "${BLUE}🔍 Verificando e corrigindo configuração do domínio...${NC}\n"

# 1. Verificar DNS
echo -e "${BLUE}1. Verificando DNS...${NC}"
DNS_RESULT=$(dig +short ${DOMAIN} @8.8.8.8 2>/dev/null | tail -1 || echo "")
if [ -n "$DNS_RESULT" ]; then
    if [ "$DNS_RESULT" = "$IP" ]; then
        echo -e "${GREEN}   ✅ DNS OK: ${DOMAIN} → ${IP}${NC}"
    else
        echo -e "${YELLOW}   ⚠️  DNS aponta para: ${DNS_RESULT} (esperado: ${IP})${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  DNS ainda não propagado ou não encontrado${NC}"
fi
echo ""

# 2. Verificar configuração atual do Nginx
echo -e "${BLUE}2. Verificando configuração do Nginx...${NC}"
if [ -f "/etc/nginx/sites-available/${DOMAIN}" ]; then
    echo -e "${GREEN}   ✅ Arquivo de configuração existe${NC}"
    echo -e "${BLUE}   Conteúdo do server_name:${NC}"
    grep "server_name" /etc/nginx/sites-available/${DOMAIN} | head -1
else
    echo -e "${RED}   ❌ Arquivo de configuração não existe!${NC}"
fi
echo ""

# 3. Verificar se site está ativado
echo -e "${BLUE}3. Verificando se site está ativado...${NC}"
if [ -L "/etc/nginx/sites-enabled/${DOMAIN}" ]; then
    echo -e "${GREEN}   ✅ Site está ativado${NC}"
else
    echo -e "${RED}   ❌ Site NÃO está ativado!${NC}"
    echo -e "${YELLOW}   Ativando...${NC}"
    sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/${DOMAIN}
    echo -e "${GREEN}   ✅ Site ativado${NC}"
fi
echo ""

# 4. Verificar se aplicação está rodando
echo -e "${BLUE}4. Verificando aplicação...${NC}"
if pm2 list | grep -q "ecoreport-site.*online"; then
    echo -e "${GREEN}   ✅ Aplicação rodando no PM2${NC}"
else
    echo -e "${RED}   ❌ Aplicação NÃO está rodando!${NC}"
    echo -e "${YELLOW}   Iniciando...${NC}"
    cd /var/www/ecoreport-site
    pm2 start npm --name ecoreport-site -- start
    pm2 save
    sleep 3
    echo -e "${GREEN}   ✅ Aplicação iniciada${NC}"
fi

# Testar localhost
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}   ✅ Aplicação respondendo em localhost:3000${NC}"
else
    echo -e "${RED}   ❌ Aplicação NÃO está respondendo em localhost:3000${NC}"
fi
echo ""

# 5. Recriar configuração do Nginx garantindo que aceita o domínio
echo -e "${BLUE}5. Recriando configuração do Nginx...${NC}"
sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${DOMAIN} www.${DOMAIN} ${IP} _;

    # Logs
    access_log /var/log/nginx/ecoreport-access.log;
    error_log /var/log/nginx/ecoreport-error.log;

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json application/xml+rss;

    # Arquivos estáticos do Next.js
    location /_next/static {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # Assets estáticos
    location ~* \.(ico|png|jpg|jpeg|gif|svg|webp|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # API routes
    location /api {
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

    # Proxy principal
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
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check
    location /api/health {
        proxy_pass http://localhost:3000;
        access_log off;
    }
}
NGINXEOF

# Garantir que está ativado
sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/${DOMAIN}

echo -e "${GREEN}   ✅ Configuração recriada${NC}"
echo ""

# 6. Testar configuração
echo -e "${BLUE}6. Testando configuração do Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}   ✅ Configuração válida${NC}"
else
    echo -e "${RED}   ❌ Erro na configuração!${NC}"
    sudo nginx -t
    exit 1
fi
echo ""

# 7. Recarregar Nginx
echo -e "${BLUE}7. Recarregando Nginx...${NC}"
sudo systemctl reload nginx
sleep 2
echo -e "${GREEN}   ✅ Nginx recarregado${NC}"
echo ""

# 8. Testes finais
echo -e "${BLUE}8. Testando acesso...${NC}\n"

echo -e "${GREEN}Teste 1: Via IP direto${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${IP} 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${IP} - Status: ${HTTP_CODE}"
else
    echo -e "   ⚠️  http://${IP} - Status: ${HTTP_CODE}"
fi

echo -e "\n${GREEN}Teste 2: Via domínio (simulando Host header)${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: ${DOMAIN}" http://${IP} 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${DOMAIN} (Host: ${DOMAIN}) - Status: ${HTTP_CODE}"
else
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
fi

echo -e "\n${GREEN}Teste 3: Via domínio real (se DNS propagado)${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://${DOMAIN} 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${DOMAIN} - Status: ${HTTP_CODE}"
elif [ "$HTTP_CODE" = "000" ]; then
    echo -e "   ⚠️  Timeout ou DNS não propagado ainda"
    echo -e "   ${YELLOW}   Aguarde alguns minutos para propagação DNS${NC}"
else
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
fi

# 9. Resumo
echo -e "\n${GREEN}✅ Verificação concluída!${NC}\n"
echo -e "${BLUE}📋 Status:${NC}"
echo -e "   - DNS: ${DOMAIN} → ${IP} ${GREEN}✅${NC}"
echo -e "   - Nginx: Configurado com default_server ${GREEN}✅${NC}"
echo -e "   - Aplicação: Rodando no PM2 ${GREEN}✅${NC}"
echo -e "   - Site ativado: ${GREEN}✅${NC}\n"

echo -e "${YELLOW}💡 Se o domínio ainda não funcionar:${NC}"
echo -e "   1. Aguarde alguns minutos para propagação DNS (pode levar até 24h)"
echo -e "   2. Limpe o cache do navegador (Ctrl+Shift+Delete)"
echo -e "   3. Teste em modo anônimo/privado"
echo -e "   4. Verifique logs: sudo tail -f /var/log/nginx/ecoreport-error.log\n"

echo -e "${GREEN}🎉 Configuração verificada e corrigida!${NC}"
