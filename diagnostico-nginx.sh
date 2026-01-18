#!/bin/bash

# Script de Diagnóstico - Verificar Por Que 404
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔍 DIAGNÓSTICO COMPLETO${NC}\n"

DOMAIN="ecoreport.shop"

# 1. Verificar PM2
echo -e "${BLUE}1️⃣  Verificando PM2...${NC}"
pm2 status
echo ""

# 2. Verificar porta 3000
echo -e "${BLUE}2️⃣  Verificando porta 3000...${NC}"
if netstat -tlnp 2>/dev/null | grep :3000 || ss -tlnp 2>/dev/null | grep :3000; then
    echo -e "${GREEN}✅ Porta 3000 ativa${NC}"
else
    echo -e "${RED}❌ Porta 3000 NÃO ativa!${NC}"
fi
echo ""

# 3. Testar localhost:3000
echo -e "${BLUE}3️⃣  Testando localhost:3000...${NC}"
curl -I http://localhost:3000 2>&1 | head -5
echo ""

# 4. Verificar configuração Nginx do ecoreport.shop
echo -e "${BLUE}4️⃣  Verificando configuração Nginx...${NC}"
if [ -f "/etc/nginx/sites-available/ecoreport.shop" ]; then
    echo -e "${GREEN}✅ Arquivo existe${NC}"
    echo -e "${BLUE}Conteúdo:${NC}"
    sudo cat /etc/nginx/sites-available/ecoreport.shop
else
    echo -e "${RED}❌ Arquivo NÃO existe!${NC}"
fi
echo ""

# 5. Verificar se está ativado
echo -e "${BLUE}5️⃣  Verificando sites ativados...${NC}"
sudo ls -la /etc/nginx/sites-enabled/ | grep ecoreport
echo ""

# 6. Testar configuração Nginx
echo -e "${BLUE}6️⃣  Testando configuração Nginx...${NC}"
sudo nginx -t 2>&1
echo ""

# 7. Verificar qual server block está sendo usado
echo -e "${BLUE}7️⃣  Testando com Host header...${NC}"
echo -e "${YELLOW}Teste 1: Com Host header (simula domínio)${NC}"
curl -v -H "Host: ${DOMAIN}" http://localhost 2>&1 | grep -E "< HTTP|< Server|< Location|404|200" || curl -I -H "Host: ${DOMAIN}" http://localhost 2>&1 | head -3
echo ""

echo -e "${YELLOW}Teste 2: Sem Host header (localhost direto)${NC}"
curl -I http://localhost 2>&1 | head -5
echo ""

# 8. Ver logs do Nginx
echo -e "${BLUE}8️⃣  Últimas linhas do log de erro do Nginx...${NC}"
sudo tail -10 /var/log/nginx/error.log 2>/dev/null || echo "Log não encontrado"
echo ""

# 9. Ver qual site está como default
echo -e "${BLUE}9️⃣  Verificando default_server...${NC}"
sudo grep -r "default_server" /etc/nginx/sites-enabled/ 2>/dev/null || echo "Nenhum default_server encontrado"
echo ""

# 10. IP do servidor
echo -e "${BLUE}🔟 IP do servidor...${NC}"
hostname -I | awk '{print $1}'
echo ""

# 11. Teste via domínio
echo -e "${BLUE}1️⃣1️⃣  Teste via domínio (se DNS estiver OK)...${NC}"
curl -I http://${DOMAIN} 2>&1 | head -5 || echo "DNS pode não estar configurado"
echo ""

echo -e "${GREEN}✅ DIAGNÓSTICO CONCLUÍDO${NC}\n"
echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
echo -e "   Se localhost:3000 funciona mas Nginx retorna 404:"
echo -e "   → Problema na configuração do Nginx"
echo -e "   Se localhost:3000 NÃO funciona:"
echo -e "   → Problema no PM2/Next.js"
echo ""

