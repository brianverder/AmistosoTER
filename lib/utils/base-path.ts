const rawBasePath = process.env.NEXT_PUBLIC_BASE_PATH?.trim() ?? '';

const normalizedBasePath =
  rawBasePath && rawBasePath !== '/'
    ? rawBasePath.startsWith('/')
      ? rawBasePath
      : `/${rawBasePath}`
    : '';

export const BASE_PATH = normalizedBasePath;

export function withBasePath(path: string): string {
  if (!path) return BASE_PATH || '/';
  if (!BASE_PATH) return path;

  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return `${BASE_PATH}${normalizedPath}`;
}
