#!/bin/bash

# Script para finalizar o deploy - EcoReport Site
# Execute este script NO SERVIDOR após o build bem-sucedido

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_DIR="/var/www/ecoreport-site"

echo -e "${BLUE}🚀 Finalizando deploy do EcoReport Site...${NC}\n"

cd ${APP_DIR}

# 1. Verificar se PM2 está instalado
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}📦 Instalando PM2...${NC}"
    sudo npm install -g pm2
    pm2 startup
else
    echo -e "${GREEN}✅ PM2 já instalado${NC}"
fi

# 2. Parar aplicação existente (se houver)
pm2 delete ecoreport-site 2>/dev/null || true

# 3. Iniciar aplicação com PM2
echo -e "${BLUE}⚙️  Iniciando aplicação com PM2...${NC}"
pm2 start npm --name ecoreport-site -- start
pm2 save

# 4. Verificar status
echo -e "\n${GREEN}📊 Status da aplicação:${NC}"
pm2 status

# 5. Verificar se está respondendo
echo -e "\n${BLUE}🔍 Verificando se a aplicação está respondendo...${NC}"
sleep 2
if curl -s http://localhost:3000 > /dev/null; then
    echo -e "${GREEN}✅ Aplicação respondendo em http://localhost:3000${NC}"
else
    echo -e "${YELLOW}⚠️  Aplicação ainda não está respondendo. Verifique os logs:${NC}"
    echo -e "   pm2 logs ecoreport-site"
fi

# 6. Configurar Nginx (se não estiver configurado)
if [ ! -f "/etc/nginx/sites-available/ecoreport.shop" ]; then
    echo -e "\n${BLUE}🌐 Configurando Nginx...${NC}"
    
    # Verificar se Nginx está instalado
    if ! command -v nginx &> /dev/null; then
        echo -e "${YELLOW}📦 Instalando Nginx...${NC}"
        sudo apt update
        sudo apt install -y nginx
        sudo systemctl enable nginx
        sudo systemctl start nginx
    fi
    
    # Criar configuração Nginx
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
    echo -e "${GREEN}✅ Nginx configurado!${NC}"
else
    echo -e "${GREEN}✅ Nginx já configurado${NC}"
    sudo nginx -t && sudo systemctl reload nginx
fi

# 7. Resumo final
echo -e "\n${GREEN}✅ Deploy finalizado com sucesso!${NC}\n"
echo -e "${BLUE}📋 Informações:${NC}"
echo -e "   - Aplicação rodando em: http://localhost:3000"
echo -e "   - Acesse via IP: http://92.113.33.16"
echo -e "   - Acesse via domínio: http://ecoreport.shop (após configurar DNS)\n"

echo -e "${YELLOW}📝 Próximos passos:${NC}"
echo -e "   1. Configure DNS: ecoreport.shop → 92.113.33.16"
echo -e "   2. Configure SSL: sudo certbot --nginx -d ecoreport.shop -d www.ecoreport.shop"
echo -e "   3. Verifique logs: pm2 logs ecoreport-site\n"

echo -e "${GREEN}🎉 Site no ar!${NC}"
