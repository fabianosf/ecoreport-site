import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { email, name, company } = await request.json();

    // Validação
    if (!email || !name || !company) {
      return NextResponse.json(
        { error: 'Todos os campos são obrigatórios' },
        { status: 400 }
      );
    }

    // Validar email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return NextResponse.json(
        { error: 'Email inválido' },
        { status: 400 }
      );
    }

    // 📊 Enviar para Google Sheets
    const googleWebhookUrl = process.env.GOOGLE_WEBHOOK_URL;

    if (googleWebhookUrl) {
      try {
        const payload = {
          timestamp: new Date().toISOString(),
          name,
          email,
          company,
        };

        const sheetResponse = await fetch(googleWebhookUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
        });

        const responseText = await sheetResponse.text();
        
        if (sheetResponse.ok && responseText.includes('OK')) {
          console.log('✅ Dados salvos no Google Sheets com sucesso');
        } else {
          console.warn('⚠️ Resposta inesperada do Google Sheets:', responseText);
        }
      } catch (sheetError) {
        console.error('❌ Erro ao salvar no Google Sheets:', sheetError);
        // Continua mesmo se Sheets falhar - não bloqueia o cadastro
      }
    } else {
      console.warn('⚠️ GOOGLE_WEBHOOK_URL não configurada - dados não serão salvos no Sheets');
    }

    // ✅ Log no console
    console.log('✅ Novo cadastro:', {
      timestamp: new Date().toISOString(),
      name,
      email,
      company,
    });

    return NextResponse.json(
      { 
        message: 'Cadastro realizado com sucesso!',
        success: true 
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('❌ Erro no signup:', error);
    return NextResponse.json(
      { error: 'Erro ao processar cadastro' },
      { status: 500 }
    );
  }
}
