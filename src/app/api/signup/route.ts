import { NextRequest, NextResponse } from 'next/server';
import {
  sanitizeEmail,
  sanitizeText,
  validateWebhookUrl,
  getClientIp,
  validateRequestSize,
  MAX_REQUEST_SIZE,
} from '@/lib/security';

// Simple in-memory rate limiting (in production, use Redis or similar)
const rateLimitMap = new Map<string, { count: number; resetTime: number }>();
const RATE_LIMIT_WINDOW = 60 * 1000; // 1 minute
const RATE_LIMIT_MAX_REQUESTS = 5; // 5 requests per minute per IP
const CLEANUP_INTERVAL = 5 * 60 * 1000; // Cleanup every 5 minutes
let lastCleanup = Date.now();

// Lazy cleanup: only clean up when checking rate limit and enough time has passed
// This works better in serverless environments than setInterval
function cleanupExpiredEntries(): void {
  const now = Date.now();
  // Only cleanup if enough time has passed (prevents excessive cleanup in high-traffic)
  if (now - lastCleanup < CLEANUP_INTERVAL) {
    return;
  }

  lastCleanup = now;
  let cleanedCount = 0;

  for (const [ip, record] of rateLimitMap.entries()) {
    if (now > record.resetTime) {
      rateLimitMap.delete(ip);
      cleanedCount++;
    }
  }

  // Log cleanup only in development
  if (process.env.NODE_ENV !== 'production' && cleanedCount > 0) {
    console.log(`🧹 Cleaned up ${cleanedCount} expired rate limit entries`);
  }
}

function checkRateLimit(ip: string): boolean {
  const now = Date.now();

  // Lazy cleanup: clean expired entries when checking (better for serverless)
  if (rateLimitMap.size > 100 || now - lastCleanup >= CLEANUP_INTERVAL) {
    cleanupExpiredEntries();
  }

  const record = rateLimitMap.get(ip);

  if (!record || now > record.resetTime) {
    rateLimitMap.set(ip, { count: 1, resetTime: now + RATE_LIMIT_WINDOW });
    return true;
  }

  if (record.count >= RATE_LIMIT_MAX_REQUESTS) {
    return false;
  }

  record.count++;
  return true;
}

// Validate environment variables
function validateEnv(): { valid: boolean; missing?: string[] } {
  const required = ['GOOGLE_WEBHOOK_URL'];
  const missing = required.filter(key => !process.env[key]);

  // In production, fail if required env vars are missing
  if (process.env.NODE_ENV === 'production' && missing.length > 0) {
    return { valid: false, missing };
  }

  // Validate webhook URL format
  const webhookUrl = process.env.GOOGLE_WEBHOOK_URL;
  if (webhookUrl && !validateWebhookUrl(webhookUrl)) {
    console.error('❌ Invalid GOOGLE_WEBHOOK_URL format');
    if (process.env.NODE_ENV === 'production') {
      return { valid: false, missing: ['GOOGLE_WEBHOOK_URL'] };
    }
  }

  return { valid: true };
}

export async function POST(request: NextRequest) {
  try {
    // 1. Request size validation
    const contentLength = request.headers.get('content-length');
    if (!validateRequestSize(contentLength, MAX_REQUEST_SIZE)) {
      return NextResponse.json(
        { error: 'Requisição muito grande' },
        { status: 413 }
      );
    }

    // 2. Content-Type validation
    const contentType = request.headers.get('content-type');
    if (!contentType?.includes('application/json')) {
      return NextResponse.json(
        { error: 'Content-Type deve ser application/json' },
        { status: 415 }
      );
    }

    // 3. Rate limiting - get IP from headers
    const ip = getClientIp(request);
    
    if (!checkRateLimit(ip)) {
      // Log rate limit hit in production (without IP)
      if (process.env.NODE_ENV === 'production') {
        console.warn('⚠️ Rate limit exceeded');
      }
      return NextResponse.json(
        { error: 'Muitas requisições. Tente novamente em alguns minutos.' },
        { status: 429 }
      );
    }

    // 4. Validate environment
    const envCheck = validateEnv();
    if (!envCheck.valid && process.env.NODE_ENV === 'production') {
      // Don't expose which env vars are missing in production
      console.error('❌ Missing required environment variables');
      return NextResponse.json(
        { error: 'Serviço temporariamente indisponível' },
        { status: 503 }
      );
    }

    // 5. Parse and validate JSON body
    let body;
    try {
      body = await request.json();
    } catch (error) {
      return NextResponse.json(
        { error: 'JSON inválido no corpo da requisição' },
        { status: 400 }
      );
    }

    const { email, name, company } = body;

    // 6. Validate and sanitize inputs using security utilities
    const emailValidation = sanitizeEmail(email);
    if (!emailValidation.valid) {
      return NextResponse.json(
        { error: emailValidation.error },
        { status: 400 }
      );
    }

    const nameValidation = sanitizeText(name, 'Nome', 200);
    if (!nameValidation.valid) {
      return NextResponse.json(
        { error: nameValidation.error },
        { status: 400 }
      );
    }

    const companyValidation = sanitizeText(company, 'Empresa', 200);
    if (!companyValidation.valid) {
      return NextResponse.json(
        { error: companyValidation.error },
        { status: 400 }
      );
    }

    const sanitizedEmail = emailValidation.sanitized!;
    const sanitizedName = nameValidation.sanitized!;
    const sanitizedCompany = companyValidation.sanitized!;

    // 7. 📊 Enviar para Google Sheets (validate URL first)
    const googleWebhookUrl = process.env.GOOGLE_WEBHOOK_URL;

    if (googleWebhookUrl && validateWebhookUrl(googleWebhookUrl)) {
      try {
        const payload = {
          timestamp: new Date().toISOString(),
          name: sanitizedName,
          email: sanitizedEmail,
          company: sanitizedCompany,
        };

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 10000); // 10s timeout

        const sheetResponse = await fetch(googleWebhookUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'EcoReport-Site/1.0',
          },
          body: JSON.stringify(payload),
          signal: controller.signal,
        });

        clearTimeout(timeoutId);
        const responseText = await sheetResponse.text();
        
        if (sheetResponse.ok && responseText.includes('OK')) {
          // Log apenas em desenvolvimento para evitar logs sensíveis em produção
          if (process.env.NODE_ENV !== 'production') {
            console.log('✅ Dados salvos no Google Sheets com sucesso');
          }
        } else {
          // Log apenas primeiro 100 chars para não expor dados sensíveis
          console.warn('⚠️ Resposta inesperada do Google Sheets:', responseText.slice(0, 100));
        }
      } catch (sheetError) {
        // Don't expose internal errors to client
        const errorMessage = sheetError instanceof Error ? sheetError.message : 'Unknown error';
        if (errorMessage.includes('aborted')) {
          console.warn('⚠️ Timeout ao salvar no Google Sheets');
        } else {
          // Log apenas tipo de erro, não detalhes
          console.error('❌ Erro ao salvar no Google Sheets');
          if (process.env.NODE_ENV !== 'production') {
            console.error('Detalhes:', errorMessage);
          }
        }
        // Continua mesmo se Sheets falhar - não bloqueia o cadastro
      }
    } else {
      if (process.env.NODE_ENV !== 'production') {
        console.warn('⚠️ GOOGLE_WEBHOOK_URL não configurada ou inválida');
      }
    }

    // ✅ Log estruturado (sem dados sensíveis em produção)
    if (process.env.NODE_ENV !== 'production') {
      console.log('✅ Novo cadastro:', {
        timestamp: new Date().toISOString(),
        name: sanitizedName,
        email: sanitizedEmail,
        company: sanitizedCompany,
      });
    } else {
      // Em produção, log apenas metadata
      console.log('✅ Novo cadastro realizado:', {
        timestamp: new Date().toISOString(),
        emailDomain: sanitizedEmail.split('@')[1],
      });
    }

    return NextResponse.json(
      { 
        message: 'Cadastro realizado com sucesso!',
        success: true 
      },
      { status: 201 }
    );
  } catch (error) {
    // Never expose internal error details to client
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    
    // Log full error only in development
    if (process.env.NODE_ENV !== 'production') {
      console.error('❌ Erro no signup:', errorMessage);
      if (error instanceof Error && error.stack) {
        console.error('Stack:', error.stack);
      }
    } else {
      // In production, log minimal info
      console.error('❌ Erro ao processar cadastro');
    }

    // Always return generic error message
    return NextResponse.json(
      { error: 'Erro ao processar cadastro. Tente novamente mais tarde.' },
      { status: 500 }
    );
  }
}
