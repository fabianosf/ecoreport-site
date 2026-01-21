#!/bin/bash

# Script para configurar domínio ecoreport.shop corretamente
# Execute este script NO SERVIDOR

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOMAIN="ecoreport.shop"
IP="92.113.33.16"

echo -e "${BLUE}🔧 Configurando domínio ${DOMAIN}...${NC}\n"

# 1. Verificar DNS
echo -e "${BLUE}🔍 Verificando DNS...${NC}"
DNS_IP=$(dig +short ${DOMAIN} @8.8.8.8 2>/dev/null | tail -1 || echo "")
if [ -n "$DNS_IP" ]; then
    if [ "$DNS_IP" = "$IP" ]; then
        echo -e "${GREEN}✅ DNS configurado corretamente: ${DOMAIN} → ${IP}${NC}"
    else
        echo -e "${YELLOW}⚠️  DNS aponta para IP diferente: ${DOMAIN} → ${DNS_IP} (esperado: ${IP})${NC}"
        echo -e "${YELLOW}   Configure o DNS no seu provedor de domínio${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  DNS não encontrado ou não propagado ainda${NC}"
    echo -e "${YELLOW}   Configure o DNS: ${DOMAIN} → ${IP}${NC}"
fi
echo ""

# 2. Verificar sites ativos no Nginx
echo -e "${BLUE}📋 Sites ativos no Nginx:${NC}"
ls -la /etc/nginx/sites-enabled/ | grep -v "^total" | grep -v "^d"
echo ""

# 3. Criar/atualizar configuração do Nginx com prioridade para o domínio
echo -e "${BLUE}🌐 Configurando Nginx para ${DOMAIN}...${NC}"

sudo tee /etc/nginx/sites-available/${DOMAIN} > /dev/null << NGINXEOF
# Configuração principal para ecoreport.shop
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

# 4. Ativar site (garantir que está ativo)
echo -e "${BLUE}🔗 Ativando site...${NC}"
sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/${DOMAIN}

# 5. Verificar se há outros sites conflitantes
echo -e "${BLUE}🔍 Verificando conflitos...${NC}"
CONFLICTING_SITES=$(ls /etc/nginx/sites-enabled/ | grep -v "${DOMAIN}" | grep -v "^$" || true)
if [ -n "$CONFLICTING_SITES" ]; then
    echo -e "${YELLOW}⚠️  Outros sites encontrados:${NC}"
    for site in $CONFLICTING_SITES; do
        echo -e "   - $site"
        # Verificar se tem default_server
        if sudo grep -q "default_server" /etc/nginx/sites-enabled/$site 2>/dev/null; then
            echo -e "     ${YELLOW}⚠️  Este site tem default_server, pode causar conflito${NC}"
        fi
    done
    echo ""
fi

# 6. Remover default_server de outros sites (opcional, mas recomendado)
echo -e "${BLUE}🔧 Removendo default_server de outros sites...${NC}"
for site_file in /etc/nginx/sites-enabled/*; do
    if [ -f "$site_file" ] && [[ "$site_file" != *"${DOMAIN}"* ]]; then
        site_name=$(basename "$site_file")
        echo -e "${YELLOW}   Verificando: $site_name${NC}"
        # Remover default_server se existir
        sudo sed -i 's/ listen 80 default_server;/ listen 80;/g' "$site_file" 2>/dev/null || true
        sudo sed -i 's/ listen \[::\]:80 default_server;/ listen [::]:80;/g' "$site_file" 2>/dev/null || true
    fi
done

# 7. Adicionar default_server ao ecoreport.shop (para garantir que funcione via IP)
echo -e "${BLUE}🔧 Adicionando default_server ao ${DOMAIN}...${NC}"
sudo sed -i 's/ listen 80;/ listen 80 default_server;/g' /etc/nginx/sites-available/${DOMAIN}
sudo sed -i 's/ listen \[::\]:80;/ listen [::]:80 default_server;/g' /etc/nginx/sites-available/${DOMAIN}

# Recriar link simbólico
sudo ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/${DOMAIN}

# 8. Testar configuração
echo -e "\n${BLUE}🧪 Testando configuração do Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✅ Configuração do Nginx está correta${NC}"
else
    echo -e "${RED}❌ Erro na configuração do Nginx!${NC}"
    sudo nginx -t
    exit 1
fi

# 9. Recarregar Nginx
echo -e "\n${BLUE}🔄 Recarregando Nginx...${NC}"
sudo systemctl reload nginx

# 10. Aguardar
sleep 3

# 11. Testes
echo -e "\n${BLUE}🧪 Testando acesso...${NC}\n"

echo -e "${GREEN}1. Teste via IP (${IP}):${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${IP} 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${IP} - Status: ${HTTP_CODE}"
else
    echo -e "   ⚠️  http://${IP} - Status: ${HTTP_CODE}"
fi

echo -e "\n${GREEN}2. Teste via domínio (${DOMAIN}):${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: ${DOMAIN}" http://${IP} 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "   ✅ http://${DOMAIN} (via Host header) - Status: ${HTTP_CODE}"
else
    echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
fi

# Teste real do domínio (se DNS estiver configurado)
if [ -n "$DNS_IP" ] && [ "$DNS_IP" = "$IP" ]; then
    echo -e "\n${GREEN}3. Teste direto do domínio:${NC}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://${DOMAIN} 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "   ✅ http://${DOMAIN} - Status: ${HTTP_CODE}"
    else
        echo -e "   ⚠️  http://${DOMAIN} - Status: ${HTTP_CODE}"
        echo -e "   ${YELLOW}   Pode estar aguardando propagação DNS${NC}"
    fi
fi

# 12. Verificar logs
echo -e "\n${BLUE}📋 Últimas linhas do log de erro (se houver):${NC}"
sudo tail -5 /var/log/nginx/ecoreport-error.log 2>/dev/null || echo "Nenhum erro recente"

# 13. Resumo
echo -e "\n${GREEN}✅ Configuração concluída!${NC}\n"
echo -e "${BLUE}📋 Configuração aplicada:${NC}"
echo -e "   - Domínio: ${DOMAIN}"
echo -e "   - www.${DOMAIN}"
echo -e "   - IP: ${IP}"
echo -e "   - default_server: SIM (aceita requisições sem Host header)\n"

echo -e "${YELLOW}📝 IMPORTANTE - Configure DNS:${NC}"
echo -e "   No seu provedor de domínio, configure:"
echo -e "   - Tipo: A"
echo -e "   - Nome: ${DOMAIN}"
echo -e "   - Valor: ${IP}"
echo -e "   - TTL: 3600 (ou padrão)\n"
echo -e "   E também:"
echo -e "   - Tipo: A"
echo -e "   - Nome: www.${DOMAIN}"
echo -e "   - Valor: ${IP}\n"

echo -e "${BLUE}🔍 Para verificar DNS:${NC}"
echo -e "   dig ${DOMAIN} @8.8.8.8"
echo -e "   nslookup ${DOMAIN}\n"

echo -e "${GREEN}🎉 Configuração do domínio concluída!${NC}"
