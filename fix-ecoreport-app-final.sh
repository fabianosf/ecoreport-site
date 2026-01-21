#!/bin/bash

# Script para corrigir arquivo 'ecoreport' com certificado app./
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Corrigindo arquivo 'ecoreport' definitivamente...${NC}\n"

# 1. Encontrar arquivo ecoreport
echo -e "${BLUE}1. Localizando arquivo 'ecoreport'...${NC}"
if [ -f "/etc/nginx/sites-enabled/ecoreport" ]; then
    ECOREPORT_FILE="/etc/nginx/sites-enabled/ecoreport"
    echo -e "${GREEN}   ✅ Encontrado: $ECOREPORT_FILE${NC}"
elif [ -f "/etc/nginx/sites-available/ecoreport" ]; then
    ECOREPORT_FILE="/etc/nginx/sites-available/ecoreport"
    echo -e "${GREEN}   ✅ Encontrado: $ECOREPORT_FILE${NC}"
else
    echo -e "${RED}   ❌ Arquivo 'ecoreport' não encontrado!${NC}"
    exit 1
fi
echo ""

# 2. Fazer backup
echo -e "${BLUE}2. Fazendo backup...${NC}"
sudo cp "$ECOREPORT_FILE" "${ECOREPORT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
echo -e "${GREEN}   ✅ Backup criado${NC}"
echo ""

# 3. Verificar certificado
echo -e "${BLUE}3. Verificando certificado SSL...${NC}"
if [ -f "/etc/letsencrypt/live/app.ecoreport.shop/fullchain.pem" ]; then
    CERT_PATH="/etc/letsencrypt/live/app.ecoreport.shop"
    echo -e "${GREEN}   ✅ Certificado encontrado: $CERT_PATH${NC}"
    CERT_EXISTS=true
else
    echo -e "${YELLOW}   ⚠️  Certificado não encontrado${NC}"
    CERT_EXISTS=false
fi
echo ""

# 4. Mostrar linhas problemáticas
echo -e "${BLUE}4. Linhas problemáticas encontradas:${NC}"
sudo grep -n "ssl_certificate.*app\." "$ECOREPORT_FILE" || true
sudo grep -n "ssl_certificate.*live//" "$ECOREPORT_FILE" || true
echo ""

# 5. Corrigir arquivo
echo -e "${BLUE}5. Corrigindo arquivo...${NC}"

if [ "$CERT_EXISTS" = true ]; then
    # Substituir caminhos errados pelo correto
    echo -e "${YELLOW}   Substituindo caminhos errados...${NC}"
    sudo sed -i 's|/etc/letsencrypt/live/app\./fullchain\.pem|/etc/letsencrypt/live/app.ecoreport.shop/fullchain.pem|g' "$ECOREPORT_FILE"
    sudo sed -i 's|/etc/letsencrypt/live/app\./privkey\.pem|/etc/letsencrypt/live/app.ecoreport.shop/privkey.pem|g' "$ECOREPORT_FILE"
    sudo sed -i 's|/etc/letsencrypt/live/app/fullchain\.pem|/etc/letsencrypt/live/app.ecoreport.shop/fullchain.pem|g' "$ECOREPORT_FILE"
    sudo sed -i 's|/etc/letsencrypt/live/app/privkey\.pem|/etc/letsencrypt/live/app.ecoreport.shop/privkey.pem|g' "$ECOREPORT_FILE"
    echo -e "${GREEN}   ✅ Caminhos corrigidos${NC}"
else
    # Comentar todas as linhas SSL
    echo -e "${YELLOW}   Comentando linhas SSL (certificado não existe)...${NC}"
    sudo sed -i 's|^\([[:space:]]*\)ssl_certificate|    # ssl_certificate|g' "$ECOREPORT_FILE"
    sudo sed -i 's|^\([[:space:]]*\)ssl_certificate_key|    # ssl_certificate_key|g' "$ECOREPORT_FILE"
    echo -e "${GREEN}   ✅ Linhas SSL comentadas${NC}"
fi

# Também comentar qualquer linha com live//
sudo sed -i 's|ssl_certificate /etc/letsencrypt/live//fullchain.pem|# ssl_certificate /etc/letsencrypt/live//fullchain.pem|g' "$ECOREPORT_FILE"
sudo sed -i 's|ssl_certificate_key /etc/letsencrypt/live//privkey.pem|# ssl_certificate_key /etc/letsencrypt/live//privkey.pem|g' "$ECOREPORT_FILE"

echo ""

# 6. Verificar se ainda há problemas
echo -e "${BLUE}6. Verificando se ainda há problemas...${NC}"
PROBLEMAS=$(sudo grep -E "ssl_certificate.*live//|ssl_certificate.*app\./" "$ECOREPORT_FILE" 2>/dev/null | grep -v "#" || true)
if [ -n "$PROBLEMAS" ]; then
    echo -e "${YELLOW}   ⚠️  Ainda há problemas:${NC}"
    echo "$PROBLEMAS" | sed 's/^/      /'
    echo ""
    echo -e "${YELLOW}   Comentando todas as linhas SSL...${NC}"
    # Comentar TODAS as linhas SSL que não estão comentadas
    sudo sed -i '/^[[:space:]]*ssl_certificate/s/^/# /' "$ECOREPORT_FILE"
    sudo sed -i '/^[[:space:]]*ssl_certificate_key/s/^/# /' "$ECOREPORT_FILE"
    echo -e "${GREEN}   ✅ Todas as linhas SSL comentadas${NC}"
else
    echo -e "${GREEN}   ✅ Nenhum problema encontrado${NC}"
fi
echo ""

# 7. Mostrar configuração atual
echo -e "${BLUE}7. Configuração atual do certificado SSL:${NC}"
sudo grep -E "ssl_certificate|ssl_certificate_key" "$ECOREPORT_FILE" | head -4 || echo "   Nenhuma linha SSL encontrada"
echo ""

# 8. Testar configuração
echo -e "${BLUE}8. Testando configuração do Nginx...${NC}"
if sudo nginx -t 2>&1 | grep -q "cannot load certificate.*app\."; then
    echo -e "${RED}   ❌ Ainda há erro com app./${NC}"
    echo -e "${YELLOW}   Comentando TODAS as seções SSL do arquivo ecoreport...${NC}"
    
    # Comentar todo o bloco server que tem SSL
    sudo sed -i '/listen 443/,/^}/ s/^/# /' "$ECOREPORT_FILE"
    
    # Ou simplesmente comentar todas as linhas SSL
    sudo sed -i 's|.*ssl_certificate.*|# &|g' "$ECOREPORT_FILE"
    sudo sed -i 's|.*ssl_certificate_key.*|# &|g' "$ECOREPORT_FILE"
    
    echo -e "${GREEN}   ✅ Seções SSL comentadas${NC}"
    echo ""
    echo -e "${BLUE}   Testando novamente...${NC}"
fi

if sudo nginx -t; then
    echo -e "${GREEN}   ✅ Configuração válida!${NC}"
else
    echo -e "${RED}   ❌ Ainda há erro!${NC}"
    sudo nginx -t 2>&1 | head -5
    echo ""
    echo -e "${YELLOW}   Mostrando arquivo ecoreport:${NC}"
    sudo cat "$ECOREPORT_FILE" | grep -A 5 -B 5 "ssl_certificate" || true
    exit 1
fi
echo ""

# 9. Recarregar Nginx
echo -e "${BLUE}9. Recarregando Nginx...${NC}"
sudo systemctl reload nginx
sleep 2
echo -e "${GREEN}   ✅ Nginx recarregado${NC}"
echo ""

# 10. Testes
echo -e "${BLUE}10. Testando acesso...${NC}\n"

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

# 11. Resumo
echo -e "\n${GREEN}✅ Correção concluída!${NC}\n"
echo -e "${BLUE}📋 O que foi feito:${NC}"
echo -e "   - Arquivo 'ecoreport' corrigido"
echo -e "   - Certificado SSL corrigido ou comentado"
echo -e "   - Nginx testado e recarregado\n"

if [ "$CERT_EXISTS" = false ]; then
    echo -e "${YELLOW}⚠️  Certificado SSL para app.ecoreport.shop não encontrado.${NC}"
    echo -e "${YELLOW}   Configure o certificado:${NC}"
    echo -e "${YELLOW}   sudo certbot --nginx -d app.ecoreport.shop${NC}\n"
fi

echo -e "${GREEN}🎉 Configuração corrigida!${NC}"
