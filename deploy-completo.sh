#!/bin/bash

# Script de Deploy Completo - EcoReport Site
# Servidor: 92.113.33.16
# Usuário: fabianosf

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Variáveis
SERVER_IP="92.113.33.16"
SERVER_USER="fabianosf"
SERVER_PASS="${SERVER_PASS:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
APP_DIR="/var/www/ecoreport-site"
REPO_URL="https://github.com/fabianosf/ecoreport-site.git"

echo -e "${BLUE}🚀 Iniciando deploy completo do EcoReport Site...${NC}\n"

# 1. Build local
echo -e "${BLUE}📦 Fazendo build local...${NC}"
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erro no build! Corrija os erros antes de fazer deploy.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build local concluído!${NC}\n"

# 2. Verificar se sshpass está instalado (se senha fornecida)
if [ -n "${SERVER_PASS}" ]; then
    if ! command -v sshpass &> /dev/null; then
        echo -e "${YELLOW}⚠️  sshpass não encontrado. Instalando...${NC}"
        sudo apt-get update && sudo apt-get install -y sshpass
    fi
    SSH_CMD="sshpass -p '${SERVER_PASS}' ssh"
else
    SSH_CMD="ssh"
    echo -e "${YELLOW}⚠️  SERVER_PASS não definido. Você precisará digitar a senha manualmente.${NC}"
fi

# 3. Deploy no servidor
echo -e "${BLUE}📤 Conectando ao servidor e fazendo deploy...${NC}\n"

${SSH_CMD} -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} << ENDSSH
set -e

echo "🔍 Verificando setup do servidor..."

# Verificar se Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "📦 Instalando Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo "✅ Node.js já instalado: \$(node --version)"
fi

# Verificar se PM2 está instalado
if ! command -v pm2 &> /dev/null; then
    echo "📦 Instalando PM2..."
    sudo npm install -g pm2
    pm2 startup
else
    echo "✅ PM2 já instalado"
fi

# Verificar se Nginx está instalado
if ! command -v nginx &> /dev/null; then
    echo "📦 Instalando Nginx..."
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
else
    echo "✅ Nginx já instalado"
fi

# Criar diretório se não existir
sudo mkdir -p ${APP_DIR}
sudo chown -R ${SERVER_USER}:${SERVER_USER} ${APP_DIR}

# Clonar ou atualizar repositório
if [ ! -d "${APP_DIR}/.git" ]; then
    echo "📥 Clonando repositório..."
    cd /var/www
    sudo rm -rf ecoreport-site
    sudo git clone ${REPO_URL} ecoreport-site
    sudo chown -R ${SERVER_USER}:${SERVER_USER} ${APP_DIR}
else
    echo "🔄 Atualizando repositório..."
    cd ${APP_DIR}
    if [ -n "${GITHUB_TOKEN}" ]; then
        git remote set-url origin https://${GITHUB_TOKEN}@github.com/fabianosf/ecoreport-site.git
    fi
    git pull origin main || git fetch origin main && git reset --hard origin/main
fi

cd ${APP_DIR}

# Criar .env.local se não existir
if [ ! -f ".env.local" ]; then
    echo "📝 Criando .env.local..."
    cat > .env.local << 'ENVEOF'
# Google Analytics 4
NEXT_PUBLIC_GA_ID=G-FY0M95V3SN

# Site Configuration
NEXT_PUBLIC_SITE_URL=https://ecoreport.shop
GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID/exec
NODE_ENV=production
ENVEOF
    echo "⚠️  IMPORTANTE: Edite .env.local e adicione GOOGLE_WEBHOOK_URL real!"
fi

# Instalar dependências
echo "📦 Instalando dependências..."
    npm install

# Build
echo "🔨 Fazendo build..."
npm run build

# Configurar PM2
echo "⚙️  Configurando PM2..."
pm2 delete ecoreport-site 2>/dev/null || true
pm2 start npm --name ecoreport-site -- start
pm2 save

# Configurar Nginx
echo "🌐 Configurando Nginx..."
sudo tee /etc/nginx/sites-available/ecoreport.shop > /dev/null << 'NGINXEOF'
server {
    listen 80;
    server_name ecoreport.shop www.ecoreport.shop;

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

# Ativar site
sudo ln -sf /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Deploy concluído no servidor!"
echo "📊 Status PM2:"
pm2 status

ENDSSH

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ Deploy completo concluído com sucesso!${NC}\n"
    echo -e "${BLUE}🌐 Acesse: http://92.113.33.16 ou http://ecoreport.shop${NC}"
    echo -e "${YELLOW}📝 Próximos passos:${NC}"
    echo -e "   1. Configure DNS: ecoreport.shop → 92.113.33.16"
    echo -e "   2. Configure SSL: sudo certbot --nginx -d ecoreport.shop -d www.ecoreport.shop"
    echo -e "   3. Edite .env.local no servidor para adicionar GOOGLE_WEBHOOK_URL"
else
    echo -e "\n${RED}❌ Erro durante o deploy!${NC}"
    exit 1
fi
