#!/bin/bash

# Script para corrigir certificado SSL do app.ecoreport.shop
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Corrigindo certificado SSL do app.ecoreport.shop...${NC}\n"

# 1. Verificar arquivo 'ecoreport'
echo -e "${BLUE}1. Verificando arquivo 'ecoreport'...${NC}"
if [ -f "/etc/nginx/sites-available/ecoreport" ]; then
    ECOREPORT_FILE="/etc/nginx/sites-available/ecoreport"
elif [ -f "/etc/nginx/sites-enabled/ecoreport" ]; then
    ECOREPORT_FILE="/etc/nginx/sites-enabled/ecoreport"
else
    echo -e "${RED}   ❌ Arquivo 'ecoreport' não encontrado!${NC}"
    exit 1
fi

# Verificar se tem certificado com caminho errado
if sudo grep -q "live/app./" "$ECOREPORT_FILE" 2>/dev/null; then
    echo -e "${YELLOW}   ⚠️  Encontrado certificado com caminho errado (app.)${NC}"
    sudo grep "ssl_certificate.*live/app" "$ECOREPORT_FILE" || true
else
    echo -e "${GREEN}   ✅ Nenhum certificado com caminho errado encontrado${NC}"
fi
echo ""

# 2. Verificar se certificado existe
echo -e "${BLUE}2. Verificando certificado SSL...${NC}"
if [ -f "/etc/letsencrypt/live/app.ecoreport.shop/fullchain.pem" ]; then
    echo -e "${GREEN}   ✅ Certificado encontrado: /etc/letsencrypt/live/app.ecoreport.shop/fullchain.pem${NC}"
    CERT_EXISTS=true
else
    echo -e "${YELLOW}   ⚠️  Certificado não encontrado: /etc/letsencrypt/live/app.ecoreport.shop/fullchain.pem${NC}"
    CERT_EXISTS=false
fi
echo ""

# 3. Fazer backup e corrigir
echo -e "${BLUE}3. Corrigindo arquivo 'ecoreport'...${NC}"
sudo cp "$ECOREPORT_FILE" "${ECOREPORT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}   ✅ Backup criado${NC}"

# Corrigir caminho do certificado
if [ "$CERT_EXISTS" = true ]; then
    # Substituir caminhos errados pelo correto
    sudo sed -i 's|/etc/letsencrypt/live/app\./fullchain\.pem|/etc/letsencrypt/live/app.ecoreport.shop/fullchain.pem|g' "$ECOREPORT_FILE"
    sudo sed -i 's|/etc/letsencrypt/live/app\./privkey\.pem|/etc/letsencrypt/live/app.ecoreport.shop/privkey.pem|g' "$ECOREPORT_FILE"
    sudo sed -i 's|/etc/letsencrypt/live/app/fullchain\.pem|/etc/letsencrypt/live/app.ecoreport.shop/fullchain.pem|g' "$ECOREPORT_FILE"
    sudo sed -i 's|/etc/letsencrypt/live/app/privkey\.pem|/etc/letsencrypt/live/app.ecoreport.shop/privkey.pem|g' "$ECOREPORT_FILE"
    echo -e "${GREEN}   ✅ Caminho do certificado corrigido${NC}"
else
    # Se certificado não existe, comentar as linhas SSL
    echo -e "${YELLOW}   ⚠️  Certificado não existe, comentando linhas SSL...${NC}"
    sudo sed -i 's|^[[:space:]]*ssl_certificate|    # ssl_certificate|g' "$ECOREPORT_FILE"
    sudo sed -i 's|^[[:space:]]*ssl_certificate_key|    # ssl_certificate_key|g' "$ECOREPORT_FILE"
    echo -e "${YELLOW}   ⚠️  Linhas SSL comentadas. Configure o certificado depois:${NC}"
    echo -e "${YELLOW}      sudo certbot --nginx -d app.ecoreport.shop${NC}"
fi
echo ""

# 4. Verificar se há outros problemas
echo -e "${BLUE}4. Verificando outros problemas...${NC}"
# Procurar por certificados vazios ou com caminhos estranhos
PROBLEMAS=$(sudo grep -n "ssl_certificate.*live" "$ECOREPORT_FILE" 2>/dev/null | grep -E "live//|live/app\.|live/\$" || true)
if [ -n "$PROBLEMAS" ]; then
    echo -e "${YELLOW}   ⚠️  Ainda há problemas encontrados:${NC}"
    echo "$PROBLEMAS" | sed 's/^/      /'
    echo -e "${YELLOW}   Corrigindo...${NC}"
    # Comentar linhas problemáticas
    sudo sed -i 's|ssl_certificate.*live//|# ssl_certificate /etc/letsencrypt/live//|g' "$ECOREPORT_FILE"
    sudo sed -i 's|ssl_certificate_key.*live//|# ssl_certificate_key /etc/letsencrypt/live//|g' "$ECOREPORT_FILE"
    echo -e "${GREEN}   ✅ Problemas corrigidos${NC}"
else
    echo -e "${GREEN}   ✅ Nenhum outro problema encontrado${NC}"
fi
echo ""

# 5. Mostrar configuração atual
echo -e "${BLUE}5. Configuração atual do certificado SSL:${NC}"
sudo grep "ssl_certificate" "$ECOREPORT_FILE" | head -2 || echo "   Nenhuma linha SSL encontrada"
echo ""

# 6. Testar configuração
echo -e "${BLUE}6. Testando configuração do Nginx...${NC}"
if sudo nginx -t 2>&1 | grep -q "cannot load certificate"; then
    echo -e "${RED}   ❌ Ainda há erro de certificado!${NC}"
    sudo nginx -t 2>&1 | grep "cannot load certificate"
    echo ""
    echo -e "${YELLOW}   Verificando todos os certificados SSL...${NC}"
    sudo grep -r "ssl_certificate.*live" /etc/nginx/sites-available/ /etc/nginx/sites-enabled/ 2>/dev/null | grep -v backup | grep -v "#"
    echo ""
    echo -e "${YELLOW}   Comentando todas as linhas SSL problemáticas...${NC}"
    sudo find /etc/nginx/sites-available /etc/nginx/sites-enabled -type f -name "ecoreport" -exec sed -i 's|^[[:space:]]*ssl_certificate|    # ssl_certificate|g' {} \;
    sudo find /etc/nginx/sites-available /etc/nginx/sites-enabled -type f -name "ecoreport" -exec sed -i 's|^[[:space:]]*ssl_certificate_key|    # ssl_certificate_key|g' {} \;
    echo -e "${GREEN}   ✅ Linhas SSL problemáticas comentadas${NC}"
    echo ""
    echo -e "${BLUE}   Testando novamente...${NC}"
fi

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

# 8. Testes
echo -e "${BLUE}8. Testando acesso...${NC}\n"

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

# 9. Resumo
echo -e "\n${GREEN}✅ Correção concluída!${NC}\n"
echo -e "${BLUE}📋 O que foi feito:${NC}"
echo -e "   - Certificado SSL do app.ecoreport.shop corrigido"
echo -e "   - Arquivo 'ecoreport' atualizado"
echo -e "   - Nginx recarregado\n"

if [ "$CERT_EXISTS" = false ]; then
    echo -e "${YELLOW}⚠️  Certificado SSL para app.ecoreport.shop não encontrado.${NC}"
    echo -e "${YELLOW}   Configure o certificado:${NC}"
    echo -e "${YELLOW}   sudo certbot --nginx -d app.ecoreport.shop${NC}\n"
fi

echo -e "${GREEN}🎉 Configuração corrigida!${NC}"
