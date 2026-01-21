#!/bin/bash

# Script para corrigir arquivo 'ecoreport' corretamente
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="ecoreport.shop"

echo -e "${BLUE}🔧 Corrigindo arquivo 'ecoreport' corretamente...${NC}\n"

# 1. Fazer backup
echo -e "${BLUE}1. Fazendo backup do arquivo 'ecoreport'...${NC}"
if [ -f "/etc/nginx/sites-available/ecoreport" ]; then
    sudo cp /etc/nginx/sites-available/ecoreport /etc/nginx/sites-available/ecoreport.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "${GREEN}   ✅ Backup criado${NC}"
elif [ -f "/etc/nginx/sites-enabled/ecoreport" ]; then
    sudo cp /etc/nginx/sites-enabled/ecoreport /etc/nginx/sites-enabled/ecoreport.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "${GREEN}   ✅ Backup criado${NC}"
fi
echo ""

# 2. Recriar arquivo 'ecoreport' SEM ecoreport.shop e www.ecoreport.shop
echo -e "${BLUE}2. Recriando arquivo 'ecoreport' (apenas app.ecoreport.shop)...${NC}"

# Determinar qual arquivo usar
if [ -f "/etc/nginx/sites-available/ecoreport" ]; then
    ECOREPORT_FILE="/etc/nginx/sites-available/ecoreport"
elif [ -f "/etc/nginx/sites-enabled/ecoreport" ]; then
    ECOREPORT_FILE="/etc/nginx/sites-enabled/ecoreport"
else
    echo -e "${RED}   ❌ Arquivo 'ecoreport' não encontrado!${NC}"
    exit 1
fi

sudo tee ${ECOREPORT_FILE} > /dev/null << 'ECOREPORTEOF'
# Configuração Nginx para EcoReport
# Colocar em: /etc/nginx/sites-available/ecoreport

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

echo -e "${GREEN}   ✅ Arquivo 'ecoreport' recriado (apenas app.ecoreport.shop)${NC}"
echo ""

# 3. Garantir que ecoreport.shop está configurado corretamente
echo -e "${BLUE}3. Garantindo que ${DOMAIN} está configurado corretamente...${NC}"
sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN} 92.113.33.16;

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

    # Proxy principal - SEM redirects
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

echo -e "${GREEN}   ✅ Configuração do ${DOMAIN} atualizada${NC}"
echo ""

# 4. Testar configuração
echo -e "${BLUE}4. Testando configuração do Nginx...${NC}"
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

# 6. Testes finais
echo -e "${BLUE}6. Testando acesso...${NC}\n"

echo -e "${GREEN}Teste 1: Via IP direto${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://92.113.33.16 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://92.113.33.16 - Status: ${HTTP_CODE}"
else
    echo -e "   ⚠️  http://92.113.33.16 - Status: ${HTTP_CODE}"
fi

echo -e "\n${GREEN}Teste 2: Via domínio (Host header)${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: ${DOMAIN}" http://92.113.33.16 2>/dev/null || echo "000")
LOCATION=$(curl -s -I -H "Host: ${DOMAIN}" http://92.113.33.16 2>/dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r' || echo "")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${DOMAIN} (Host: ${DOMAIN}) - Status: ${HTTP_CODE}"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
    if [ -n "$LOCATION" ]; then
        echo -e "   ${YELLOW}   Redirect para: ${LOCATION}${NC}"
    fi
else
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
fi

echo -e "\n${GREEN}Teste 3: Via domínio real${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://${DOMAIN} 2>/dev/null || echo "000")
LOCATION=$(curl -s -I --connect-timeout 5 http://${DOMAIN} 2>/dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r' || echo "")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${DOMAIN} - Status: ${HTTP_CODE}"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
    if [ -n "$LOCATION" ]; then
        echo -e "   ${YELLOW}   Redirect para: ${LOCATION}${NC}"
    fi
elif [ "$HTTP_CODE" = "000" ]; then
    echo -e "   ⚠️  Timeout ou DNS não propagado"
else
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
fi

# 7. Resumo
echo -e "\n${GREEN}✅ Correção concluída!${NC}\n"
echo -e "${BLUE}📋 O que foi feito:${NC}"
echo -e "   - Arquivo 'ecoreport' corrigido (apenas app.ecoreport.shop)"
echo -e "   - Removido 'ecoreport.shop' e 'www.ecoreport.shop' do arquivo 'ecoreport'"
echo -e "   - Configurado ${DOMAIN} separadamente (sem redirects)"
echo -e "   - Backup criado do arquivo original\n"

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}🎉 Domínio ${DOMAIN} funcionando corretamente!${NC}"
else
    echo -e "${YELLOW}⚠️  Se ainda houver redirect, limpe o cache do navegador.${NC}"
fi
