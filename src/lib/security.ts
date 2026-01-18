/**
 * Security utilities for input validation and sanitization
 */

// Maximum request body size (1MB)
export const MAX_REQUEST_SIZE = 1024 * 1024;

// Valid email regex (RFC 5322 compliant subset)
const EMAIL_REGEX = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;

// Allowed characters for name and company (letters, numbers, spaces, common punctuation)
const SAFE_TEXT_REGEX = /^[a-zA-ZÀ-ÿ0-9\s.,\-'&()]+$/u;

/**
 * Sanitize and validate email
 */
export function sanitizeEmail(email: string): { valid: boolean; sanitized?: string; error?: string } {
  if (!email || typeof email !== 'string') {
    return { valid: false, error: 'Email é obrigatório' };
  }

  // Trim and convert to lowercase
  const trimmed = email.trim().toLowerCase();

  // Length validation (RFC 5321)
  if (trimmed.length > 254) {
    return { valid: false, error: 'Email muito longo (máximo 254 caracteres)' };
  }

  if (trimmed.length < 3) {
    return { valid: false, error: 'Email muito curto' };
  }

  // Basic format validation
  if (!EMAIL_REGEX.test(trimmed)) {
    return { valid: false, error: 'Formato de email inválido' };
  }

  // Check for suspicious patterns
  if (trimmed.includes('..') || trimmed.startsWith('.') || trimmed.endsWith('.')) {
    return { valid: false, error: 'Formato de email inválido' };
  }

  return { valid: true, sanitized: trimmed };
}

/**
 * Sanitize and validate text input (name, company)
 */
export function sanitizeText(
  text: string,
  fieldName: string,
  maxLength: number = 200
): { valid: boolean; sanitized?: string; error?: string } {
  if (!text || typeof text !== 'string') {
    return { valid: false, error: `${fieldName} é obrigatório` };
  }

  // Trim whitespace
  const trimmed = text.trim();

  // Length validation
  if (trimmed.length === 0) {
    return { valid: false, error: `${fieldName} não pode estar vazio` };
  }

  if (trimmed.length > maxLength) {
    return { valid: false, error: `${fieldName} muito longo (máximo ${maxLength} caracteres)` };
  }

  // Check for safe characters only
  if (!SAFE_TEXT_REGEX.test(trimmed)) {
    return { valid: false, error: `${fieldName} contém caracteres inválidos` };
  }

  // Prevent script injection attempts
  const lowerText = trimmed.toLowerCase();
  const dangerousPatterns = [
    '<script',
    'javascript:',
    'onerror=',
    'onload=',
    'onclick=',
    '<iframe',
    '<object',
    '<embed',
  ];

  for (const pattern of dangerousPatterns) {
    if (lowerText.includes(pattern)) {
      return { valid: false, error: `${fieldName} contém conteúdo inválido` };
    }
  }

  return { valid: true, sanitized: trimmed };
}

/**
 * Validate webhook URL
 */
export function validateWebhookUrl(url: string): boolean {
  if (!url || typeof url !== 'string') {
    return false;
  }

  try {
    const parsed = new URL(url);

    // Only allow HTTPS
    if (parsed.protocol !== 'https:') {
      return false;
    }

    // Only allow script.google.com domain
    if (!parsed.hostname.endsWith('script.google.com')) {
      return false;
    }

    return true;
  } catch {
    return false;
  }
}

/**
 * Check request origin against allowed origins
 */
export function validateOrigin(origin: string | null, allowedOrigins: string[]): boolean {
  if (!origin) {
    return false;
  }

  try {
    const originUrl = new URL(origin);

    return allowedOrigins.some(allowed => {
      try {
        const allowedUrl = new URL(allowed);
        return originUrl.origin === allowedUrl.origin;
      } catch {
        return false;
      }
    });
  } catch {
    return false;
  }
}

/**
 * Get client IP from request headers
 */
export function getClientIp(request: Request): string {
  const headers = request.headers;
  const forwardedFor = headers.get('x-forwarded-for');
  const realIp = headers.get('x-real-ip');
  const cfConnectingIp = headers.get('cf-connecting-ip'); // Cloudflare

  if (forwardedFor) {
    // x-forwarded-for can contain multiple IPs, take the first one
    return forwardedFor.split(',')[0].trim();
  }

  return realIp || cfConnectingIp || 'unknown';
}

/**
 * Validate request size
 */
export function validateRequestSize(contentLength: string | null, maxSize: number = MAX_REQUEST_SIZE): boolean {
  if (!contentLength) {
    return true; // No content length means unknown, let it through
  }

  const size = parseInt(contentLength, 10);
  if (isNaN(size)) {
    return false;
  }

  return size <= maxSize;
}

