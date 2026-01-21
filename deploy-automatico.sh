#!/bin/bash

# Script de Deploy Automático - EcoReport Site
# Execute este script NO SERVIDOR após conectar via SSH

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variáveis
APP_DIR="/var/www/ecoreport-site"
REPO_URL="https://github.com/fabianosf/ecoreport-site.git"
# GITHUB_TOKEN será solicitado ou pode ser definido como variável de ambiente
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

echo -e "${BLUE}🚀 Iniciando deploy automático do EcoReport Site...${NC}\n"

# Verificar se Node.js está instalado
if ! command -v node &> /dev/null; then
    echo -e "${BLUE}📦 Instalando Node.js 20...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo -e "${GREEN}✅ Node.js já instalado: $(node --version)${NC}"
fi

# Verificar se PM2 está instalado
if ! command -v pm2 &> /dev/null; then
    echo -e "${BLUE}📦 Instalando PM2...${NC}"
    sudo npm install -g pm2
    pm2 startup
else
    echo -e "${GREEN}✅ PM2 já instalado${NC}"
fi

# Verificar se Nginx está instalado
if ! command -v nginx &> /dev/null; then
    echo -e "${BLUE}📦 Instalando Nginx...${NC}"
    sudo apt update
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
else
    echo -e "${GREEN}✅ Nginx já instalado${NC}"
fi

# Criar diretório se não existir
echo -e "${BLUE}📁 Configurando diretório da aplicação...${NC}"
sudo mkdir -p ${APP_DIR}
sudo chown -R $USER:$USER ${APP_DIR}

# Clonar ou atualizar repositório
if [ ! -d "${APP_DIR}/.git" ]; then
    echo -e "${BLUE}📥 Clonando repositório...${NC}"
    cd /var/www
    sudo rm -rf ecoreport-site 2>/dev/null || true
    # Clonar repositório (será solicitada senha se necessário)
    if [ -n "${GITHUB_TOKEN}" ]; then
        git clone https://${GITHUB_TOKEN}@github.com/fabianosf/ecoreport-site.git ecoreport-site
    else
        git clone ${REPO_URL} ecoreport-site
    fi
    sudo chown -R $USER:$USER ${APP_DIR}
else
    echo -e "${BLUE}🔄 Atualizando repositório...${NC}"
    cd ${APP_DIR}
    # Atualizar repositório
    if [ -n "${GITHUB_TOKEN}" ]; then
        git remote set-url origin https://${GITHUB_TOKEN}@github.com/fabianosf/ecoreport-site.git
    fi
    git pull origin main || {
        echo -e "${YELLOW}⚠️  Tentando reset hard...${NC}"
        git fetch origin main
        git reset --hard origin/main
    }
fi

cd ${APP_DIR}

# Criar .env.local se não existir
if [ ! -f ".env.local" ]; then
    echo -e "${BLUE}📝 Criando .env.local...${NC}"
    cat > .env.local << 'ENVEOF'
# Google Analytics 4
NEXT_PUBLIC_GA_ID=G-FY0M95V3SN

# Site Configuration
NEXT_PUBLIC_SITE_URL=https://ecoreport.shop
GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID/exec
NODE_ENV=production
ENVEOF
    echo -e "${YELLOW}⚠️  IMPORTANTE: Edite .env.local e adicione GOOGLE_WEBHOOK_URL real!${NC}"
fi

# Instalar dependências (incluindo devDependencies para build)
echo -e "${BLUE}📦 Instalando dependências...${NC}"
npm install

# Build
echo -e "${BLUE}🔨 Fazendo build...${NC}"
npm run build

# Configurar PM2
echo -e "${BLUE}⚙️  Configurando PM2...${NC}"
pm2 delete ecoreport-site 2>/dev/null || true
pm2 start npm --name ecoreport-site -- start
pm2 save

# Configurar Nginx
echo -e "${BLUE}🌐 Configurando Nginx...${NC}"
sudo tee /etc/nginx/sites-available/ecoreport.shop > /dev/null << 'NGINXEOF'
server {
    listen 80;
    server_name ecoreport.shop www.ecoreport.shop;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINXEOF

# Ativar site
sudo ln -sf /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo nginx -t && sudo systemctl reload nginx

echo -e "\n${GREEN}✅ Deploy concluído com sucesso!${NC}\n"
echo -e "${BLUE}📊 Status PM2:${NC}"
pm2 status

echo -e "\n${YELLOW}📝 Próximos passos:${NC}"
echo -e "   1. Configure DNS: ecoreport.shop → 92.113.33.16"
echo -e "   2. Configure SSL: sudo certbot --nginx -d ecoreport.shop -d www.ecoreport.shop"
echo -e "   3. Edite .env.local para adicionar GOOGLE_WEBHOOK_URL real"
echo -e "\n${GREEN}🌐 Acesse: http://92.113.33.16${NC}"
