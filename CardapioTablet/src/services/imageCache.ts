import { Image } from 'react-native';

import type { MenuItem } from '../types';

const prefetchedImageUris = new Set<string>();
const failedImageUris = new Set<string>();

export function resolveProductImageUri(product: Pick<MenuItem, 'imagem'> | null | undefined): string | undefined {
  const uri = String(product?.imagem || '').trim();
  return uri || undefined;
}

export function isProductImageFailed(uri: string | undefined): boolean {
  return Boolean(uri && failedImageUris.has(uri));
}

export function markProductImageFailed(uri: string | undefined): void {
  if (uri) {
    failedImageUris.add(uri);
  }
}

export async function prefetchProductImages(products: MenuItem[], limit = 16): Promise<void> {
  const targets = products
    .map(resolveProductImageUri)
    .filter((uri): uri is string => Boolean(uri))
    .filter((uri) => !uri.startsWith('data:image/'))
    .filter((uri) => !prefetchedImageUris.has(uri) && !failedImageUris.has(uri))
    .slice(0, limit);

  if (targets.length === 0) return;

  await Promise.allSettled(
    targets.map(async (uri) => {
      try {
        const loaded = await Image.prefetch(uri);
        if (loaded) {
          prefetchedImageUris.add(uri);
        } else {
          failedImageUris.add(uri);
        }
      } catch {
        failedImageUris.add(uri);
      }
    })
  );
}
