#!/bin/bash

# Script para Finalizar Setup - Passos 2-8
# Execute NO SERVIDOR (após npm install)

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 FINALIZANDO SETUP - Passos 2-8${NC}\n"

APP_DIR="/var/www/ecoreport-site"
DOMAIN="ecoreport.shop"

# Verificar se está no diretório correto
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Execute este script no diretório /var/www/ecoreport-site${NC}"
    exit 1
fi

# Passo 2: Criar .env.local
echo -e "${BLUE}📝 Passo 2: Criando .env.local...${NC}"
cat > .env.local << 'ENVEOF'
NEXT_PUBLIC_GA_ID=G-FY0M95V3SN
NEXT_PUBLIC_SITE_URL=https://ecoreport.shop
GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID/exec
NODE_ENV=production
ENVEOF
echo -e "${GREEN}✅ .env.local criado${NC}\n"

# Passo 3: Fazer build
echo -e "${BLUE}🔨 Passo 3: Fazendo build...${NC}"
npm run build
echo -e "${GREEN}✅ Build concluído${NC}\n"

# Passo 4: Iniciar PM2
echo -e "${BLUE}🚀 Passo 4: Iniciando com PM2...${NC}"
pm2 delete ecoreport-site 2>/dev/null || true
pm2 start npm --name ecoreport-site -- start
pm2 save
echo -e "${GREEN}✅ PM2 iniciado${NC}\n"

# Passo 5: Aguardar e verificar
echo -e "${BLUE}🔍 Passo 5: Verificando aplicação...${NC}"
sleep 8
echo -e "${GREEN}Status do PM2:${NC}"
pm2 status

echo -e "\n${BLUE}Testando localhost:3000...${NC}"
if curl -s http://localhost:3000 | grep -q "EcoReport"; then
    echo -e "${GREEN}✅ Aplicação responde em localhost:3000${NC}"
else
    echo -e "${YELLOW}⚠️  Aplicação ainda não respondeu. Aguardando...${NC}"
    sleep 5
    curl -I http://localhost:3000 2>&1 | head -3 || echo "Ainda iniciando..."
fi
echo ""

# Passo 6: Configurar Nginx
echo -e "${BLUE}🌐 Passo 6: Configurando Nginx...${NC}"
sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

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
    }
}
NGINXEOF
echo -e "${GREEN}✅ Configuração Nginx criada${NC}\n"

# Passo 7: Ativar site e recarregar Nginx
echo -e "${BLUE}🔗 Passo 7: Ativando site no Nginx...${NC}"
sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

echo -e "${BLUE}🧪 Testando configuração Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuração Nginx OK${NC}"
    sudo systemctl reload nginx
    echo -e "${GREEN}✅ Nginx recarregado${NC}\n"
else
    echo -e "${RED}❌ Erro na configuração Nginx!${NC}"
    exit 1
fi

# Passo 8: Testar
echo -e "${BLUE}🧪 Passo 8: Testando site...${NC}"
sleep 2
echo -e "${GREEN}Teste via Nginx:${NC}"
curl -I http://${DOMAIN} 2>&1 | head -5 || echo -e "${YELLOW}DNS pode não estar configurado ainda${NC}"

echo -e "\n${GREEN}🎉 SETUP FINALIZADO!${NC}\n"
echo -e "${BLUE}📊 VERIFICAÇÃO FINAL:${NC}\n"

echo -e "${GREEN}✅ Status do PM2:${NC}"
pm2 status | head -3

echo -e "\n${GREEN}✅ Porta 3000:${NC}"
netstat -tlnp 2>/dev/null | grep :3000 || ss -tlnp 2>/dev/null | grep :3000 || echo "Não detectado"

echo -e "\n${GREEN}✅ Teste local:${NC}"
curl -I http://localhost:3000 2>&1 | head -3

echo -e "\n${BLUE}🌐 Acesse: http://${DOMAIN}${NC}\n"

echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo -e "   Se ainda não funcionar, verifique:"
echo -e "   1. DNS está configurado? (nslookup ${DOMAIN})"
echo -e "   2. Firewall permite porta 80? (sudo ufw status)"
echo -e "   3. PM2 está rodando? (pm2 status)"
echo -e "   4. Logs do PM2: (pm2 logs ecoreport-site)\n"

