'use client';

import { SessionProvider } from 'next-auth/react';
import DashboardNav from '@/components/DashboardNav';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <SessionProvider>
      <div className="min-h-screen bg-gray-50">
        <DashboardNav />
        <main className="container-custom py-8">{children}</main>
      </div>
    </SessionProvider>
  );
}
