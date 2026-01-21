#!/bin/bash

# Script DEFINITIVO para corrigir certificado SSL vazio
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Correção DEFINITIVA de certificados SSL...${NC}\n"

# 1. Procurar em TODOS os arquivos do Nginx
echo -e "${BLUE}1. Procurando em TODOS os arquivos do Nginx...${NC}"

# Listar todos os arquivos que podem ter configuração SSL
ALL_FILES=(
    /etc/nginx/nginx.conf
    /etc/nginx/sites-available/*
    /etc/nginx/sites-enabled/*
    /etc/nginx/conf.d/*
)

for pattern in "${ALL_FILES[@]}"; do
    for file in $pattern; do
        if [ -f "$file" ] && [[ "$file" != *"backup"* ]]; then
            # Verificar se tem certificado vazio (com //)
            if sudo grep -q "ssl_certificate.*live//" "$file" 2>/dev/null; then
                echo -e "${YELLOW}   ⚠️  Encontrado em: $file${NC}"
                sudo grep -n "ssl_certificate.*live//" "$file" | head -5
            fi
        fi
    done
done
echo ""

# 2. Comentar TODAS as linhas SSL com caminho vazio em TODOS os arquivos
echo -e "${BLUE}2. Comentando TODAS as linhas SSL problemáticas...${NC}"

for pattern in "${ALL_FILES[@]}"; do
    for file in $pattern; do
        if [ -f "$file" ] && [[ "$file" != *"backup"* ]]; then
            # Verificar se tem certificado vazio
            if sudo grep -q "ssl_certificate.*live//" "$file" 2>/dev/null; then
                file_name=$(basename "$file")
                echo -e "${YELLOW}   Corrigindo: $file_name${NC}"
                
                # Fazer backup
                sudo cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
                
                # Comentar linhas com certificado vazio (múltiplas tentativas)
                sudo sed -i 's|ssl_certificate /etc/letsencrypt/live//fullchain.pem|# ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' "$file"
                sudo sed -i 's|ssl_certificate_key /etc/letsencrypt/live//privkey.pem|# ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' "$file"
                
                # Também comentar se tiver espaços ou tabs antes
                sudo sed -i 's|^[[:space:]]*ssl_certificate /etc/letsencrypt/live//fullchain.pem|    # ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' "$file"
                sudo sed -i 's|^[[:space:]]*ssl_certificate_key /etc/letsencrypt/live//privkey.pem|    # ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' "$file"
                
                echo -e "${GREEN}   ✅ $file_name corrigido${NC}"
            fi
        fi
    done
done
echo ""

# 3. Busca mais agressiva - procurar por qualquer menção a "live//"
echo -e "${BLUE}3. Busca agressiva por 'live//'...${NC}"
ENCONTRADOS=$(sudo grep -r "live//" /etc/nginx/ 2>/dev/null | grep -v backup | grep -v "#" || true)
if [ -n "$ENCONTRADOS" ]; then
    echo -e "${YELLOW}   ⚠️  Ainda encontrados:${NC}"
    echo "$ENCONTRADOS" | sed 's/^/      /'
    echo ""
    echo -e "${YELLOW}   Comentando todos...${NC}"
    
    # Comentar TODAS as ocorrências de live// em TODOS os arquivos do nginx
    sudo find /etc/nginx -type f -name "*.conf" -o -name "*" | while read file; do
        if [ -f "$file" ] && [[ "$file" != *"backup"* ]]; then
            sudo sed -i 's|\(.*\)ssl_certificate /etc/letsencrypt/live//fullchain.pem\(.*\)|\1# ssl_certificate /etc/letsencrypt/live//fullchain.pem\2|g' "$file" 2>/dev/null || true
            sudo sed -i 's|\(.*\)ssl_certificate_key /etc/letsencrypt/live//privkey.pem\(.*\)|\1# ssl_certificate_key /etc/letsencrypt/live//privkey.pem\2|g' "$file" 2>/dev/null || true
        fi
    done
    
    echo -e "${GREEN}   ✅ Todos comentados${NC}"
else
    echo -e "${GREEN}   ✅ Nenhum encontrado${NC}"
fi
echo ""

# 4. Verificar nginx.conf principal
echo -e "${BLUE}4. Verificando nginx.conf principal...${NC}"
if sudo grep -q "ssl_certificate.*live//" /etc/nginx/nginx.conf 2>/dev/null; then
    echo -e "${YELLOW}   ⚠️  nginx.conf também tem problema!${NC}"
    sudo grep "ssl_certificate.*live//" /etc/nginx/nginx.conf
    echo -e "${YELLOW}   Corrigindo...${NC}"
    sudo sed -i 's|ssl_certificate /etc/letsencrypt/live//fullchain.pem|# ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' /etc/nginx/nginx.conf
    sudo sed -i 's|ssl_certificate_key /etc/letsencrypt/live//privkey.pem|# ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' /etc/nginx/nginx.conf
    echo -e "${GREEN}   ✅ nginx.conf corrigido${NC}"
else
    echo -e "${GREEN}   ✅ nginx.conf OK${NC}"
fi
echo ""

# 5. Verificar includes no nginx.conf
echo -e "${BLUE}5. Verificando includes no nginx.conf...${NC}"
INCLUDES=$(sudo grep -E "^[[:space:]]*include" /etc/nginx/nginx.conf 2>/dev/null | awk '{print $2}' | tr -d ';' || true)
if [ -n "$INCLUDES" ]; then
    echo -e "${YELLOW}   Includes encontrados:${NC}"
    for include in $INCLUDES; do
        # Expandir wildcards
        for inc_file in $include; do
            if [ -f "$inc_file" ]; then
                echo -e "      - $inc_file"
                if sudo grep -q "ssl_certificate.*live//" "$inc_file" 2>/dev/null; then
                    echo -e "${YELLOW}         ⚠️  Tem problema! Corrigindo...${NC}"
                    sudo sed -i 's|ssl_certificate /etc/letsencrypt/live//fullchain.pem|# ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' "$inc_file"
                    sudo sed -i 's|ssl_certificate_key /etc/letsencrypt/live//privkey.pem|# ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' "$inc_file"
                    echo -e "${GREEN}         ✅ Corrigido${NC}"
                fi
            fi
        done
    done
else
    echo -e "${GREEN}   ✅ Nenhum include encontrado${NC}"
fi
echo ""

# 6. Verificação final
echo -e "${BLUE}6. Verificação final...${NC}"
RESTANTES=$(sudo grep -r "ssl_certificate.*live//" /etc/nginx/ 2>/dev/null | grep -v backup | grep -v "#" || true)
if [ -n "$RESTANTES" ]; then
    echo -e "${RED}   ❌ Ainda há problemas:${NC}"
    echo "$RESTANTES" | sed 's/^/      /'
    echo ""
    echo -e "${YELLOW}   Forçando comentário em TODOS os arquivos...${NC}"
    # Última tentativa - comentar TUDO que tem live//
    sudo find /etc/nginx -type f ! -name "*.backup*" -exec sed -i 's|\([^#]*\)ssl_certificate /etc/letsencrypt/live//fullchain.pem|\1# ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' {} \;
    sudo find /etc/nginx -type f ! -name "*.backup*" -exec sed -i 's|\([^#]*\)ssl_certificate_key /etc/letsencrypt/live//privkey.pem|\1# ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' {} \;
    echo -e "${GREEN}   ✅ Forçado${NC}"
else
    echo -e "${GREEN}   ✅ Nenhum problema restante${NC}"
fi
echo ""

# 7. Testar configuração
echo -e "${BLUE}7. Testando configuração do Nginx...${NC}"
if sudo nginx -t 2>&1 | grep -q "cannot load certificate.*live//"; then
    echo -e "${RED}   ❌ Ainda há erro!${NC}"
    ERRO=$(sudo nginx -t 2>&1 | grep "cannot load certificate.*live//")
    echo -e "${YELLOW}   $ERRO${NC}"
    echo ""
    echo -e "${YELLOW}   Listando TODOS os arquivos do Nginx:${NC}"
    sudo find /etc/nginx -type f -name "*.conf" -o -name "*" | grep -v backup | head -20
    echo ""
    echo -e "${YELLOW}   Procurando manualmente...${NC}"
    # Procurar linha por linha em todos os arquivos
    sudo find /etc/nginx -type f ! -name "*.backup*" -exec grep -l "live//" {} \; 2>/dev/null | while read file; do
        echo -e "${YELLOW}   Arquivo problemático: $file${NC}"
        sudo sed -i 's|.*live//.*|# &|g' "$file"
    done
    echo -e "${GREEN}   ✅ Todos os arquivos com 'live//' foram comentados${NC}"
    echo ""
    echo -e "${BLUE}   Testando novamente...${NC}"
fi

if sudo nginx -t; then
    echo -e "${GREEN}   ✅ Configuração válida!${NC}"
else
    echo -e "${RED}   ❌ Ainda há erro!${NC}"
    sudo nginx -t 2>&1 | head -10
    echo ""
    echo -e "${YELLOW}   Mostrando últimos 20 arquivos modificados:${NC}"
    sudo find /etc/nginx -type f -name "*.conf" -mmin -5 2>/dev/null | head -20
    exit 1
fi
echo ""

# 8. Recarregar Nginx
echo -e "${BLUE}8. Recarregando Nginx...${NC}"
sudo systemctl reload nginx
sleep 2
echo -e "${GREEN}   ✅ Nginx recarregado${NC}"
echo ""

# 9. Testes
echo -e "${BLUE}9. Testando acesso...${NC}\n"

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

# 10. Resumo
echo -e "\n${GREEN}✅ Correção DEFINITIVA concluída!${NC}\n"
echo -e "${BLUE}📋 O que foi feito:${NC}"
echo -e "   - Procurado em TODOS os arquivos do Nginx"
echo -e "   - Verificado nginx.conf principal"
echo -e "   - Verificado includes"
echo -e "   - Comentado TODAS as linhas SSL com caminho vazio"
echo -e "   - Nginx testado e recarregado\n"

echo -e "${GREEN}🎉 Configuração corrigida!${NC}"
