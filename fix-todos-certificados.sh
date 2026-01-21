#!/bin/bash

# Script para corrigir TODOS os certificados SSL problemáticos
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Corrigindo TODOS os certificados SSL problemáticos...${NC}\n"

# 1. Procurar TODOS os arquivos com certificados problemáticos
echo -e "${BLUE}1. Procurando TODOS os certificados SSL problemáticos...${NC}"
PROBLEMAS=()

# Procurar em sites-available e sites-enabled
for site_file in /etc/nginx/sites-available/* /etc/nginx/sites-enabled/*; do
    if [ -f "$site_file" ] && [[ "$site_file" != *"backup"* ]]; then
        # Verificar se tem certificado vazio ou com caminho errado
        if sudo grep -q "ssl_certificate.*live//" "$site_file" 2>/dev/null || \
           sudo grep -q "ssl_certificate.*live/app\./" "$site_file" 2>/dev/null || \
           sudo grep -q "ssl_certificate.*live/\$" "$site_file" 2>/dev/null; then
            PROBLEMAS+=("$site_file")
            site_name=$(basename "$site_file")
            echo -e "${YELLOW}   ⚠️  Problema em: $site_name${NC}"
            sudo grep "ssl_certificate.*live" "$site_file" | grep -E "live//|live/app\.|live/\$" || true
        fi
    fi
done

if [ ${#PROBLEMAS[@]} -eq 0 ]; then
    echo -e "${GREEN}   ✅ Nenhum problema encontrado${NC}"
else
    echo -e "${YELLOW}   ${#PROBLEMAS[@]} arquivo(s) com problema${NC}"
fi
echo ""

# 2. Corrigir TODOS os arquivos
echo -e "${BLUE}2. Corrigindo TODOS os arquivos...${NC}"
for site_file in "${PROBLEMAS[@]}"; do
    if [ -f "$site_file" ]; then
        site_name=$(basename "$site_file")
        echo -e "${YELLOW}   Corrigindo: $site_name${NC}"
        
        # Fazer backup
        sudo cp "$site_file" "${site_file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Comentar TODAS as linhas SSL com caminho vazio ou errado
        sudo sed -i 's|^\([[:space:]]*\)ssl_certificate /etc/letsencrypt/live//fullchain.pem|\1# ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' "$site_file"
        sudo sed -i 's|^\([[:space:]]*\)ssl_certificate_key /etc/letsencrypt/live//privkey.pem|\1# ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' "$site_file"
        sudo sed -i 's|^\([[:space:]]*\)ssl_certificate /etc/letsencrypt/live/app\./fullchain.pem|\1# ssl_certificate /etc/letsencrypt/live/app./fullchain.pem|g' "$site_file"
        sudo sed -i 's|^\([[:space:]]*\)ssl_certificate_key /etc/letsencrypt/live/app\./privkey.pem|\1# ssl_certificate_key /etc/letsencrypt/live/app./privkey.pem|g' "$site_file"
        
        echo -e "${GREEN}   ✅ $site_name corrigido${NC}"
    fi
done

# 3. Procurar e comentar TODAS as linhas SSL problemáticas em TODOS os arquivos
echo -e "\n${BLUE}3. Procurando e comentando TODAS as linhas SSL problemáticas...${NC}"
for site_file in /etc/nginx/sites-available/* /etc/nginx/sites-enabled/*; do
    if [ -f "$site_file" ] && [[ "$site_file" != *"backup"* ]]; then
        # Verificar se ainda tem problema
        if sudo grep -q "ssl_certificate.*live//" "$site_file" 2>/dev/null || \
           sudo grep -q "ssl_certificate.*live/app\./" "$site_file" 2>/dev/null; then
            site_name=$(basename "$site_file")
            echo -e "${YELLOW}   Ainda há problema em: $site_name${NC}"
            
            # Comentar todas as linhas SSL problemáticas
            sudo sed -i 's|ssl_certificate /etc/letsencrypt/live//fullchain.pem|# ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' "$site_file"
            sudo sed -i 's|ssl_certificate_key /etc/letsencrypt/live//privkey.pem|# ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' "$site_file"
            sudo sed -i 's|ssl_certificate /etc/letsencrypt/live/app\./fullchain.pem|# ssl_certificate /etc/letsencrypt/live/app./fullchain.pem|g' "$site_file"
            sudo sed -i 's|ssl_certificate_key /etc/letsencrypt/live/app\./privkey.pem|# ssl_certificate_key /etc/letsencrypt/live/app./privkey.pem|g' "$site_file"
            
            echo -e "${GREEN}   ✅ $site_name corrigido${NC}"
        fi
    fi
done
echo ""

# 4. Verificar se ainda há problemas
echo -e "${BLUE}4. Verificando se ainda há problemas...${NC}"
RESTANTES=$(sudo grep -r "ssl_certificate.*live//" /etc/nginx/sites-available/ /etc/nginx/sites-enabled/ 2>/dev/null | grep -v backup | grep -v "#" || true)
if [ -n "$RESTANTES" ]; then
    echo -e "${YELLOW}   ⚠️  Ainda há problemas:${NC}"
    echo "$RESTANTES" | sed 's/^/      /'
    echo ""
    echo -e "${YELLOW}   Comentando manualmente...${NC}"
    # Comentar todas as ocorrências restantes
    sudo find /etc/nginx/sites-available /etc/nginx/sites-enabled -type f -exec sed -i 's|ssl_certificate /etc/letsencrypt/live//fullchain.pem|# ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' {} \;
    sudo find /etc/nginx/sites-available /etc/nginx/sites-enabled -type f -exec sed -i 's|ssl_certificate_key /etc/letsencrypt/live//privkey.pem|# ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' {} \;
    sudo find /etc/nginx/sites-available /etc/nginx/sites-enabled -type f -exec sed -i 's|ssl_certificate /etc/letsencrypt/live/app\./fullchain.pem|# ssl_certificate /etc/letsencrypt/live/app./fullchain.pem|g' {} \;
    sudo find /etc/nginx/sites-available /etc/nginx/sites-enabled -type f -exec sed -i 's|ssl_certificate_key /etc/letsencrypt/live/app\./privkey.pem|# ssl_certificate_key /etc/letsencrypt/live/app./privkey.pem|g' {} \;
    echo -e "${GREEN}   ✅ Todos os problemas comentados${NC}"
else
    echo -e "${GREEN}   ✅ Nenhum problema restante${NC}"
fi
echo ""

# 5. Testar configuração
echo -e "${BLUE}5. Testando configuração do Nginx...${NC}"
if sudo nginx -t 2>&1 | grep -q "cannot load certificate"; then
    echo -e "${RED}   ❌ Ainda há erro!${NC}"
    ERRO=$(sudo nginx -t 2>&1 | grep "cannot load certificate")
    echo -e "${YELLOW}   $ERRO${NC}"
    echo ""
    
    # Extrair o caminho problemático
    CAMINHO_PROBLEMA=$(echo "$ERRO" | grep -oP '/etc/letsencrypt/live/[^"]+' || echo "")
    if [ -n "$CAMINHO_PROBLEMA" ]; then
        echo -e "${YELLOW}   Procurando arquivo com: $CAMINHO_PROBLEMA${NC}"
        sudo grep -r "$CAMINHO_PROBLEMA" /etc/nginx/sites-available/ /etc/nginx/sites-enabled/ 2>/dev/null | grep -v backup | grep -v "#"
        echo ""
        echo -e "${YELLOW}   Comentando...${NC}"
        sudo find /etc/nginx/sites-available /etc/nginx/sites-enabled -type f -exec sed -i "s|ssl_certificate.*$CAMINHO_PROBLEMA|# &|g" {} \;
        sudo find /etc/nginx/sites-available /etc/nginx/sites-enabled -type f -exec sed -i "s|ssl_certificate_key.*$CAMINHO_PROBLEMA|# &|g" {} \;
        echo -e "${GREEN}   ✅ Comentado${NC}"
        echo ""
        echo -e "${BLUE}   Testando novamente...${NC}"
    fi
fi

if sudo nginx -t; then
    echo -e "${GREEN}   ✅ Configuração válida!${NC}"
else
    echo -e "${RED}   ❌ Ainda há erro na configuração!${NC}"
    sudo nginx -t
    echo ""
    echo -e "${YELLOW}   Mostrando todos os certificados SSL:${NC}"
    sudo grep -r "ssl_certificate" /etc/nginx/sites-available/ /etc/nginx/sites-enabled/ 2>/dev/null | grep -v backup | grep -v "#"
    exit 1
fi
echo ""

# 6. Recarregar Nginx
echo -e "${BLUE}6. Recarregando Nginx...${NC}"
sudo systemctl reload nginx
sleep 2
echo -e "${GREEN}   ✅ Nginx recarregado${NC}"
echo ""

# 7. Testes
echo -e "${BLUE}7. Testando acesso...${NC}\n"

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

# 8. Resumo
echo -e "\n${GREEN}✅ Correção concluída!${NC}\n"
echo -e "${BLUE}📋 O que foi feito:${NC}"
echo -e "   - Todos os certificados SSL com caminho vazio foram comentados"
echo -e "   - Todos os certificados SSL com caminho errado foram comentados"
echo -e "   - Nginx testado e recarregado\n"

echo -e "${GREEN}🎉 Configuração corrigida!${NC}"
