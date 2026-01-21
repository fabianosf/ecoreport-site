#!/bin/bash

# Script para Encontrar Pasta de um Site
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="clinicarenatabastos.com.br"

echo -e "${BLUE}🔍 PROCURANDO PASTA DO SITE: ${DOMAIN}${NC}\n"

# 1. Verificar configuração do Nginx
echo -e "${BLUE}1️⃣  Verificando configuração do Nginx...${NC}"
if [ -f "/etc/nginx/sites-available/${DOMAIN}" ]; then
    echo -e "${GREEN}✅ Arquivo de configuração encontrado:${NC}"
    echo -e "${BLUE}/etc/nginx/sites-available/${DOMAIN}${NC}\n"
    
    # Procurar root, proxy_pass, document_root no arquivo
    echo -e "${BLUE}📋 Configuração do site:${NC}"
    sudo cat /etc/nginx/sites-available/${DOMAIN}
    echo ""
    
    # Extrair diretório root
    ROOT_DIR=$(sudo grep -i "root\|proxy_pass" /etc/nginx/sites-available/${DOMAIN} | grep -v "^#" | head -1)
    if [ ! -z "$ROOT_DIR" ]; then
        echo -e "${GREEN}📍 Diretório/path encontrado na configuração:${NC}"
        echo -e "${YELLOW}${ROOT_DIR}${NC}\n"
    fi
else
    echo -e "${YELLOW}⚠️  Arquivo de configuração não encontrado${NC}\n"
fi

# 2. Procurar em locais comuns
echo -e "${BLUE}2️⃣  Procurando em locais comuns...${NC}"

LOCATIONS=(
    "/var/www/${DOMAIN}"
    "/var/www/clinicarenatabastos"
    "/var/www/html"
    "/home/fabianosf/${DOMAIN}"
    "/home/fabianosf/clinicarenatabastos"
    "/var/www"
)

for location in "${LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        echo -e "${GREEN}✅ Diretório encontrado: ${location}${NC}"
        
        # Verificar se parece ser o site correto
        if [ -f "$location/index.html" ] || [ -f "$location/index.php" ] || [ -f "$location/app.js" ]; then
            echo -e "${GREEN}   📁 Parece ser o diretório do site!${NC}"
            ls -lah "$location" | head -10
            echo ""
        fi
    fi
done

# 3. Procurar em todo /var/www
echo -e "${BLUE}3️⃣  Procurando em /var/www...${NC}"
echo -e "${YELLOW}Diretórios encontrados:${NC}"
sudo find /var/www -maxdepth 3 -type d -name "*clinica*" -o -name "*renata*" -o -name "*bastos*" 2>/dev/null | head -10
echo ""

# 4. Procurar por arquivos HTML/PHP relacionados
echo -e "${BLUE}4️⃣  Procurando arquivos relacionados...${NC}"
sudo find /var/www -maxdepth 4 -type f \( -name "*.html" -o -name "*.php" -o -name "index.*" \) -exec grep -l "clinica\|renata\|bastos" {} \; 2>/dev/null | head -5
echo ""

# 5. Verificar PM2 (se estiver rodando algum processo relacionado)
echo -e "${BLUE}5️⃣  Verificando PM2...${NC}"
pm2 list | grep -i "clinica\|renata\|bastos" || echo "Nenhum processo PM2 encontrado"
echo ""

# 6. Verificar processos Node/Next.js relacionados
echo -e "${BLUE}6️⃣  Verificando processos Node.js...${NC}"
ps aux | grep -i "clinica\|renata\|bastos" | grep -v grep || echo "Nenhum processo Node.js encontrado"
echo ""

# 7. Verificar simlinks
echo -e "${BLUE}7️⃣  Verificando simlinks do Nginx...${NC}"
sudo ls -la /etc/nginx/sites-enabled/ | grep "${DOMAIN}"
echo ""

# 8. Resumo
echo -e "${GREEN}✅ BUSCA CONCLUÍDA!${NC}\n"
echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
echo -e "   1. Verifique a configuração do Nginx acima"
echo -e "   2. Veja os diretórios encontrados acima"
echo -e "   3. A pasta provavelmente está em um dos locais mostrados\n"

echo -e "${YELLOW}💡 DICA:${NC}"
echo -e "   Se não encontrou, verifique manualmente:"
echo -e "   sudo cat /etc/nginx/sites-available/${DOMAIN}"
echo -e "   sudo ls -la /var/www/"
echo -e "   sudo find /var/www -name '*clinica*'\n"


