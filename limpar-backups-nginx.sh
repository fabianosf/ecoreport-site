#!/bin/bash

# Script para remover arquivos de backup do sites-enabled
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🧹 Removendo arquivos de backup do sites-enabled...${NC}\n"

# 1. Listar arquivos de backup
echo -e "${BLUE}1. Arquivos de backup encontrados em sites-enabled:${NC}"
BACKUPS=$(ls /etc/nginx/sites-enabled/*.backup* 2>/dev/null || true)
if [ -n "$BACKUPS" ]; then
    echo "$BACKUPS" | while read backup; do
        echo -e "${YELLOW}   - $(basename $backup)${NC}"
    done
else
    echo -e "${GREEN}   ✅ Nenhum backup encontrado${NC}"
fi
echo ""

# 2. Remover arquivos de backup
echo -e "${BLUE}2. Removendo arquivos de backup...${NC}"
if [ -n "$BACKUPS" ]; then
    for backup in $BACKUPS; do
        echo -e "${YELLOW}   Removendo: $(basename $backup)${NC}"
        sudo rm -f "$backup"
    done
    echo -e "${GREEN}   ✅ Backups removidos${NC}"
else
    echo -e "${GREEN}   ✅ Nenhum backup para remover${NC}"
fi
echo ""

# 3. Verificar se há outros arquivos problemáticos
echo -e "${BLUE}3. Verificando outros arquivos problemáticos...${NC}"
PROBLEMAS=$(ls /etc/nginx/sites-enabled/ 2>/dev/null | grep -E "backup|\.bak|\.old" || true)
if [ -n "$PROBLEMAS" ]; then
    echo -e "${YELLOW}   ⚠️  Outros arquivos problemáticos encontrados:${NC}"
    echo "$PROBLEMAS" | while read problema; do
        echo -e "${YELLOW}   - $problema${NC}"
        sudo rm -f "/etc/nginx/sites-enabled/$problema"
    done
    echo -e "${GREEN}   ✅ Removidos${NC}"
else
    echo -e "${GREEN}   ✅ Nenhum problema encontrado${NC}"
fi
echo ""

# 4. Listar arquivos ativos
echo -e "${BLUE}4. Arquivos ativos em sites-enabled:${NC}"
ls -la /etc/nginx/sites-enabled/ | grep -v "^total" | grep -v "^d" | awk '{print "   - " $9}'
echo ""

# 5. Testar configuração
echo -e "${BLUE}5. Testando configuração do Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}   ✅ Configuração válida!${NC}"
else
    echo -e "${RED}   ❌ Ainda há erro!${NC}"
    sudo nginx -t 2>&1 | head -10
    echo ""
    echo -e "${YELLOW}   Verificando todos os arquivos em sites-enabled...${NC}"
    for file in /etc/nginx/sites-enabled/*; do
        if [ -f "$file" ]; then
            echo -e "${YELLOW}   Arquivo: $(basename $file)${NC}"
            # Verificar se tem erro de sintaxe
            if sudo nginx -t 2>&1 | grep -q "$(basename $file)"; then
                echo -e "${RED}      ⚠️  Este arquivo tem problema!${NC}"
            fi
        fi
    done
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
echo -e "\n${GREEN}✅ Limpeza concluída!${NC}\n"
echo -e "${BLUE}📋 O que foi feito:${NC}"
echo -e "   - Arquivos de backup removidos de sites-enabled"
echo -e "   - Nginx testado e recarregado\n"

echo -e "${GREEN}🎉 Configuração corrigida!${NC}"
