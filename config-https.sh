#!/bin/bash

# Script para Configurar HTTPS - EcoReport Site
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔒 CONFIGURANDO HTTPS - EcoReport Site${NC}\n"

DOMAIN="ecoreport.shop"

# 1. Verificar se Certbot está instalado
if ! command -v certbot &> /dev/null; then
    echo -e "${BLUE}📦 Instalando Certbot...${NC}"
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
    echo -e "${GREEN}✅ Certbot instalado${NC}\n"
else
    echo -e "${GREEN}✅ Certbot já instalado${NC}\n"
fi

# 2. Verificar DNS primeiro
echo -e "${BLUE}🔍 Verificando DNS...${NC}"
DNS_IP=$(nslookup ${DOMAIN} 2>/dev/null | grep -A 1 "Name:" | grep "Address:" | awk '{print $2}' | head -1)
SERVER_IP=$(hostname -I | awk '{print $1}')

if [ -z "$DNS_IP" ]; then
    echo -e "${YELLOW}⚠️  DNS não configurado ainda ou não propagado${NC}"
    echo -e "${YELLOW}   Configure DNS primeiro:${NC}"
    echo -e "   A record: ${DOMAIN} → ${SERVER_IP}"
    echo -e "   A record: www.${DOMAIN} → ${SERVER_IP}"
    echo -e "${YELLOW}   Aguarde propagação (algumas horas) antes de configurar HTTPS${NC}\n"
    exit 1
fi

if [ "$DNS_IP" != "$SERVER_IP" ]; then
    echo -e "${YELLOW}⚠️  DNS não aponta para este servidor!${NC}"
    echo -e "   DNS aponta para: ${DNS_IP}"
    echo -e "   Servidor IP: ${SERVER_IP}"
    echo -e "${YELLOW}   Configure DNS para apontar para ${SERVER_IP}${NC}\n"
    exit 1
fi

echo -e "${GREEN}✅ DNS configurado corretamente: ${DNS_IP}${NC}\n"

# 3. Configurar HTTPS com Certbot
echo -e "${BLUE}🔒 Configurando HTTPS com Certbot...${NC}"
echo -e "${YELLOW}Certbot vai pedir:${NC}"
echo -e "   1. Email (digite seu email)"
echo -e "   2. Aceitar termos (digite A e Enter)"
echo -e "   3. Redirecionar HTTP → HTTPS (digite 2)\n"

# Tentar modo não-interativo primeiro (se DNS estiver OK)
if sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --redirect --email admin@${DOMAIN} 2>&1 | tee /tmp/certbot-output.log; then
    echo -e "${GREEN}✅ HTTPS configurado automaticamente!${NC}\n"
else
    echo -e "${YELLOW}⚠️  Certbot precisa de interação manual. Executando modo interativo...${NC}\n"
    sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}
fi

# 4. Verificar certificado
echo -e "${BLUE}🔍 Verificando certificado SSL...${NC}"
if sudo certbot certificates | grep -q "${DOMAIN}"; then
    echo -e "${GREEN}✅ Certificado SSL configurado!${NC}"
    sudo certbot certificates | grep -A 5 "${DOMAIN}"
else
    echo -e "${RED}❌ Certificado SSL não encontrado!${NC}"
fi

# 5. Testar HTTPS
echo -e "\n${BLUE}🧪 Testando HTTPS...${NC}"
sleep 3
curl -I https://${DOMAIN} 2>&1 | head -5 || echo -e "${YELLOW}HTTPS ainda não está funcionando${NC}"

# 6. Verificar renovação automática
echo -e "\n${BLUE}🔄 Testando renovação automática...${NC}"
if sudo certbot renew --dry-run; then
    echo -e "${GREEN}✅ Renovação automática configurada${NC}"
else
    echo -e "${YELLOW}⚠️  Teste de renovação falhou (normal se DNS não estiver configurado)${NC}"
fi

echo -e "\n${GREEN}🎉 HTTPS CONFIGURADO!${NC}\n"
echo -e "${BLUE}🌐 Acesse: https://${DOMAIN}${NC}\n"
echo -e "${YELLOW}⚠️  NOTA: Se HTTPS não funcionou, execute manualmente:${NC}"
echo -e "   sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}\n"

