export const DEFAULT_API_BASE_URL = 'https://mobile.rpfood.com.br';

function shouldUseHttpForLocalAddress(value: string): boolean {
  const host = value.split(/[/?#]/)[0];

  return (
    /^localhost(?::|$)/i.test(host) ||
    /^127\./.test(host) ||
    /^10\./.test(host) ||
    /^192\.168\./.test(host) ||
    /^172\.(1[6-9]|2\d|3[0-1])\./.test(host) ||
    /^\d{1,3}(?:\.\d{1,3}){3}(?::|$)/.test(host) ||
    host.includes(':')
  );
}

export function normalizeApiBaseUrl(value: unknown, fallback = DEFAULT_API_BASE_URL): string {
  const fallbackValue = String(fallback || DEFAULT_API_BASE_URL).trim().replace(/\/+$/, '');
  const raw = String(value || '').trim().replace(/\/+$/, '');
  const candidate = raw || fallbackValue;

  if (/^[a-z][a-z\d+.-]*:\/\//i.test(candidate)) {
    return candidate;
  }

  const protocol = shouldUseHttpForLocalAddress(candidate) ? 'http' : 'https';
  return `${protocol}://${candidate}`;
}

export function isHttpApiBaseUrl(value: unknown): boolean {
  return /^http:\/\//i.test(String(value || '').trim());
}
