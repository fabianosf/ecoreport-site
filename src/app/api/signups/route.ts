import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    // Por enquanto retorna mensagem informando que precisa configurar o Google Sheets
    // Quando o Sheets estiver configurado, podemos buscar os dados de lá
    
    return NextResponse.json({
      message: 'Os cadastros estão sendo salvos no Google Sheets. Para visualizar, abra a planilha no Google Drive.',
      note: 'Você também pode ver os cadastros em tempo real no console do terminal onde o servidor está rodando.',
    });
  } catch (error) {
    console.error('❌ Erro ao buscar cadastros:', error);
    return NextResponse.json(
      { error: 'Erro ao buscar cadastros' },
      { status: 500 }
    );
  }
}

