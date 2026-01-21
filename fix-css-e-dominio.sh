#!/bin/bash

# Script para corrigir CSS e configurar domínio ecoreport.shop
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

APP_DIR="/var/www/ecoreport-site"
DOMAIN="ecoreport.shop"
IP="92.113.33.16"

echo -e "${BLUE}🔧 Corrigindo CSS e configurando domínio...${NC}\n"

cd ${APP_DIR}

# 1. Verificar se .env.local está configurado corretamente
echo -e "${BLUE}📝 Verificando .env.local...${NC}"
if [ ! -f ".env.local" ]; then
    echo -e "${YELLOW}⚠️  Criando .env.local...${NC}"
    cat > .env.local << 'ENVEOF'
# Google Analytics 4
NEXT_PUBLIC_GA_ID=G-FY0M95V3SN

# Site Configuration
NEXT_PUBLIC_SITE_URL=http://ecoreport.shop
GOOGLE_WEBHOOK_URL=https://script.google.com/macros/s/SEU_ID/exec
NODE_ENV=production
ENVEOF
fi

# Atualizar NEXT_PUBLIC_SITE_URL se necessário
if ! grep -q "NEXT_PUBLIC_SITE_URL" .env.local; then
    echo "NEXT_PUBLIC_SITE_URL=http://ecoreport.shop" >> .env.local
fi

# 2. Limpar build antigo
echo -e "\n${BLUE}🧹 Limpando build antigo...${NC}"
rm -rf .next
echo -e "${GREEN}✅ Build antigo removido${NC}"

# 3. Fazer build novamente
echo -e "\n${BLUE}🔨 Fazendo build de produção...${NC}"
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Erro no build!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build concluído com sucesso!${NC}"

# 4. Verificar se arquivos estáticos foram gerados
if [ -d ".next/static" ]; then
    echo -e "${GREEN}✅ Arquivos estáticos gerados${NC}"
else
    echo -e "${RED}❌ Arquivos estáticos não encontrados!${NC}"
    exit 1
fi

# 5. Parar PM2
echo -e "\n${BLUE}🛑 Parando PM2...${NC}"
pm2 delete ecoreport-site 2>/dev/null || true
sleep 2

# 6. Iniciar PM2 novamente
echo -e "${BLUE}🚀 Iniciando PM2...${NC}"
pm2 start npm --name ecoreport-site -- start
pm2 save
sleep 5

# 7. Verificar se está rodando
if pm2 list | grep -q "ecoreport-site.*online"; then
    echo -e "${GREEN}✅ PM2 está rodando${NC}"
else
    echo -e "${RED}❌ PM2 não está rodando!${NC}"
    pm2 logs ecoreport-site --lines 20 --nostream
    exit 1
fi

# 8. Testar localhost
echo -e "\n${BLUE}🧪 Testando localhost:3000...${NC}"
sleep 3
if curl -s http://localhost:3000 | grep -q "EcoReport"; then
    echo -e "${GREEN}✅ Aplicação respondendo${NC}"
else
    echo -e "${YELLOW}⚠️  Aplicação pode não estar respondendo corretamente${NC}"
fi

# 9. Configurar Nginx com suporte completo a arquivos estáticos e domínio
echo -e "\n${BLUE}🌐 Configurando Nginx...${NC}"
sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} www.${DOMAIN} ${IP};

    # Logs
    access_log /var/log/nginx/ecoreport-access.log;
    error_log /var/log/nginx/ecoreport-error.log;

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json application/xml+rss;

    # Arquivos estáticos do Next.js (CSS, JS, imagens)
    location /_next/static {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # Favicon e outros assets
    location ~* \.(ico|png|jpg|jpeg|gif|svg|webp|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # API routes
    location /api {
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

    # Proxy principal para Next.js
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

# 10. Ativar site
echo -e "${BLUE}🔗 Ativando site...${NC}"
sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/

# 11. Testar configuração
echo -e "${BLUE}🧪 Testando configuração do Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuração do Nginx está correta${NC}"
else
    echo -e "${RED}❌ Erro na configuração do Nginx!${NC}"
    exit 1
fi

# 12. Recarregar Nginx
echo -e "${BLUE}🔄 Recarregando Nginx...${NC}"
sudo systemctl reload nginx

# 13. Aguardar e testar
echo -e "\n${BLUE}⏳ Aguardando aplicação inicializar...${NC}"
sleep 5

# 14. Testes finais
echo -e "\n${BLUE}🧪 Testando acesso...${NC}"

echo -e "${GREEN}1. Teste via IP:${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${IP})
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${IP} - Status: ${HTTP_CODE}"
else
    echo -e "   ⚠️  http://${IP} - Status: ${HTTP_CODE}"
fi

echo -e "\n${GREEN}2. Teste via localhost:${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://localhost - Status: ${HTTP_CODE}"
else
    echo -e "   ⚠️  http://localhost - Status: ${HTTP_CODE}"
fi

# 15. Verificar se CSS está sendo servido
echo -e "\n${BLUE}🎨 Verificando arquivos estáticos...${NC}"
STATIC_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/_next/static 2>/dev/null || echo "000")
if [ "$STATIC_CHECK" != "000" ]; then
    echo -e "${GREEN}✅ Arquivos estáticos acessíveis${NC}"
else
    echo -e "${YELLOW}⚠️  Verifique se os arquivos estáticos estão sendo servidos${NC}"
fi

# 16. Resumo final
echo -e "\n${GREEN}✅ Correção concluída!${NC}\n"
echo -e "${BLUE}📋 Informações:${NC}"
echo -e "   - Aplicação: http://localhost:3000"
echo -e "   - Via IP: http://${IP}"
echo -e "   - Via domínio: http://${DOMAIN} (após configurar DNS)\n"

echo -e "${YELLOW}📝 Próximos passos:${NC}"
echo -e "   1. Configure DNS: ${DOMAIN} → ${IP}"
echo -e "   2. Aguarde propagação DNS (algumas horas)"
echo -e "   3. Configure SSL: sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}\n"

echo -e "${BLUE}🔍 Para verificar logs:${NC}"
echo -e "   - PM2: pm2 logs ecoreport-site"
echo -e "   - Nginx: sudo tail -f /var/log/nginx/ecoreport-error.log\n"

echo -e "${GREEN}🎉 Site configurado!${NC}"
