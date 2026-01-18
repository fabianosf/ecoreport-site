#!/bin/bash

# Script de Setup do Servidor - EcoReport Site
# Execute este script NO SERVIDOR (92.113.33.16)

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Configurando servidor para EcoReport Site...${NC}\n"

# Variáveis
DOMAIN="ecoreport.shop"
APP_DIR="/var/www/ecoreport-site"
REPO_URL="https://github.com/fabianosf/ecoreport-site.git"
NODE_VERSION="20"

# Verificar se é root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠️  Executando como usuário normal. Alguns comandos podem precisar de sudo.${NC}\n"
fi

# 1. Atualizar sistema
echo -e "${BLUE}📦 Atualizando sistema...${NC}"
sudo apt update && sudo apt upgrade -y

# 2. Instalar Node.js (se não tiver)
if ! command -v node &> /dev/null; then
    echo -e "${BLUE}📦 Instalando Node.js ${NODE_VERSION}...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
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

# 4. Instalar Nginx (se não tiver)
if ! command -v nginx &> /dev/null; then
    echo -e "${BLUE}📦 Instalando Nginx...${NC}"
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
else
    echo -e "${GREEN}✅ Nginx já instalado${NC}"
fi

# 5. Criar diretório da aplicação
echo -e "${BLUE}📁 Criando diretório da aplicação...${NC}"
sudo mkdir -p ${APP_DIR}
sudo chown -R $USER:$USER ${APP_DIR}

# 6. Clonar repositório (se não existir)
if [ ! -d "${APP_DIR}/.git" ]; then
    echo -e "${BLUE}📥 Clonando repositório...${NC}"
    cd /var/www
    sudo git clone ${REPO_URL} ecoreport-site
    sudo chown -R $USER:$USER ${APP_DIR}
else
    echo -e "${GREEN}✅ Repositório já existe${NC}"
fi

# 7. Instalar dependências
echo -e "${BLUE}📦 Instalando dependências...${NC}"
cd ${APP_DIR}
npm install --production

# 8. Criar .env.local (se não existir)
if [ ! -f "${APP_DIR}/.env.local" ]; then
    echo -e "${YELLOW}⚠️  Criando .env.local...${NC}"
    cat > ${APP_DIR}/.env.local << 'ENVEOF'
# Google Analytics 4
NEXT_PUBLIC_GA_ID=G-FY0M95V3SN

# Site Configuration
NEXT_PUBLIC_SITE_URL=https://ecoreport.shop
GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID/exec
NODE_ENV=production
ENVEOF
    echo -e "${YELLOW}⚠️  IMPORTANTE: Edite .env.local e adicione GOOGLE_WEBHOOK_URL real!${NC}"
fi

# 9. Build da aplicação
echo -e "${BLUE}🔨 Fazendo build...${NC}"
npm run build

# 10. Configurar PM2
echo -e "${BLUE}⚙️  Configurando PM2...${NC}"
pm2 delete ecoreport-site 2>/dev/null || true
pm2 start npm --name ecoreport-site -- start
pm2 save

# 11. Configurar Nginx
echo -e "${BLUE}🌐 Configurando Nginx...${NC}"
sudo tee /etc/nginx/sites-available/ecoreport.shop > /dev/null << 'NGINXEOF'
server {
    listen 80;
    server_name ecoreport.shop www.ecoreport.shop;

    # Redirect HTTP to HTTPS (será ativado após SSL)
    # return 301 https://$server_name$request_uri;

    # Por enquanto, proxy para Next.js
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
sudo nginx -t && sudo systemctl reload nginx

echo -e "${GREEN}✅ Nginx configurado!${NC}\n"

# 12. Instalar Certbot para SSL
if ! command -v certbot &> /dev/null; then
    echo -e "${BLUE}🔒 Instalando Certbot para SSL...${NC}"
    sudo apt install -y certbot python3-certbot-nginx
else
    echo -e "${GREEN}✅ Certbot já instalado${NC}"
fi

# 13. Instruções finais
echo -e "\n${GREEN}✅ Setup do servidor concluído!${NC}\n"
echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}\n"
echo -e "${YELLOW}1. Configure DNS:${NC}"
echo -e "   A record: ecoreport.shop → 92.113.33.16"
echo -e "   A record: www.ecoreport.shop → 92.113.33.16\n"

echo -e "${YELLOW}2. Configure SSL (HTTPS):${NC}"
echo -e "   sudo certbot --nginx -d ecoreport.shop -d www.ecoreport.shop\n"

echo -e "${YELLOW}3. Edite .env.local:${NC}"
echo -e "   nano ${APP_DIR}/.env.local"
echo -e "   Adicione GOOGLE_WEBHOOK_URL real\n"

echo -e "${YELLOW}4. Reinicie a aplicação:${NC}"
echo -e "   pm2 restart ecoreport-site\n"

echo -e "${GREEN}🎉 Servidor configurado!${NC}"

