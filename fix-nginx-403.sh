#!/bin/bash

# Script para corrigir erro 403 Forbidden no Nginx
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 Corrigindo erro 403 Forbidden no Nginx...${NC}\n"

# 1. Verificar configuração atual
echo -e "${BLUE}📋 Verificando configurações do Nginx...${NC}"
ls -la /etc/nginx/sites-enabled/

# 2. Verificar se a aplicação está rodando
echo -e "\n${BLUE}🔍 Verificando se a aplicação está rodando...${NC}"
if curl -s http://localhost:3000 > /dev/null; then
    echo -e "${GREEN}✅ Aplicação respondendo em localhost:3000${NC}"
else
    echo -e "${RED}❌ Aplicação não está respondendo em localhost:3000${NC}"
    echo -e "${YELLOW}   Verifique: pm2 status${NC}"
    exit 1
fi

# 3. Criar/atualizar configuração do Nginx para ecoreport.shop
echo -e "\n${BLUE}🌐 Configurando Nginx para ecoreport.shop...${NC}"

sudo tee /etc/nginx/sites-available/ecoreport.shop > /dev/null << 'NGINXEOF'
server {
    listen 80;
    server_name ecoreport.shop www.ecoreport.shop 92.113.33.16;

    # Logs
    access_log /var/log/nginx/ecoreport-access.log;
    error_log /var/log/nginx/ecoreport-error.log;

    # Proxy para Next.js
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
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check
    location /api/health {
        proxy_pass http://localhost:3000;
        access_log off;
    }
}
NGINXEOF

# 4. Ativar site
echo -e "${BLUE}🔗 Ativando site...${NC}"
sudo ln -sf /etc/nginx/sites-available/ecoreport.shop /etc/nginx/sites-enabled/

# 5. Remover configurações conflitantes (opcional - comentado para segurança)
# sudo rm -f /etc/nginx/sites-enabled/default

# 6. Verificar configuração
echo -e "\n${BLUE}✅ Verificando configuração do Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuração do Nginx está correta${NC}"
else
    echo -e "${RED}❌ Erro na configuração do Nginx${NC}"
    exit 1
fi

# 7. Recarregar Nginx
echo -e "\n${BLUE}🔄 Recarregando Nginx...${NC}"
sudo systemctl reload nginx

# 8. Verificar status
echo -e "\n${BLUE}📊 Status do Nginx:${NC}"
sudo systemctl status nginx --no-pager -l | head -10

# 9. Testar acesso
echo -e "\n${BLUE}🧪 Testando acesso...${NC}"
sleep 2

if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ Site acessível via localhost${NC}"
elif curl -s -o /dev/null -w "%{http_code}" http://92.113.33.16 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ Site acessível via IP${NC}"
else
    echo -e "${YELLOW}⚠️  Verifique os logs do Nginx:${NC}"
    echo -e "   sudo tail -f /var/log/nginx/ecoreport-error.log"
    echo -e "   sudo tail -f /var/log/nginx/error.log"
fi

# 10. Mostrar informações
echo -e "\n${GREEN}✅ Correção aplicada!${NC}\n"
echo -e "${BLUE}📋 Informações:${NC}"
echo -e "   - Aplicação: http://localhost:3000"
echo -e "   - Site: http://92.113.33.16"
echo -e "   - Logs: /var/log/nginx/ecoreport-*.log\n"

echo -e "${YELLOW}📝 Se ainda houver problemas:${NC}"
echo -e "   1. Verifique logs: sudo tail -f /var/log/nginx/ecoreport-error.log"
echo -e "   2. Verifique PM2: pm2 logs ecoreport-site"
echo -e "   3. Verifique firewall: sudo ufw status\n"
