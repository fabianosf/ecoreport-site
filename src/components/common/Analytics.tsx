'use client';

import { useEffect } from 'react';
import Script from 'next/script';
import { saveUTMParams, getSavedUTMParams } from '@/lib/utm';

/**
 * Analytics component supporting multiple providers
 * - Google Analytics 4 (GA4)
 * - Google Ads Conversion Tracking
 * - Facebook Pixel (Meta Pixel)
 * - Plausible Analytics
 */
export default function Analytics() {
  const gaId = process.env.NEXT_PUBLIC_GA_ID;
  const googleAdsId = process.env.NEXT_PUBLIC_GOOGLE_ADS_ID;
  const facebookPixelId = process.env.NEXT_PUBLIC_FACEBOOK_PIXEL_ID;
  const plausibleDomain = process.env.NEXT_PUBLIC_PLAUSIBLE_DOMAIN;

  // Save UTM parameters on page load
  useEffect(() => {
    if (typeof window !== 'undefined') {
      saveUTMParams();
    }
  }, []);

  // Track page views with UTM data for GA4
  useEffect(() => {
    if (gaId && typeof window !== 'undefined' && (window as any).gtag) {
      const utmParams = getSavedUTMParams();
      
      // Send page view with UTM parameters
      (window as any).gtag('event', 'page_view', {
        page_path: window.location.pathname + window.location.search,
        ...utmParams,
      });
    }
  }, [gaId]);

  return (
    <>
      {/* Google Analytics 4 */}
      {gaId && (
        <>
          <Script
            strategy="afterInteractive"
            src={`https://www.googletagmanager.com/gtag/js?id=${gaId}`}
          />
          <Script
            id="google-analytics"
            strategy="afterInteractive"
            dangerouslySetInnerHTML={{
              __html: `
                window.dataLayer = window.dataLayer || [];
                function gtag(){dataLayer.push(arguments);}
                gtag('js', new Date());
                gtag('config', '${gaId}', {
                  page_path: window.location.pathname,
                });
              `,
            }}
          />
        </>
      )}

      {/* Google Ads Conversion Tracking */}
      {googleAdsId && gaId && (
        <Script
          id="google-ads"
          strategy="afterInteractive"
          dangerouslySetInnerHTML={{
            __html: `
              gtag('config', '${googleAdsId}');
            `,
          }}
        />
      )}

      {/* Facebook Pixel (Meta Pixel) */}
      {facebookPixelId && (
        <>
          <Script
            id="facebook-pixel"
            strategy="afterInteractive"
            dangerouslySetInnerHTML={{
              __html: `
                !function(f,b,e,v,n,t,s)
                {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
                n.callMethod.apply(n,arguments):n.queue.push(arguments)};
                if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
                n.queue=[];t=b.createElement(e);t.async=!0;
                t.src=v;s=b.getElementsByTagName(e)[0];
                s.parentNode.insertBefore(t,s)}(window, document,'script',
                'https://connect.facebook.net/en_US/fbevents.js');
                fbq('init', '${facebookPixelId}');
                fbq('track', 'PageView');
              `,
            }}
          />
          <noscript>
            <img
              height="1"
              width="1"
              style={{ display: 'none' }}
              src={`https://www.facebook.com/tr?id=${facebookPixelId}&ev=PageView&noscript=1`}
              alt=""
            />
          </noscript>
        </>
      )}

      {/* Plausible Analytics */}
      {plausibleDomain && (
        <Script
          strategy="afterInteractive"
          data-domain={plausibleDomain}
          src="https://plausible.io/js/script.js"
        />
      )}
    </>
  );
}

/**
 * Track custom event for Google Analytics
 */
export function trackEvent(action: string, category: string, label?: string, value?: number) {
  if (typeof window !== 'undefined' && (window as any).gtag) {
    (window as any).gtag('event', action, {
      event_category: category,
      event_label: label,
      value: value,
    });
  }
}

/**
 * Track custom event for Plausible
 */
export function trackPlausibleEvent(name: string, props?: Record<string, any>) {
  if (typeof window !== 'undefined' && (window as any).plausible) {
    (window as any).plausible(name, { props });
  }
}

/**
 * Track conversion for Google Ads
 */
export function trackGoogleAdsConversion(conversionLabel: string, value?: number, currency = 'BRL') {
  if (typeof window !== 'undefined' && (window as any).gtag) {
    (window as any).gtag('event', 'conversion', {
      send_to: conversionLabel,
      value: value,
      currency: currency,
    });
  }
}

/**
 * Track conversion for Facebook Pixel
 */
export function trackFacebookEvent(eventName: string, params?: Record<string, any>) {
  if (typeof window !== 'undefined' && (window as any).fbq) {
    (window as any).fbq('track', eventName, params);
  }
}

/**
 * Track custom conversion with all platforms
 */
export function trackConversion(eventName: string, value?: number, params?: Record<string, any>) {
  // Google Analytics
  trackEvent(eventName, 'conversion', undefined, value);

  // Google Ads
  const googleAdsConversionLabel = process.env.NEXT_PUBLIC_GOOGLE_ADS_CONVERSION_LABEL;
  if (googleAdsConversionLabel) {
    trackGoogleAdsConversion(googleAdsConversionLabel, value);
  }

  // Facebook Pixel
  const facebookPixelId = process.env.NEXT_PUBLIC_FACEBOOK_PIXEL_ID;
  if (facebookPixelId) {
    trackFacebookEvent(eventName, { value, currency: 'BRL', ...params });
  }

  // Plausible
  trackPlausibleEvent(eventName, { value, ...params });
}

