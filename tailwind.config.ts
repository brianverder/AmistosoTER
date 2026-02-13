import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Paleta inspirada en Tercer Tiempo: Blanco y Negro, sobrio y deportivo
        primary: {
          DEFAULT: '#000000',    // Negro principal
          light: '#1a1a1a',      // Negro suave
          dark: '#000000',       // Negro puro
        },
        secondary: {
          DEFAULT: '#ffffff',    // Blanco puro
          dark: '#f8f8f8',       // Gris muy claro
        },
        gray: {
          50: '#f9fafb',
          100: '#f3f4f6',
          200: '#e5e7eb',
          300: '#d1d5db',
          400: '#9ca3af',
          500: '#6b7280',
          600: '#4b5563',
          700: '#374151',
          800: '#1f2937',
          900: '#111827',
        },
        accent: {
          DEFAULT: '#374151',    // Gris oscuro para acentos
          success: '#10b981',    // Verde sutil para éxitos
          warning: '#f59e0b',    // Amarillo para advertencias
          danger: '#dc2626',     // Rojo para errores
        },
      },
      fontFamily: {
        sans: [
          'Inter',
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'Roboto',
          'Helvetica Neue',
          'Arial',
          'sans-serif',
        ],
      },
      fontWeight: {
        normal: '400',
        medium: '500',
        semibold: '600',
        bold: '700',
        extrabold: '800',
        black: '900',
      },
    },
  },
  plugins: [],
}
export default config
