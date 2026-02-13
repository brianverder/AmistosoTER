import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import NextAuthProvider from '@/components/NextAuthProvider';
import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'Tercer Tiempo - Partidos Amistosos',
  description: 'Plataforma para coordinar partidos amistosos de fútbol amateur',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body className={inter.className}>
        <NextAuthProvider>
          {children}
        </NextAuthProvider>
      </body>
    </html>
  );
}
