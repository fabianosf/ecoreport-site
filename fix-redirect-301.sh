#!/bin/bash

# Script para corrigir redirect 301 no domínio
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

echo -e "${BLUE}🔧 Corrigindo redirect 301...${NC}\n"

# 1. Verificar todos os sites ativos
echo -e "${BLUE}1. Verificando sites ativos no Nginx...${NC}"
echo -e "${YELLOW}Sites encontrados:${NC}"
ls -la /etc/nginx/sites-enabled/ | grep -v "^total" | grep -v "^d" | awk '{print "   - " $9}'
echo ""

# 2. Verificar se há redirects em outros sites
echo -e "${BLUE}2. Verificando redirects em outros sites...${NC}"
for site_file in /etc/nginx/sites-enabled/*; do
    if [ -f "$site_file" ]; then
        site_name=$(basename "$site_file")
        if [[ "$site_name" != *"${DOMAIN}"* ]]; then
            # Verificar se tem redirect para HTTPS ou outro domínio
            if grep -q "return 301" "$site_file" 2>/dev/null; then
                echo -e "${YELLOW}   ⚠️  $site_name tem redirect:${NC}"
                grep "return 301" "$site_file" | head -1 | sed 's/^/      /'
            fi
            # Verificar se tem default_server
            if grep -q "default_server" "$site_file" 2>/dev/null; then
                echo -e "${YELLOW}   ⚠️  $site_name tem default_server (pode causar conflito)${NC}"
            fi
        fi
    fi
done
echo ""

# 3. Remover default_server de outros sites
echo -e "${BLUE}3. Removendo default_server de outros sites...${NC}"
for site_file in /etc/nginx/sites-enabled/*; do
    if [ -f "$site_file" ] && [[ "$site_file" != *"${DOMAIN}"* ]]; then
        site_name=$(basename "$site_file")
        echo -e "${YELLOW}   Processando: $site_name${NC}"
        # Remover default_server
        sudo sed -i 's/ listen 80 default_server;/ listen 80;/g' "$site_file" 2>/dev/null || true
        sudo sed -i 's/ listen \[::\]:80 default_server;/ listen [::]:80;/g' "$site_file" 2>/dev/null || true
        sudo sed -i 's/ listen 80 default_server;/ listen 80;/g' "$site_file" 2>/dev/null || true
        sudo sed -i 's/ listen \[::\]:80 default_server;/ listen [::]:80;/g' "$site_file" 2>/dev/null || true
    fi
done
echo -e "${GREEN}   ✅ default_server removido de outros sites${NC}"
echo ""

# 4. Recriar configuração do ecoreport.shop SEM redirects
echo -e "${BLUE}4. Recriando configuração do ${DOMAIN} (sem redirects)...${NC}"
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

echo -e "${GREEN}   ✅ Configuração recriada sem redirects${NC}"
echo ""

# 5. Verificar se há configuração na nginx.conf principal que pode estar causando redirect
echo -e "${BLUE}5. Verificando nginx.conf principal...${NC}"
if sudo grep -q "return 301" /etc/nginx/nginx.conf 2>/dev/null; then
    echo -e "${YELLOW}   ⚠️  Encontrado redirect no nginx.conf principal${NC}"
    sudo grep "return 301" /etc/nginx/nginx.conf
else
    echo -e "${GREEN}   ✅ Nenhum redirect no nginx.conf principal${NC}"
fi
echo ""

# 6. Testar configuração
echo -e "${BLUE}6. Testando configuração...${NC}"
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
sleep 3
echo -e "${GREEN}   ✅ Nginx recarregado${NC}"
echo ""

# 8. Testes finais
echo -e "${BLUE}8. Testando acesso (verificando se ainda há redirect)...${NC}\n"

echo -e "${GREEN}Teste 1: Via IP direto${NC}"
RESPONSE=$(curl -s -I http://${IP} 2>/dev/null | head -1)
HTTP_CODE=$(echo "$RESPONSE" | grep -oP '\d{3}' | head -1)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${IP} - Status: ${HTTP_CODE}"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "   ⚠️  http://${IP} - Status: ${HTTP_CODE} (ainda há redirect)"
    echo -e "   ${YELLOW}   Location: $(curl -s -I http://${IP} 2>/dev/null | grep -i location | cut -d' ' -f2 | tr -d '\r')${NC}"
else
    echo -e "   ⚠️  http://${IP} - Status: ${HTTP_CODE}"
fi

echo -e "\n${GREEN}Teste 2: Via domínio (Host header)${NC}"
RESPONSE=$(curl -s -I -H "Host: ${DOMAIN}" http://${IP} 2>/dev/null | head -1)
HTTP_CODE=$(echo "$RESPONSE" | grep -oP '\d{3}' | head -1)
LOCATION=$(curl -s -I -H "Host: ${DOMAIN}" http://${IP} 2>/dev/null | grep -i location | cut -d' ' -f2 | tr -d '\r' || echo "")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${DOMAIN} (Host: ${DOMAIN}) - Status: ${HTTP_CODE}"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE} (ainda há redirect)"
    if [ -n "$LOCATION" ]; then
        echo -e "   ${YELLOW}   Redirect para: ${LOCATION}${NC}"
    fi
else
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
fi

echo -e "\n${GREEN}Teste 3: Via domínio real${NC}"
RESPONSE=$(curl -s -I --connect-timeout 5 http://${DOMAIN} 2>/dev/null | head -1)
HTTP_CODE=$(echo "$RESPONSE" | grep -oP '\d{3}' | head -1 || echo "000")
LOCATION=$(curl -s -I --connect-timeout 5 http://${DOMAIN} 2>/dev/null | grep -i location | cut -d' ' -f2 | tr -d '\r' || echo "")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${DOMAIN} - Status: ${HTTP_CODE}"
elif [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE} (ainda há redirect)"
    if [ -n "$LOCATION" ]; then
        echo -e "   ${YELLOW}   Redirect para: ${LOCATION}${NC}"
        echo -e "   ${YELLOW}   Isso pode ser normal se houver redirect para HTTPS configurado${NC}"
    fi
elif [ "$HTTP_CODE" = "000" ]; then
    echo -e "   ⚠️  Timeout ou DNS não propagado"
else
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
fi

# 9. Verificar logs para ver o que está acontecendo
echo -e "\n${BLUE}9. Verificando logs recentes...${NC}"
echo -e "${YELLOW}Últimas 5 linhas do log de acesso:${NC}"
sudo tail -5 /var/log/nginx/ecoreport-access.log 2>/dev/null || echo "Nenhum log ainda"
echo ""
echo -e "${YELLOW}Últimas 5 linhas do log de erro:${NC}"
sudo tail -5 /var/log/nginx/ecoreport-error.log 2>/dev/null || echo "Nenhum erro"

# 10. Resumo
echo -e "\n${GREEN}✅ Correção aplicada!${NC}\n"
echo -e "${BLUE}📋 O que foi feito:${NC}"
echo -e "   - Removido default_server de outros sites"
echo -e "   - Recriada configuração sem redirects"
echo -e "   - Configurado default_server apenas para ${DOMAIN}"
echo -e "   - Nginx recarregado\n"

if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "${YELLOW}⚠️  Ainda há redirect. Possíveis causas:${NC}"
    echo -e "   1. Outro site no Nginx está capturando a requisição primeiro"
    echo -e "   2. Há configuração no nível do servidor (firewall/proxy)"
    echo -e "   3. O navegador está em cache (limpe o cache)\n"
    echo -e "${BLUE}💡 Para investigar mais:${NC}"
    echo -e "   sudo tail -f /var/log/nginx/access.log"
    echo -e "   sudo tail -f /var/log/nginx/ecoreport-access.log"
    echo -e "   curl -v http://${DOMAIN}\n"
else
    echo -e "${GREEN}🎉 Domínio configurado corretamente!${NC}"
fi
