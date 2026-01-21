#!/bin/bash

# Script para RECRIAR arquivo 'ecoreport' corretamente
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Recriando arquivo 'ecoreport' corretamente...${NC}\n"

# 1. Fazer backup
echo -e "${BLUE}1. Fazendo backup...${NC}"
if [ -f "/etc/nginx/sites-enabled/ecoreport" ]; then
    ECOREPORT_FILE="/etc/nginx/sites-enabled/ecoreport"
    sudo cp "$ECOREPORT_FILE" "${ECOREPORT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
elif [ -f "/etc/nginx/sites-available/ecoreport" ]; then
    ECOREPORT_FILE="/etc/nginx/sites-available/ecoreport"
    sudo cp "$ECOREPORT_FILE" "${ECOREPORT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
else
    ECOREPORT_FILE="/etc/nginx/sites-available/ecoreport"
fi
echo -e "${GREEN}   ✅ Backup criado${NC}"
echo ""

# 2. Verificar certificado
echo -e "${BLUE}2. Verificando certificado SSL...${NC}"
if [ -f "/etc/letsencrypt/live/app.ecoreport.shop/fullchain.pem" ]; then
    CERT_EXISTS=true
    echo -e "${GREEN}   ✅ Certificado encontrado${NC}"
else
    CERT_EXISTS=false
    echo -e "${YELLOW}   ⚠️  Certificado não encontrado${NC}"
fi
echo ""

# 3. Recriar arquivo ecoreport APENAS com app.ecoreport.shop
echo -e "${BLUE}3. Recriando arquivo 'ecoreport'...${NC}"

if [ "$CERT_EXISTS" = true ]; then
    # Com certificado SSL
    sudo tee "$ECOREPORT_FILE" > /dev/null << 'ECOREPORTEOF'
# Configuração Nginx para EcoReport - app.ecoreport.shop
# Apenas app.ecoreport.shop (sem ecoreport.shop para evitar conflito)

# Redirecionar HTTP para HTTPS
server {
    if ($host = app.ecoreport.shop) {
        return 301 https://$host$request_uri;
    } # managed by Certbot

    listen 80;
    listen [::]:80;
    server_name app.ecoreport.shop;
    
    # Redirecionar para HTTPS
    return 301 https://$host$request_uri;
}

# Aplicação - app.ecoreport.shop
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name app.ecoreport.shop;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/app.ecoreport.shop/fullchain.pem; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/app.ecoreport.shop/privkey.pem; # managed by Certbot
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Tamanho máximo de upload
    client_max_body_size 10M;

    # Logs
    access_log /var/log/nginx/ecoreport_app_access.log;
    error_log /var/log/nginx/ecoreport_app_error.log;

    # Frontend (React Build)
    location / {
        root /var/www/ecoreport.shop/app/frontend/dist;
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
        proxy_redirect off;
    }
    
    # Health check direto
    location /health/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
    
    # Admin Django
    location /admin/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    # Static files (Django)
    location /static/ {
        alias /var/www/ecoreport.shop/app/backend/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Media files (Django)
    location /media/ {
        alias /var/www/ecoreport.shop/app/backend/media/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
}
ECOREPORTEOF
else
    # Sem certificado SSL (apenas HTTP)
    sudo tee "$ECOREPORT_FILE" > /dev/null << 'ECOREPORTEOF'
# Configuração Nginx para EcoReport - app.ecoreport.shop
# Apenas app.ecoreport.shop (sem ecoreport.shop para evitar conflito)
# SSL não configurado ainda

server {
    listen 80;
    listen [::]:80;
    server_name app.ecoreport.shop;

    # Tamanho máximo de upload
    client_max_body_size 10M;

    # Logs
    access_log /var/log/nginx/ecoreport_app_access.log;
    error_log /var/log/nginx/ecoreport_app_error.log;

    # Frontend (React Build)
    location / {
        root /var/www/ecoreport.shop/app/frontend/dist;
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
        proxy_redirect off;
    }
    
    # Health check direto
    location /health/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }
    
    # Admin Django
    location /admin/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    # Static files (Django)
    location /static/ {
        alias /var/www/ecoreport.shop/app/backend/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Media files (Django)
    location /media/ {
        alias /var/www/ecoreport.shop/app/backend/media/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
}
ECOREPORTEOF
fi

# Garantir que está em sites-enabled
if [ "$ECOREPORT_FILE" = "/etc/nginx/sites-available/ecoreport" ]; then
    sudo ln -sf /etc/nginx/sites-available/ecoreport /etc/nginx/sites-enabled/ecoreport
fi

echo -e "${GREEN}   ✅ Arquivo 'ecoreport' recriado${NC}"
echo ""

# 4. Testar configuração
echo -e "${BLUE}4. Testando configuração do Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}   ✅ Configuração válida!${NC}"
else
    echo -e "${RED}   ❌ Erro na configuração!${NC}"
    sudo nginx -t
    exit 1
fi
echo ""

# 5. Recarregar Nginx
echo -e "${BLUE}5. Recarregando Nginx...${NC}"
sudo systemctl reload nginx
sleep 2
echo -e "${GREEN}   ✅ Nginx recarregado${NC}"
echo ""

# 6. Testes
echo -e "${BLUE}6. Testando acesso...${NC}\n"

echo -e "${GREEN}Teste 1: HTTPS ecoreport.shop${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 https://ecoreport.shop 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ https://ecoreport.shop - Status: ${HTTP_CODE}"
elif [ "$HTTP_CODE" = "403" ]; then
    echo -e "   ⚠️  https://ecoreport.shop - Status: ${HTTP_CODE} (Forbidden)"
else
    echo -e "   ⚠️  https://ecoreport.shop - Status: ${HTTP_CODE}"
fi

echo -e "\n${GREEN}Teste 2: HTTP ecoreport.shop${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://ecoreport.shop 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://ecoreport.shop - Status: ${HTTP_CODE}"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "   ✅ http://ecoreport.shop - Status: ${HTTP_CODE} (redirect para HTTPS - OK)"
else
    echo -e "   ⚠️  http://ecoreport.shop - Status: ${HTTP_CODE}"
fi

# 7. Resumo
echo -e "\n${GREEN}✅ Arquivo 'ecoreport' recriado com sucesso!${NC}\n"
echo -e "${BLUE}📋 O que foi feito:${NC}"
echo -e "   - Arquivo 'ecoreport' recriado do zero"
echo -e "   - Apenas app.ecoreport.shop configurado (sem conflito)"
echo -e "   - Estrutura correta mantida"
echo -e "   - Nginx testado e recarregado\n"

echo -e "${GREEN}🎉 Configuração corrigida!${NC}"
