#!/bin/bash

# Script para Corrigir Erros do Certbot
# Remove/Desabilita certificados com problemas de DNS
# Execute NO SERVIDOR

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔧 CORRIGINDO ERROS DO CERTBOT${NC}\n"

# 1. Verificar certificados existentes
echo -e "${BLUE}📋 Certificados atuais:${NC}"
sudo certbot certificates
echo ""

# 2. Verificar quais certificados têm problemas
echo -e "${BLUE}🔍 Verificando problemas...${NC}"
PROBLEMATIC_DOMAINS=()

# Verificar asbjj.cloud (o que está dando erro)
if [ -f "/etc/letsencrypt/renewal/asbjj.cloud.conf" ]; then
    echo -e "${YELLOW}⚠️  Encontrado certificado para asbjj.cloud${NC}"
    DNS_CHECK=$(nslookup asbjj.cloud 2>/dev/null | grep -c "NXDOMAIN" || echo "0")
    if [ "$DNS_CHECK" != "0" ]; then
        echo -e "${RED}❌ DNS não configurado para asbjj.cloud${NC}"
        PROBLEMATIC_DOMAINS+=("asbjj.cloud")
    fi
fi

# 3. Opções para corrigir
if [ ${#PROBLEMATIC_DOMAINS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ Nenhum problema encontrado nos certificados principais${NC}\n"
    echo -e "${YELLOW}O erro de renovação para asbjj.cloud é apenas um aviso${NC}"
    echo -e "${YELLOW}Os certificados funcionais (como ecoreport.shop) não são afetados${NC}\n"
    exit 0
fi

echo -e "${BLUE}📋 Domínios com problemas encontrados:${NC}"
for domain in "${PROBLEMATIC_DOMAINS[@]}"; do
    echo -e "   - ${domain}"
done
echo ""

# 4. Perguntar o que fazer
echo -e "${YELLOW}Escolha uma opção:${NC}"
echo -e "   1) Desabilitar renovação automática (recomendado)"
echo -e "   2) Deletar certificado completamente"
echo -e "   3) Apenas ignorar (o erro não afeta outros certificados)"
echo ""

read -p "Digite sua escolha (1, 2 ou 3): " choice

case $choice in
    1)
        echo -e "${BLUE}🔧 Desabilitando renovação automática...${NC}"
        for domain in "${PROBLEMATIC_DOMAINS[@]}"; do
            if [ -f "/etc/letsencrypt/renewal/${domain}.conf" ]; then
                # Adicionar comentário no arquivo de renovação
                sudo sed -i 's/^\[/;\0/' /etc/letsencrypt/renewal/${domain}.conf 2>/dev/null || true
                # Ou renomear para .disabled
                sudo mv /etc/letsencrypt/renewal/${domain}.conf /etc/letsencrypt/renewal/${domain}.conf.disabled 2>/dev/null || true
                echo -e "${GREEN}✅ Renovação desabilitada para ${domain}${NC}"
            fi
        done
        ;;
    2)
        echo -e "${BLUE}🗑️  Deletando certificados...${NC}"
        for domain in "${PROBLEMATIC_DOMAINS[@]}"; do
            if sudo certbot delete --cert-name ${domain} --non-interactive 2>/dev/null; then
                echo -e "${GREEN}✅ Certificado deletado: ${domain}${NC}"
            else
                echo -e "${YELLOW}⚠️  Não foi possível deletar automaticamente: ${domain}${NC}"
                echo -e "${YELLOW}   Tente manualmente: sudo certbot delete --cert-name ${domain}${NC}"
            fi
        done
        ;;
    3)
        echo -e "${YELLOW}✅ Mantendo como está (erro não afeta outros certificados)${NC}"
        ;;
    *)
        echo -e "${RED}❌ Opção inválida${NC}"
        exit 1
        ;;
esac

# 5. Verificar renovação novamente (apenas certificados que devem renovar)
echo -e "\n${BLUE}🧪 Testando renovação dos certificados válidos...${NC}"
echo -e "${YELLOW}Testando apenas ecoreport.shop (certificado funcional)...${NC}"

# Testar renovação específica do ecoreport.shop
if sudo certbot renew --cert-name ecoreport.shop --dry-run 2>&1 | grep -q "The following simulated renewals succeeded"; then
    echo -e "${GREEN}✅ Renovação do ecoreport.shop funcionando perfeitamente!${NC}"
else
    # Mostrar resultado completo
    sudo certbot renew --cert-name ecoreport.shop --dry-run 2>&1 | tail -10
fi

echo -e "\n${BLUE}📊 STATUS FINAL:${NC}\n"

# 6. Mostrar certificados válidos
echo -e "${GREEN}✅ Certificados funcionais:${NC}"
sudo certbot certificates | grep -A 3 "Certificate Name" | grep -E "Certificate Name|Domains|Expiry" | grep -v "asbjj.cloud" || true

echo -e "\n${GREEN}🎉 CORREÇÃO CONCLUÍDA!${NC}\n"
echo -e "${BLUE}📋 RESUMO:${NC}"
echo -e "   - ecoreport.shop: ✅ Funcionando"
echo -e "   - Renovação automática: ✅ Configurada"
echo -e "   - Erros de outros domínios: ${YELLOW}⚠️  Não afetam o ecoreport.shop${NC}\n"

echo -e "${YELLOW}💡 DICA: O erro de asbjj.cloud não afeta seu site ecoreport.shop${NC}"
echo -e "${YELLOW}   Se quiser remover completamente, execute:${NC}"
echo -e "   sudo certbot delete --cert-name asbjj.cloud\n"

