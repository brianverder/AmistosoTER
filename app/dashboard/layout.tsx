'use client';

import { SessionProvider } from 'next-auth/react';
import DashboardNav from '@/components/DashboardNav';
import AdSenseBanner from '@/components/AdSenseBanner';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <SessionProvider>
      <div className="min-h-screen bg-gray-50">
        <DashboardNav />
        <main className="container-custom py-8">
          <AdSenseBanner
            adSlot={process.env.NEXT_PUBLIC_ADSENSE_DASHBOARD_SLOT || ''}
            className="mb-6"
            minHeight={100}
          />
          {children}
        </main>
      </div>
    </SessionProvider>
  );
}
