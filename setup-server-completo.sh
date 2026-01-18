#!/bin/bash

# Script Completo de Setup do Servidor - EcoReport Site
# Execute este script NO SERVIDOR (92.113.33.16)
# Este script FAZ TUDO: clona, instala, faz build, configura e inicia

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 SETUP COMPLETO - EcoReport Site${NC}\n"

# Variáveis
DOMAIN="ecoreport.shop"
APP_DIR="/var/www/ecoreport-site"
REPO_URL="https://github.com/fabianosf/ecoreport-site.git"
NODE_VERSION="20"

# 1. Atualizar sistema
echo -e "${BLUE}📦 Atualizando sistema...${NC}"
sudo apt update -y
sudo apt upgrade -y

# 2. Instalar Node.js 20 (se não tiver)
if ! command -v node &> /dev/null; then
    echo -e "${BLUE}📦 Instalando Node.js ${NODE_VERSION}...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
    sudo apt install -y nodejs
else
    NODE_VER=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    echo -e "${GREEN}✅ Node.js já instalado: $(node --version)${NC}"
    if [ "$NODE_VER" -lt "18" ]; then
        echo -e "${YELLOW}⚠️  Versão do Node.js muito antiga. Atualizando...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash -
        sudo apt install -y nodejs
    fi
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

# 6. Clonar ou atualizar repositório
cd /var/www
if [ ! -d "${APP_DIR}/.git" ]; then
    echo -e "${BLUE}📥 Clonando repositório...${NC}"
    if [ -d "ecoreport-site" ]; then
        sudo rm -rf ecoreport-site
    fi
    git clone ${REPO_URL} ecoreport-site
    sudo chown -R $USER:$USER ${APP_DIR}
else
    echo -e "${BLUE}📥 Atualizando repositório...${NC}"
    cd ${APP_DIR}
    git pull origin main || true
fi

# 7. Entrar no diretório
cd ${APP_DIR}
pwd

# 8. Instalar dependências
echo -e "${BLUE}📦 Instalando dependências...${NC}"
npm install --production=false

# 9. Criar .env.local (se não existir)
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
else
    echo -e "${GREEN}✅ .env.local já existe${NC}"
fi

# 10. Build da aplicação
echo -e "${BLUE}🔨 Fazendo build da aplicação...${NC}"
cd ${APP_DIR}
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erro no build! Verifique os logs acima.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build concluído com sucesso!${NC}"

# 11. Parar aplicação existente (se houver)
echo -e "${BLUE}🛑 Parando aplicação existente...${NC}"
pm2 delete ecoreport-site 2>/dev/null || true

# 12. Iniciar aplicação com PM2
echo -e "${BLUE}🚀 Iniciando aplicação com PM2...${NC}"
cd ${APP_DIR}
pm2 start npm --name ecoreport-site -- start
pm2 save

# Aguardar um pouco para a aplicação iniciar
sleep 5

# 13. Verificar se aplicação está rodando
echo -e "${BLUE}🔍 Verificando se aplicação está rodando...${NC}"
if pm2 list | grep -q "ecoreport-site.*online"; then
    echo -e "${GREEN}✅ Aplicação está rodando no PM2${NC}"
else
    echo -e "${RED}❌ Aplicação NÃO está rodando! Verificando logs...${NC}"
    pm2 logs ecoreport-site --lines 20 --nostream
    exit 1
fi

# 14. Verificar porta 3000
echo -e "${BLUE}🔍 Verificando porta 3000...${NC}"
sleep 3
if netstat -tlnp 2>/dev/null | grep -q ":3000" || ss -tlnp 2>/dev/null | grep -q ":3000"; then
    echo -e "${GREEN}✅ Porta 3000 está ativa${NC}"
else
    echo -e "${YELLOW}⚠️  Porta 3000 não está ativa ainda. Aguardando...${NC}"
    sleep 5
    if netstat -tlnp 2>/dev/null | grep -q ":3000" || ss -tlnp 2>/dev/null | grep -q ":3000"; then
        echo -e "${GREEN}✅ Porta 3000 está ativa agora${NC}"
    else
        echo -e "${RED}❌ Porta 3000 ainda não está ativa!${NC}"
        echo -e "${YELLOW}Verificando logs do PM2...${NC}"
        pm2 logs ecoreport-site --lines 30 --nostream
    fi
fi

# 15. Testar aplicação localmente
echo -e "${BLUE}🧪 Testando aplicação localmente...${NC}"
sleep 3
if curl -s http://localhost:3000 | grep -q "EcoReport"; then
    echo -e "${GREEN}✅ Aplicação está respondendo em localhost:3000${NC}"
else
    echo -e "${YELLOW}⚠️  Aplicação não respondeu como esperado. Verificando...${NC}"
    curl -I http://localhost:3000 || echo "Erro ao conectar em localhost:3000"
fi

# 16. Configurar Nginx
echo -e "${BLUE}🌐 Configurando Nginx...${NC}"
sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    # Proxy para Next.js
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
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Cache static files
    location /_next/static {
        proxy_pass http://localhost:3000;
        proxy_cache_valid 200 60m;
        add_header Cache-Control "public, immutable";
    }

    # Health check
    location /api/health {
        proxy_pass http://localhost:3000;
        access_log off;
    }
}
NGINXEOF

# 17. Ativar site no Nginx
echo -e "${BLUE}🔗 Ativando site no Nginx...${NC}"
sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# 18. Testar configuração do Nginx
echo -e "${BLUE}🧪 Testando configuração do Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuração do Nginx está correta${NC}"
else
    echo -e "${RED}❌ Erro na configuração do Nginx!${NC}"
    exit 1
fi

# 19. Recarregar Nginx
echo -e "${BLUE}🔄 Recarregando Nginx...${NC}"
sudo systemctl reload nginx || sudo systemctl restart nginx

# 20. Verificar firewall
echo -e "${BLUE}🔥 Verificando firewall...${NC}"
if command -v ufw &> /dev/null; then
    if sudo ufw status | grep -q "Status: active"; then
        echo -e "${YELLOW}⚠️  Firewall está ativo. Verificando regras...${NC}"
        sudo ufw allow 80/tcp 2>/dev/null || true
        sudo ufw allow 443/tcp 2>/dev/null || true
    fi
fi

# 21. Verificação final
echo -e "\n${BLUE}📊 VERIFICAÇÃO FINAL${NC}\n"

echo -e "${GREEN}✅ Status do PM2:${NC}"
pm2 status

echo -e "\n${GREEN}✅ Status do Nginx:${NC}"
sudo systemctl status nginx --no-pager -l | head -5

echo -e "\n${GREEN}✅ Status da porta 3000:${NC}"
netstat -tlnp 2>/dev/null | grep :3000 || ss -tlnp 2>/dev/null | grep :3000 || echo "Não encontrado"

echo -e "\n${GREEN}✅ Teste local:${NC}"
curl -I http://localhost:3000 2>&1 | head -5

echo -e "\n${GREEN}✅ Teste via Nginx:${NC}"
curl -I http://${DOMAIN} 2>&1 | head -5 || echo "DNS pode não estar configurado ainda"

# 22. Instruções finais
echo -e "\n${GREEN}🎉 SETUP CONCLUÍDO!${NC}\n"

echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}\n"

echo -e "${YELLOW}1. Verificar se DNS está configurado:${NC}"
echo -e "   nslookup ${DOMAIN}"
echo -e "   Deve apontar para: 92.113.33.16\n"

echo -e "${YELLOW}2. Testar acesso ao site:${NC}"
echo -e "   curl -I http://${DOMAIN}\n"

echo -e "${YELLOW}3. Ver logs se houver problemas:${NC}"
echo -e "   pm2 logs ecoreport-site"
echo -e "   sudo tail -f /var/log/nginx/error.log\n"

echo -e "${YELLOW}4. Configurar SSL (após DNS propagar):${NC}"
echo -e "   sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}\n"

echo -e "${GREEN}🌐 Acesse: http://${DOMAIN}${NC}\n"

