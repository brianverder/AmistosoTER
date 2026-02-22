/** @type {import('next').NextConfig} */
const rawBasePath = process.env.NEXT_PUBLIC_BASE_PATH?.trim() || '';
const basePath = rawBasePath && rawBasePath !== '/'
  ? (rawBasePath.startsWith('/') ? rawBasePath : `/${rawBasePath}`)
  : '';

const nextConfig = {
  ...(basePath ? { basePath } : {}),
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'tercer-tiempo.com',
        port: '',
        pathname: '/images/**',
      },
    ],
  },
}

module.exports = nextConfig
