#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Iniciando setup automático...${NC}\n"

# 1. Pedir confirmação
echo -e "${BLUE}Este script vai:${NC}"
echo "1. Abrir Google Sheets para criar uma nova planilha"
echo "2. Você vai criar o Apps Script e pegar a URL"
echo "3. Cole a URL aqui e pronto!"
echo ""
read -p "Continuar? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    exit 1
fi

# 2. Abrir Google Sheets
echo -e "\n${GREEN}✅ Abrindo Google Sheets...${NC}"
open "https://sheets.google.com" || xdg-open "https://sheets.google.com" || start "https://sheets.google.com"

echo -e "\n${BLUE}Siga estes passos:${NC}"
echo "1. Clique em '+ Nova planilha'"
echo "2. Nomeie como: 'EcoReport Signups'"
echo "3. Clique em Extensões → Apps Script"
echo "4. Delete TODO o código e cole isto:"
echo ""
echo "---CÓDIGO PARA COPIAR---"
cat << 'EOF'
function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return ContentService.createTextOutput("Erro: Sem dados").setMimeType(ContentService.MimeType.TEXT);
    }

    const data = JSON.parse(e.postData.contents);
    const sheet = SpreadsheetApp.getActiveSheet();
    
    sheet.appendRow([
      new Date(data.timestamp),
      data.name,
      data.email,
      data.company
    ]);

    return ContentService.createTextOutput("OK").setMimeType(ContentService.MimeType.TEXT);
  } catch (error) {
    return ContentService.createTextOutput("Erro: " + error.message).setMimeType(ContentService.MimeType.TEXT);
  }
}

function doGet(e) {
  return ContentService.createTextOutput("Webhook ativo").setMimeType(ContentService.MimeType.TEXT);
}
EOF

echo -e "\n---FIM DO CÓDIGO---\n"

echo -e "${BLUE}5. Salve (Ctrl+S)${NC}"
echo -e "${BLUE}6. Clique em Implantar → Novo Implantação${NC}"
echo -e "${BLUE}7. Tipo: Aplicativo da Web${NC}"
echo -e "${BLUE}8. Execute como: Você${NC}"
echo -e "${BLUE}9. Quem tem acesso: Qualquer pessoa${NC}"
echo -e "${BLUE}10. Clique em Implantar${NC}"
echo ""
echo -e "${BLUE}11. COPIE A URL QUE APARECER (tipo: https://script.google.com/macros/s/AKfycbXXX/usercontent)${NC}"
echo ""

# 3. Pedir a URL
read -p "Cole a URL do webhook aqui: " WEBHOOK_URL

# 4. Validar URL
if [[ ! $WEBHOOK_URL =~ "script.google.com" ]]; then
    echo -e "${RED}❌ URL inválida!${NC}"
    exit 1
fi

# 5. Pedir o Sheet ID
echo ""
echo -e "${BLUE}Agora abra a planilha que você criou${NC}"
echo -e "${BLUE}A URL será algo como: https://docs.google.com/spreadsheets/d/XXXXX/edit${NC}"
echo -e "${BLUE}COPIE O ID (a parte do meio, entre /d/ e /edit)${NC}"
echo ""
read -p "Cole o ID da planilha aqui: " SHEET_ID

# 6. Validar Sheet ID
if [ -z "$SHEET_ID" ]; then
    echo -e "${RED}❌ Sheet ID vazio!${NC}"
    exit 1
fi

# 7. Criar/Atualizar .env.local
echo ""
echo -e "${GREEN}✅ Atualizando .env.local...${NC}"

cat > .env.local << EOF
GOOGLE_WEBHOOK_URL=${WEBHOOK_URL}
GOOGLE_SHEET_ID=${SHEET_ID}
EOF

echo -e "${GREEN}✅ .env.local criado com sucesso!${NC}"
echo ""
echo -e "${BLUE}Conteúdo:${NC}"
cat .env.local
echo ""

# 8. Reiniciar servidor
echo -e "${BLUE}Reiniciando servidor...${NC}"
echo ""
echo -e "${GREEN}✅ PRONTO! Agora rode:${NC}"
echo "   npm run dev"
echo ""
echo -e "${GREEN}E teste em: http://localhost:3000${NC}"
echo ""
