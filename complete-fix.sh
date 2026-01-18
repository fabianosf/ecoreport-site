#!/bin/bash

# Script Completo: Build + CSS + HTTPS
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 CORREÇÃO COMPLETA: Build + CSS + HTTPS${NC}\n"

APP_DIR="/var/www/ecoreport-site"
DOMAIN="ecoreport.shop"

# 1. Ir para diretório
cd ${APP_DIR}

# 2. Limpar build antigo
echo -e "${BLUE}🧹 Limpando build antigo...${NC}"
rm -rf .next
echo -e "${GREEN}✅ Build antigo removido${NC}\n"

# 3. Fazer build
echo -e "${BLUE}🔨 Fazendo build...${NC}"
npm run build
echo -e "${GREEN}✅ Build concluído${NC}\n"

# 4. Parar PM2
echo -e "${BLUE}🛑 Parando PM2...${NC}"
pm2 delete ecoreport-site 2>/dev/null || true
sleep 2

# 5. Iniciar PM2 novamente
echo -e "${BLUE}🚀 Reiniciando PM2...${NC}"
pm2 start npm --name ecoreport-site -- start
pm2 save
sleep 5
echo -e "${GREEN}✅ PM2 reiniciado${NC}\n"

# 6. Verificar se está rodando
if pm2 list | grep -q "ecoreport-site.*online"; then
    echo -e "${GREEN}✅ PM2 está rodando${NC}"
else
    echo -e "${RED}❌ PM2 não está rodando! Verificando logs...${NC}"
    pm2 logs ecoreport-site --lines 20 --nostream
    exit 1
fi

# 7. Testar localhost
echo -e "${BLUE}🧪 Testando localhost:3000...${NC}"
sleep 3
curl -I http://localhost:3000 2>&1 | head -5
echo ""

# 8. Atualizar configuração Nginx para suportar assets estáticos
echo -e "${BLUE}🌐 Atualizando configuração Nginx para assets...${NC}"
sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${DOMAIN} www.${DOMAIN} _;

    # Cache para assets estáticos
    location /_next/static {
        proxy_pass http://localhost:3000;
        proxy_cache_valid 200 60m;
        add_header Cache-Control "public, immutable";
        expires 1y;
    }

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

    # Health check
    location /api/health {
        proxy_pass http://localhost:3000;
        access_log off;
    }
}
NGINXEOF

# 9. Recarregar Nginx
echo -e "${BLUE}🔄 Recarregando Nginx...${NC}"
sudo nginx -t && sudo systemctl reload nginx
echo -e "${GREEN}✅ Nginx recarregado${NC}\n"

# 10. Instalar Certbot (se não tiver)
if ! command -v certbot &> /dev/null; then
    echo -e "${BLUE}📦 Instalando Certbot...${NC}"
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
    echo -e "${GREEN}✅ Certbot instalado${NC}\n"
else
    echo -e "${GREEN}✅ Certbot já instalado${NC}\n"
fi

# 11. Configurar HTTPS
echo -e "${BLUE}🔒 Configurando HTTPS...${NC}"
echo -e "${YELLOW}⚠️  Certbot vai pedir seu email e perguntar sobre redirecionamento HTTP→HTTPS${NC}"
echo -e "${YELLOW}   Escolha '2' para redirecionar HTTP para HTTPS${NC}\n"

sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --redirect --email admin@${DOMAIN} || {
    echo -e "${YELLOW}⚠️  Certbot precisa de interação manual ou DNS não está configurado${NC}"
    echo -e "${BLUE}   Execute manualmente:${NC}"
    echo -e "   sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}\n"
}

# 12. Verificação final
echo -e "${BLUE}📊 VERIFICAÇÃO FINAL${NC}\n"
echo -e "${GREEN}✅ Status do PM2:${NC}"
pm2 status | head -3

echo -e "\n${GREEN}✅ Teste HTTP:${NC}"
curl -I http://${DOMAIN} 2>&1 | head -3

echo -e "\n${GREEN}✅ Teste HTTPS:${NC}"
curl -I https://${DOMAIN} 2>&1 | head -3 || echo "HTTPS ainda não configurado (precisa de DNS)"

echo -e "\n${GREEN}🎉 CORREÇÃO CONCLUÍDA!${NC}\n"
echo -e "${BLUE}🌐 Acesse: http://${DOMAIN} ou https://${DOMAIN}${NC}\n"
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo -e "   - Se CSS ainda não carregar, limpe cache do navegador (Ctrl+Shift+R)"
echo -e "   - Para HTTPS funcionar, DNS deve apontar para o servidor (92.113.33.16)"
echo -e "   - Execute 'sudo certbot --nginx -d ${DOMAIN}' se HTTPS não foi configurado automaticamente\n"

