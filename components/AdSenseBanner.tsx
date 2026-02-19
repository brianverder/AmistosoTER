'use client';

import { useEffect, useRef, useState } from 'react';

declare global {
  interface Window {
    adsbygoogle?: unknown[];
    __adsenseScriptPromise__?: Promise<void>;
  }
}

type AdSenseBannerProps = {
  adSlot: string;
  adClient?: string;
  className?: string;
  minHeight?: number;
  adFormat?: 'auto' | 'rectangle' | 'horizontal' | 'fluid';
  adLayoutKey?: string;
  fullWidthResponsive?: boolean;
};

function loadAdSenseScript(adClient: string): Promise<void> {
  if (typeof window === 'undefined') {
    return Promise.resolve();
  }

  if (typeof window.adsbygoogle !== 'undefined') {
    return Promise.resolve();
  }

  if (window.__adsenseScriptPromise__) {
    return window.__adsenseScriptPromise__;
  }

  const existingScript = document.querySelector<HTMLScriptElement>(
    'script[data-adsense="global"]'
  );

  if (existingScript) {
    if (typeof window.adsbygoogle !== 'undefined' || existingScript.dataset.loaded === 'true') {
      return Promise.resolve();
    }

    window.__adsenseScriptPromise__ = new Promise((resolve, reject) => {
      if (existingScript.readyState === 'complete') {
        resolve();
        return;
      }

      existingScript.addEventListener('load', () => resolve(), { once: true });
      existingScript.addEventListener('error', () => reject(new Error('AdSense script error')), {
        once: true,
      });
    });
    return window.__adsenseScriptPromise__;
  }

  window.__adsenseScriptPromise__ = new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.async = true;
    script.src = `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${adClient}`;
    script.crossOrigin = 'anonymous';
    script.dataset.adsense = 'global';
    script.onload = () => {
      script.dataset.loaded = 'true';
      resolve();
    };
    script.onerror = () => reject(new Error('No se pudo cargar AdSense'));
    document.head.appendChild(script);
  });

  return window.__adsenseScriptPromise__;
}

export default function AdSenseBanner({
  adSlot,
  adClient = process.env.NEXT_PUBLIC_ADSENSE_CLIENT || '',
  className,
  minHeight = 90,
  adFormat = 'auto',
  adLayoutKey,
  fullWidthResponsive = true,
}: AdSenseBannerProps) {
  const adRef = useRef<HTMLModElement | null>(null);
  const initializedRef = useRef(false);
  const [isVisible, setIsVisible] = useState(false);
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    if (process.env.NODE_ENV === 'development' && (!adClient || !adSlot)) {
      console.warn('AdSenseBanner deshabilitado: falta NEXT_PUBLIC_ADSENSE_CLIENT o adSlot.');
    }
  }, [adClient, adSlot]);

  useEffect(() => {
    const element = adRef.current;
    if (!element) return;

    const observer = new IntersectionObserver(
      (entries) => {
        const [entry] = entries;
        if (entry.isIntersecting) {
          setIsVisible(true);
          observer.disconnect();
        }
      },
      { rootMargin: '300px 0px' }
    );

    observer.observe(element);

    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    if (!isVisible || initializedRef.current || hasError || !adClient || !adSlot || !adRef.current) {
      return;
    }

    let isCancelled = false;

    loadAdSenseScript(adClient)
      .then(() => {
        if (isCancelled || initializedRef.current || !adRef.current) return;

        try {
          (window.adsbygoogle = window.adsbygoogle || []).push({});
          initializedRef.current = true;
        } catch {
          setHasError(true);
        }
      })
      .catch(() => {
        if (!isCancelled) {
          setHasError(true);
        }
      });

    return () => {
      isCancelled = true;
    };
  }, [isVisible, hasError, adClient, adSlot]);

  if (!adClient || !adSlot || hasError) {
    return null;
  }

  return (
    <div className={className} style={{ minHeight }} aria-label="Publicidad">
      <ins
        ref={adRef}
        className="adsbygoogle"
        style={{ display: 'block', width: '100%', minHeight }}
        data-ad-client={adClient}
        data-ad-slot={adSlot}
        data-ad-format={adFormat}
        data-ad-layout-key={adLayoutKey}
        data-full-width-responsive={fullWidthResponsive ? 'true' : 'false'}
      />
    </div>
  );
}
