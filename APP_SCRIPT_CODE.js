// COLE ESTE CÓDIGO NO GOOGLE APPS SCRIPT
// IMPORTANTE: Substitua 'COLE_O_ID_DA_PLANILHA_AQUI' pelo ID real da sua planilha

const SHEET_ID = '1fugukI3V_fVvTaKi81TEUZ6WWmtR0frA2gH_HJnLRsQ';

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return ContentService.createTextOutput("Erro: Sem dados").setMimeType(ContentService.MimeType.TEXT);
    }

    const data = JSON.parse(e.postData.contents);
    
    // Abre a planilha usando o ID
    const spreadsheet = SpreadsheetApp.openById(SHEET_ID);
    const sheet = spreadsheet.getActiveSheet();
    
    // Adiciona os dados na planilha
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

