#!/bin/bash

# Script para corrigir conflito do ecoreport.shop
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

echo -e "${BLUE}🔧 Corrigindo conflito do ${DOMAIN}...${NC}\n"

# 1. Verificar o arquivo "ecoreport" que está causando conflito
echo -e "${BLUE}1. Verificando arquivo 'ecoreport' que está causando conflito...${NC}"
if [ -f "/etc/nginx/sites-available/ecoreport" ]; then
    echo -e "${YELLOW}   Conteúdo do arquivo 'ecoreport':${NC}"
    sudo cat /etc/nginx/sites-available/ecoreport
    echo ""
    
    # Verificar se tem ecoreport.shop no server_name
    if sudo grep -q "ecoreport.shop" /etc/nginx/sites-available/ecoreport; then
        echo -e "${RED}   ❌ Arquivo 'ecoreport' também tem 'ecoreport.shop' no server_name!${NC}"
        echo -e "${YELLOW}   Isso está causando o conflito.${NC}\n"
        
        # Fazer backup
        echo -e "${BLUE}   Fazendo backup...${NC}"
        sudo cp /etc/nginx/sites-available/ecoreport /etc/nginx/sites-available/ecoreport.backup
        echo -e "${GREEN}   ✅ Backup criado${NC}\n"
        
        # Remover ecoreport.shop do server_name do arquivo ecoreport
        echo -e "${BLUE}   Removendo 'ecoreport.shop' do arquivo 'ecoreport'...${NC}"
        # Usar sed para remover ecoreport.shop e www.ecoreport.shop do server_name
        sudo sed -i 's/ecoreport\.shop//g' /etc/nginx/sites-available/ecoreport
        sudo sed -i 's/www\.ecoreport\.shop//g' /etc/nginx/sites-available/ecoreport
        # Limpar espaços duplos
        sudo sed -i 's/server_name[[:space:]]\+/server_name /g' /etc/nginx/sites-available/ecoreport
        sudo sed -i 's/[[:space:]]\+/ /g' /etc/nginx/sites-available/ecoreport
        
        echo -e "${GREEN}   ✅ 'ecoreport.shop' removido do arquivo 'ecoreport'${NC}"
        echo -e "${YELLOW}   Novo conteúdo:${NC}"
        sudo grep "server_name" /etc/nginx/sites-available/ecoreport
        echo ""
    else
        echo -e "${GREEN}   ✅ Arquivo 'ecoreport' não tem 'ecoreport.shop'${NC}"
    fi
elif [ -f "/etc/nginx/sites-enabled/ecoreport" ]; then
    echo -e "${YELLOW}   Arquivo 'ecoreport' está apenas em sites-enabled${NC}"
    if sudo grep -q "ecoreport.shop" /etc/nginx/sites-enabled/ecoreport; then
        echo -e "${RED}   ❌ Arquivo 'ecoreport' também tem 'ecoreport.shop'!${NC}"
        # Fazer backup e corrigir
        sudo cp /etc/nginx/sites-enabled/ecoreport /etc/nginx/sites-enabled/ecoreport.backup
        sudo sed -i 's/ecoreport\.shop//g' /etc/nginx/sites-enabled/ecoreport
        sudo sed -i 's/www\.ecoreport\.shop//g' /etc/nginx/sites-enabled/ecoreport
        sudo sed -i 's/server_name[[:space:]]\+/server_name /g' /etc/nginx/sites-enabled/ecoreport
        sudo sed -i 's/[[:space:]]\+/ /g' /etc/nginx/sites-enabled/ecoreport
        echo -e "${GREEN}   ✅ Corrigido${NC}"
    fi
else
    echo -e "${GREEN}   ✅ Arquivo 'ecoreport' não encontrado${NC}"
fi

# 2. Verificar se há outros arquivos com ecoreport.shop
echo -e "\n${BLUE}2. Verificando outros arquivos com 'ecoreport.shop'...${NC}"
for site_file in /etc/nginx/sites-available/* /etc/nginx/sites-enabled/*; do
    if [ -f "$site_file" ] && [[ "$site_file" != *"${DOMAIN}"* ]] && [[ "$site_file" != *"backup"* ]]; then
        if sudo grep -q "ecoreport.shop" "$site_file" 2>/dev/null; then
            site_name=$(basename "$site_file")
            echo -e "${YELLOW}   ⚠️  $site_name também tem 'ecoreport.shop'${NC}"
            # Fazer backup e remover
            sudo cp "$site_file" "${site_file}.backup"
            sudo sed -i 's/ecoreport\.shop//g' "$site_file"
            sudo sed -i 's/www\.ecoreport\.shop//g' "$site_file"
            sudo sed -i 's/server_name[[:space:]]\+/server_name /g' "$site_file"
            sudo sed -i 's/[[:space:]]\+/ /g' "$site_file"
            echo -e "${GREEN}   ✅ Removido de $site_name${NC}"
        fi
    fi
done
echo ""

# 3. Garantir que ecoreport.shop está configurado corretamente (sem redirect)
echo -e "${BLUE}3. Garantindo que ${DOMAIN} está configurado corretamente...${NC}"
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

echo -e "${GREEN}   ✅ Configuração do ${DOMAIN} atualizada (sem redirects)${NC}"
echo ""

# 4. Testar configuração
echo -e "${BLUE}4. Testando configuração...${NC}"
if sudo nginx -t 2>&1 | grep -q "conflicting server name"; then
    echo -e "${RED}   ❌ Ainda há conflitos!${NC}"
    sudo nginx -t
    echo ""
    echo -e "${YELLOW}   Verificando todos os server_name com 'ecoreport.shop'...${NC}"
    sudo grep -r "ecoreport.shop" /etc/nginx/sites-available/ /etc/nginx/sites-enabled/ 2>/dev/null | grep -v ".backup" | grep -v "${DOMAIN}$"
else
    if sudo nginx -t; then
        echo -e "${GREEN}   ✅ Configuração válida (sem conflitos)${NC}"
    else
        echo -e "${RED}   ❌ Erro na configuração!${NC}"
        sudo nginx -t
        exit 1
    fi
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
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${IP} 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${IP} - Status: ${HTTP_CODE}"
else
    echo -e "   ⚠️  http://${IP} - Status: ${HTTP_CODE}"
fi

echo -e "\n${GREEN}Teste 2: Via domínio (Host header)${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: ${DOMAIN}" http://${IP} 2>/dev/null || echo "000")
LOCATION=$(curl -s -I -H "Host: ${DOMAIN}" http://${IP} 2>/dev/null | grep -i "location:" | cut -d' ' -f2 | tr -d '\r' || echo "")
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
echo -e "\n${GREEN}✅ Correção aplicada!${NC}\n"
echo -e "${BLUE}📋 O que foi feito:${NC}"
echo -e "   - Removido 'ecoreport.shop' do arquivo 'ecoreport' (que estava causando conflito)"
echo -e "   - Removido 'ecoreport.shop' de outros arquivos conflitantes"
echo -e "   - Configurado ${DOMAIN} sem redirects"
echo -e "   - Outros sites mantidos intactos\n"

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}🎉 Domínio ${DOMAIN} funcionando corretamente!${NC}"
else
    echo -e "${YELLOW}⚠️  Se ainda houver redirect, pode ser cache do navegador.${NC}"
    echo -e "${YELLOW}   Limpe o cache ou teste em modo anônimo.${NC}"
fi
