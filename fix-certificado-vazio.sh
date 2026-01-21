#!/bin/bash

# Script para corrigir certificado SSL com caminho vazio
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="ecoreport.shop"

echo -e "${BLUE}🔧 Corrigindo certificado SSL com caminho vazio...${NC}\n"

# 1. Procurar arquivos com certificado vazio
echo -e "${BLUE}1. Procurando arquivos com certificado SSL vazio...${NC}"
FOUND_FILES=()

for site_file in /etc/nginx/sites-available/* /etc/nginx/sites-enabled/*; do
    if [ -f "$site_file" ] && [[ "$site_file" != *"backup"* ]]; then
        # Verificar se tem ssl_certificate com caminho vazio ou //
        if sudo grep -q "ssl_certificate.*live//" "$site_file" 2>/dev/null || \
           sudo grep -q "ssl_certificate.*live/\$" "$site_file" 2>/dev/null || \
           sudo grep -q "ssl_certificate.*live/;" "$site_file" 2>/dev/null; then
            FOUND_FILES+=("$site_file")
            echo -e "${YELLOW}   ⚠️  Encontrado em: $(basename $site_file)${NC}"
            sudo grep "ssl_certificate" "$site_file" | grep -E "live//|live/\$|live/;" || true
        fi
    fi
done

if [ ${#FOUND_FILES[@]} -eq 0 ]; then
    echo -e "${GREEN}   ✅ Nenhum arquivo com certificado vazio encontrado${NC}"
else
    echo -e "${YELLOW}   ${#FOUND_FILES[@]} arquivo(s) com problema encontrado(s)${NC}"
fi
echo ""

# 2. Verificar arquivo 'ecoreport' especificamente
echo -e "${BLUE}2. Verificando arquivo 'ecoreport'...${NC}"
if [ -f "/etc/nginx/sites-available/ecoreport" ]; then
    ECOREPORT_FILE="/etc/nginx/sites-available/ecoreport"
elif [ -f "/etc/nginx/sites-enabled/ecoreport" ]; then
    ECOREPORT_FILE="/etc/nginx/sites-enabled/ecoreport"
else
    ECOREPORT_FILE=""
fi

if [ -n "$ECOREPORT_FILE" ]; then
    # Verificar se tem certificado vazio
    if sudo grep -q "ssl_certificate.*live//" "$ECOREPORT_FILE" 2>/dev/null; then
        echo -e "${YELLOW}   ⚠️  Arquivo 'ecoreport' tem certificado vazio${NC}"
        echo -e "${BLUE}   Corrigindo...${NC}"
        
        # Fazer backup
        sudo cp "$ECOREPORT_FILE" "${ECOREPORT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Remover linhas com certificado vazio (comentá-las)
        sudo sed -i 's|ssl_certificate /etc/letsencrypt/live//fullchain.pem|# ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' "$ECOREPORT_FILE"
        sudo sed -i 's|ssl_certificate_key /etc/letsencrypt/live//privkey.pem|# ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' "$ECOREPORT_FILE"
        
        echo -e "${GREEN}   ✅ Certificado vazio removido/comentado${NC}"
    else
        echo -e "${GREEN}   ✅ Arquivo 'ecoreport' OK${NC}"
    fi
else
    echo -e "${GREEN}   ✅ Arquivo 'ecoreport' não encontrado${NC}"
fi
echo ""

# 3. Procurar e corrigir em todos os arquivos
echo -e "${BLUE}3. Corrigindo todos os arquivos com certificado vazio...${NC}"
for site_file in "${FOUND_FILES[@]}"; do
    if [ -f "$site_file" ]; then
        site_name=$(basename "$site_file")
        echo -e "${YELLOW}   Corrigindo: $site_name${NC}"
        
        # Fazer backup
        sudo cp "$site_file" "${site_file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Comentar linhas com certificado vazio
        sudo sed -i 's|ssl_certificate /etc/letsencrypt/live//fullchain.pem|# ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' "$site_file"
        sudo sed -i 's|ssl_certificate_key /etc/letsencrypt/live//privkey.pem|# ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' "$site_file"
        
        # Também corrigir se tiver apenas /live/ sem domínio
        sudo sed -i 's|ssl_certificate /etc/letsencrypt/live/;|# ssl_certificate /etc/letsencrypt/live/;|g' "$site_file"
        sudo sed -i 's|ssl_certificate_key /etc/letsencrypt/live/;|# ssl_certificate_key /etc/letsencrypt/live/;|g' "$site_file"
        
        echo -e "${GREEN}   ✅ $site_name corrigido${NC}"
    fi
done
echo ""

# 4. Garantir que ecoreport.shop está configurado corretamente
echo -e "${BLUE}4. Garantindo que ${DOMAIN} está configurado corretamente...${NC}"

# Verificar se certificado existe
if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
# HTTP - Redirecionar para HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN} 92.113.33.16;

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
    echo -e "${YELLOW}   ⚠️  Certificado SSL não encontrado para ${DOMAIN}${NC}"
    echo -e "${YELLOW}   Configurando apenas HTTP...${NC}"
    
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

# 5. Testar configuração
echo -e "${BLUE}5. Testando configuração do Nginx...${NC}"
if sudo nginx -t 2>&1 | grep -q "cannot load certificate.*live//"; then
    echo -e "${RED}   ❌ Ainda há certificado vazio!${NC}"
    echo -e "${YELLOW}   Procurando em todos os arquivos...${NC}"
    sudo grep -r "ssl_certificate.*live//" /etc/nginx/sites-available/ /etc/nginx/sites-enabled/ 2>/dev/null | grep -v backup
    echo ""
    echo -e "${YELLOW}   Comentando manualmente...${NC}"
    # Comentar todas as ocorrências
    sudo find /etc/nginx/sites-available /etc/nginx/sites-enabled -type f -exec sed -i 's|ssl_certificate /etc/letsencrypt/live//fullchain.pem|# ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' {} \;
    sudo find /etc/nginx/sites-available /etc/nginx/sites-enabled -type f -exec sed -i 's|ssl_certificate_key /etc/letsencrypt/live//privkey.pem|# ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' {} \;
    echo -e "${GREEN}   ✅ Certificados vazios comentados${NC}"
fi

if sudo nginx -t; then
    echo -e "${GREEN}   ✅ Configuração válida${NC}"
else
    echo -e "${RED}   ❌ Erro na configuração!${NC}"
    sudo nginx -t
    exit 1
fi
echo ""

# 6. Recarregar Nginx
echo -e "${BLUE}6. Recarregando Nginx...${NC}"
sudo systemctl reload nginx
sleep 3
echo -e "${GREEN}   ✅ Nginx recarregado${NC}"
echo ""

# 7. Testes
echo -e "${BLUE}7. Testando acesso...${NC}\n"

echo -e "${GREEN}Teste 1: HTTPS via domínio${NC}"
if [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 https://${DOMAIN} 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "   ✅ https://${DOMAIN} - Status: ${HTTP_CODE}"
    elif [ "$HTTP_CODE" = "403" ]; then
        echo -e "   ⚠️  https://${DOMAIN} - Status: ${HTTP_CODE} (Forbidden)"
    else
        echo -e "   ⚠️  https://${DOMAIN} - Status: ${HTTP_CODE}"
    fi
else
    echo -e "   ${YELLOW}   Certificado SSL não configurado${NC}"
fi

echo -e "\n${GREEN}Teste 2: HTTP via domínio${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://${DOMAIN} 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${DOMAIN} - Status: ${HTTP_CODE}"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "   ✅ http://${DOMAIN} - Status: ${HTTP_CODE} (redirect para HTTPS - OK)"
else
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
fi

# 8. Resumo
echo -e "\n${GREEN}✅ Correção concluída!${NC}\n"
echo -e "${BLUE}📋 O que foi feito:${NC}"
echo -e "   - Certificados SSL vazios comentados/removidos"
echo -e "   - Configuração do ${DOMAIN} atualizada"
echo -e "   - Nginx recarregado\n"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "${GREEN}🎉 Site funcionando!${NC}"
else
    echo -e "${YELLOW}⚠️  Se ainda houver problemas, verifique os logs:${NC}"
    echo -e "   sudo tail -f /var/log/nginx/ecoreport-error.log"
fi
