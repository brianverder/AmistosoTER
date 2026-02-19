/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    serverActions: {
      allowedOrigins: ['localhost:3000'],
    },
  },

  // ============================================
  // SECURITY HEADERS
  // ============================================
  async headers() {
    return [
      {
        // Aplicar a todas las rutas
        source: '/:path*',
        headers: [
          // Prevent framing (clickjacking protection)
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          // Prevent MIME type sniffing
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          // Referrer policy
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          // XSS Protection (legacy but still useful)
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
          // DNS Prefetch Control
          {
            key: 'X-DNS-Prefetch-Control',
            value: 'on',
          },
          // Permissions Policy (restrict APIs)
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()',
          },
          // Content Security Policy (CSP)
          {
            key: 'Content-Security-Policy',
            value: [
              "default-src 'self'",
              "script-src 'self' 'unsafe-eval' 'unsafe-inline' https://pagead2.googlesyndication.com https://www.googletagservices.com https://www.google.com https://www.gstatic.com", // Next.js + AdSense
              "style-src 'self' 'unsafe-inline'", // Tailwind needs unsafe-inline
              "img-src 'self' data: https:",
              "font-src 'self' data:",
              "connect-src 'self' https://pagead2.googlesyndication.com https://googleads.g.doubleclick.net https://www.google.com https://www.googletagservices.com",
              "frame-src https://googleads.g.doubleclick.net https://tpc.googlesyndication.com https://www.google.com",
              "frame-ancestors 'none'",
            ].join('; '),
          },
        ],
      },
      {
        // HSTS para production (solo HTTPS)
        source: '/:path*',
        headers: [
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=63072000; includeSubDomains; preload',
          },
        ],
        // Solo aplicar en producción con HTTPS
        ...(process.env.NODE_ENV === 'production' ? {} : { missing: [{ type: 'header', key: 'host' }] }),
      },
    ];
  },

  // ============================================
  // COMPRESSION
  // ============================================
  compress: true, // Habilitar gzip/brotli

  // ============================================
  // OPTIMIZATIONS
  // ============================================
  images: {
    formats: ['image/webp', 'image/avif'], // Formatos modernos
    minimumCacheTTL: 60, // Cache imágenes 60 segundos
  },

  // ============================================
  // PRODUCTION OPTIMIZATIONS
  // ============================================
  ...(process.env.NODE_ENV === 'production' && {
    // Deshabilitar powered by header
    poweredByHeader: false,
    // Optimizar producción
    reactStrictMode: true,
    swcMinify: true,
  }),
};

export default nextConfig;
