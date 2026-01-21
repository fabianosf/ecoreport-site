#!/bin/bash

# Script para corrigir erro 403 Forbidden em HTTPS
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

echo -e "${BLUE}🔧 Corrigindo erro 403 Forbidden em HTTPS...${NC}\n"

# 1. Verificar se aplicação está rodando
echo -e "${BLUE}1. Verificando aplicação...${NC}"
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
    echo -e "${YELLOW}   Verifique: pm2 logs ecoreport-site${NC}"
fi
echo ""

# 2. Verificar se certificado SSL existe
echo -e "${BLUE}2. Verificando certificado SSL...${NC}"
if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    echo -e "${GREEN}   ✅ Certificado SSL encontrado${NC}"
else
    echo -e "${YELLOW}   ⚠️  Certificado SSL não encontrado${NC}"
    echo -e "${YELLOW}   Você precisa configurar SSL primeiro:${NC}"
    echo -e "${YELLOW}   sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}${NC}"
    echo ""
    echo -e "${BLUE}   Por enquanto, configurando apenas HTTP...${NC}"
fi
echo ""

# 3. Configurar Nginx com HTTP e HTTPS (se certificado existir)
echo -e "${BLUE}3. Configurando Nginx...${NC}"

if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    # Configuração com HTTPS
    sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
# HTTP - Redirecionar para HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN} ${IP};

    # Redirecionar para HTTPS
    return 301 https://\$host\$request_uri;
}

# HTTPS - Site principal
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${DOMAIN} www.${DOMAIN};

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

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
    echo -e "${GREEN}   ✅ Configuração com HTTPS criada${NC}"
else
    # Configuração apenas HTTP
    sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN} ${IP};

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
    echo -e "${GREEN}   ✅ Configuração HTTP criada${NC}"
fi

# Garantir que está ativado
sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/${DOMAIN}

echo ""

# 4. Testar configuração
echo -e "${BLUE}4. Testando configuração...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}   ✅ Configuração válida${NC}"
else
    echo -e "${RED}   ❌ Erro na configuração!${NC}"
    sudo nginx -t
    exit 1
fi
echo ""

# 5. Recarregar Nginx
echo -e "${BLUE}5. Recarregando Nginx...${NC}"
sudo systemctl reload nginx
sleep 3
echo -e "${GREEN}   ✅ Nginx recarregado${NC}"
echo ""

# 6. Testes
echo -e "${BLUE}6. Testando acesso...${NC}\n"

echo -e "${GREEN}Teste 1: HTTP via IP${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${IP} 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${IP} - Status: ${HTTP_CODE}"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "   ✅ http://${IP} - Status: ${HTTP_CODE} (redirect para HTTPS - OK)"
else
    echo -e "   ⚠️  http://${IP} - Status: ${HTTP_CODE}"
fi

echo -e "\n${GREEN}Teste 2: HTTPS via domínio${NC}"
if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 https://${DOMAIN} 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "   ✅ https://${DOMAIN} - Status: ${HTTP_CODE}"
    elif [ "$HTTP_CODE" = "403" ]; then
        echo -e "   ⚠️  https://${DOMAIN} - Status: ${HTTP_CODE} (Forbidden)"
        echo -e "   ${YELLOW}   Verificando logs...${NC}"
        sudo tail -5 /var/log/nginx/ecoreport-error.log
    else
        echo -e "   ⚠️  https://${DOMAIN} - Status: ${HTTP_CODE}"
    fi
else
    echo -e "   ${YELLOW}   Certificado SSL não configurado${NC}"
fi

echo -e "\n${GREEN}Teste 3: HTTP via domínio${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://${DOMAIN} 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${DOMAIN} - Status: ${HTTP_CODE}"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "   ✅ http://${DOMAIN} - Status: ${HTTP_CODE} (redirect para HTTPS - OK)"
else
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
fi

# 7. Verificar logs se ainda houver 403
if [ "$HTTP_CODE" = "403" ]; then
    echo -e "\n${YELLOW}📋 Verificando logs de erro...${NC}"
    sudo tail -10 /var/log/nginx/ecoreport-error.log
    echo ""
    echo -e "${YELLOW}💡 Possíveis causas do 403:${NC}"
    echo -e "   1. Aplicação não está rodando em localhost:3000"
    echo -e "   2. Problema de permissões"
    echo -e "   3. Configuração do proxy incorreta"
    echo ""
    echo -e "${BLUE}🔍 Verifique:${NC}"
    echo -e "   pm2 status"
    echo -e "   curl http://localhost:3000"
    echo -e "   sudo tail -f /var/log/nginx/ecoreport-error.log"
fi

# 8. Resumo
echo -e "\n${GREEN}✅ Correção aplicada!${NC}\n"
echo -e "${BLUE}📋 Status:${NC}"
echo -e "   - Aplicação: $(pm2 list | grep ecoreport-site | awk '{print $10}' || echo 'N/A')"
echo -e "   - HTTP: Configurado"
if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    echo -e "   - HTTPS: Configurado com certificado SSL"
else
    echo -e "   - HTTPS: ${YELLOW}Certificado SSL não encontrado${NC}"
    echo -e "   ${YELLOW}   Configure: sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}${NC}"
fi
echo ""
