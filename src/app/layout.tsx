import type { Metadata } from 'next';
import './globals.css';
import { SITE_NAME, SITE_DESCRIPTION, SITE_URL } from '@/lib/constants';
import Analytics from '@/components/common/Analytics';
import ErrorBoundary from '@/components/common/ErrorBoundary';
import StructuredData from '@/components/common/StructuredData';

export const metadata: Metadata = {
  title: `${SITE_NAME} - Gestão Fiscal e Financeira`,
  description: SITE_DESCRIPTION,
  keywords: ['gestão fiscal', 'notas fiscais', 'pedidos', 'pagamentos', 'PIX', 'Brasil'],
  metadataBase: new URL(SITE_URL),
  openGraph: {
    title: `${SITE_NAME} - Plataforma Completa de Gestão`,
    description: SITE_DESCRIPTION,
    url: SITE_URL,
    siteName: SITE_NAME,
    type: 'website',
    locale: 'pt_BR',
    images: [
      {
        url: `${SITE_URL}/og-image.png`,
        width: 1200,
        height: 630,
        alt: `${SITE_NAME} - Gestão Fiscal e Financeira`,
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: `${SITE_NAME} - Gestão Fiscal`,
    description: SITE_DESCRIPTION,
    creator: '@ecoreport',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
  verification: {
    // Add your verification codes here when available
    // google: 'your-google-verification-code',
    // yandex: 'your-yandex-verification-code',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR">
      <head>
        {/* Preconnect to external domains for performance */}
        <link rel="preconnect" href="https://www.googletagmanager.com" />
        <link rel="preconnect" href="https://plausible.io" />
        <link rel="preconnect" href="https://connect.facebook.net" />
        <link rel="dns-prefetch" href="https://www.googletagmanager.com" />
        <link rel="dns-prefetch" href="https://plausible.io" />
        <link rel="dns-prefetch" href="https://connect.facebook.net" />
      </head>
      <body>
        <ErrorBoundary>
          <StructuredData />
          {children}
          <Analytics />
        </ErrorBoundary>
      </body>
    </html>
  );
}
