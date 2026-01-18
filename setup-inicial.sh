#!/bin/bash

# Script de Setup Inicial - Cria tudo do zero
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 SETUP INICIAL - EcoReport Site${NC}\n"

APP_DIR="/var/www/ecoreport-site"
REPO_URL="https://github.com/fabianosf/ecoreport-site.git"
DOMAIN="ecoreport.shop"

# 1. Criar diretório
echo -e "${BLUE}📁 Criando diretório...${NC}"
sudo mkdir -p ${APP_DIR}
sudo chown -R $USER:$USER ${APP_DIR}
echo -e "${GREEN}✅ Diretório criado${NC}\n"

# 2. Instalar Node.js (se não tiver)
if ! command -v node &> /dev/null; then
    echo -e "${BLUE}📦 Instalando Node.js 20...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo -e "${GREEN}✅ Node.js já instalado: $(node --version)${NC}"
fi

# 3. Instalar PM2 (se não tiver)
if ! command -v pm2 &> /dev/null; then
    echo -e "${BLUE}📦 Instalando PM2...${NC}"
    sudo npm install -g pm2
    pm2 startup
else
    echo -e "${GREEN}✅ PM2 já instalado${NC}"
fi

# 4. Clonar repositório
echo -e "${BLUE}📥 Clonando repositório...${NC}"
cd /var/www
if [ -d "ecoreport-site" ]; then
    sudo rm -rf ecoreport-site
fi
git clone ${REPO_URL}
sudo chown -R $USER:$USER ecoreport-site
cd ecoreport-site
echo -e "${GREEN}✅ Repositório clonado${NC}\n"

# 5. Instalar dependências
echo -e "${BLUE}📦 Instalando dependências...${NC}"
npm install
echo -e "${GREEN}✅ Dependências instaladas${NC}\n"

# 6. Criar .env.local
echo -e "${BLUE}📝 Criando .env.local...${NC}"
cat > .env.local << 'ENVEOF'
NEXT_PUBLIC_GA_ID=G-FY0M95V3SN
NEXT_PUBLIC_SITE_URL=https://ecoreport.shop
GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID/exec
NODE_ENV=production
ENVEOF
echo -e "${GREEN}✅ .env.local criado${NC}\n"

# 7. Build
echo -e "${BLUE}🔨 Fazendo build...${NC}"
npm run build
echo -e "${GREEN}✅ Build concluído${NC}\n"

# 8. Iniciar PM2
echo -e "${BLUE}🚀 Iniciando com PM2...${NC}"
pm2 delete ecoreport-site 2>/dev/null || true
pm2 start npm --name ecoreport-site -- start
pm2 save
sleep 5
echo -e "${GREEN}✅ PM2 iniciado${NC}\n"

# 9. Verificar porta 3000
if netstat -tlnp 2>/dev/null | grep -q ":3000" || ss -tlnp 2>/dev/null | grep -q ":3000"; then
    echo -e "${GREEN}✅ Porta 3000 ativa${NC}"
else
    echo -e "${YELLOW}⚠️  Porta 3000 não detectada${NC}"
fi

# 10. Testar localmente
echo -e "${BLUE}🧪 Testando localmente...${NC}"
sleep 3
if curl -s http://localhost:3000 | grep -q "EcoReport"; then
    echo -e "${GREEN}✅ Aplicação responde${NC}"
else
    echo -e "${YELLOW}⚠️  Aplicação não respondeu como esperado${NC}"
fi

# 11. Configurar Nginx
echo -e "${BLUE}🌐 Configurando Nginx...${NC}"
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

# 12. Ativar site
sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# 13. Testar e recarregar Nginx
if sudo nginx -t; then
    sudo systemctl reload nginx
    echo -e "${GREEN}✅ Nginx configurado${NC}\n"
else
    echo -e "${RED}❌ Erro na configuração Nginx${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 SETUP CONCLUÍDO!${NC}\n"
echo -e "${BLUE}Teste: curl -I http://${DOMAIN}${NC}"

