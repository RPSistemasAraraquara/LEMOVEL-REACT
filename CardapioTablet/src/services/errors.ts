export const NETWORK_SEND_FAILURE_TITLE = 'Falha no envio da rede';
export const NETWORK_SEND_FAILURE_MESSAGE = 'Falha no envio da rede, chame o Garçom.';
export const NETWORK_GENERAL_FAILURE_MESSAGE = 'Falha de conexao com a rede. Chame o garcom.';

export function getErrorMessage(error: unknown, fallback: string): string {
  return error instanceof Error && error.message ? error.message : fallback;
}

export function isNetworkRequestError(error: unknown): boolean {
  const message = getErrorMessage(error, '').toLowerCase();
  return (
    message.includes('network request failed') ||
    message.includes('failed to fetch') ||
    message.includes('networkerror') ||
    message.includes('timeout') ||
    message.includes('timed out') ||
    message.includes('aborted')
  );
}

export function getFriendlyErrorMessage(error: unknown, fallback: string): string {
  return isNetworkRequestError(error) ? NETWORK_GENERAL_FAILURE_MESSAGE : getErrorMessage(error, fallback);
}
