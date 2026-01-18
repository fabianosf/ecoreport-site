/**
 * UTM Parameter Tracking Utilities
 * Para rastreamento de tráfego pago e campanhas
 */

export interface UTMParams {
  utm_source?: string;
  utm_medium?: string;
  utm_campaign?: string;
  utm_term?: string;
  utm_content?: string;
  gclid?: string; // Google Click ID
  fbclid?: string; // Facebook Click ID
}

/**
 * Extrai UTM parameters da URL
 */
export function getUTMParams(): UTMParams {
  if (typeof window === 'undefined') {
    return {};
  }

  const params = new URLSearchParams(window.location.search);
  const utmParams: UTMParams = {};

  // Google Click ID
  if (params.has('gclid')) {
    utmParams.gclid = params.get('gclid') || undefined;
  }

  // Facebook Click ID
  if (params.has('fbclid')) {
    utmParams.fbclid = params.get('fbclid') || undefined;
  }

  // UTM parameters
  const utmKeys: Array<keyof UTMParams> = [
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
  ];

  utmKeys.forEach((key) => {
    const value = params.get(key);
    if (value) {
      utmParams[key] = value;
    }
  });

  return utmParams;
}

/**
 * Salva UTM parameters no sessionStorage
 */
export function saveUTMParams(): void {
  if (typeof window === 'undefined') return;

  const utmParams = getUTMParams();
  
  if (Object.keys(utmParams).length > 0) {
    sessionStorage.setItem('utm_params', JSON.stringify(utmParams));
  }
}

/**
 * Recupera UTM parameters do sessionStorage
 */
export function getSavedUTMParams(): UTMParams {
  if (typeof window === 'undefined') return {};

  try {
    const saved = sessionStorage.getItem('utm_params');
    return saved ? JSON.parse(saved) : {};
  } catch {
    return {};
  }
}

/**
 * Limpa UTM parameters do sessionStorage
 */
export function clearUTMParams(): void {
  if (typeof window === 'undefined') return;
  sessionStorage.removeItem('utm_params');
}

