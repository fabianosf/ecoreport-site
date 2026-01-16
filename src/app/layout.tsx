import type { Metadata } from 'next';
import './globals.css';
import { SITE_NAME, SITE_DESCRIPTION, SITE_URL } from '@/lib/constants';

export const metadata: Metadata = {
  title: `${SITE_NAME} - Gestão Fiscal e Financeira`,
  description: SITE_DESCRIPTION,
  keywords: ['gestão fiscal', 'notas fiscais', 'pedidos', 'pagamentos', 'PIX', 'Brasil'],
  openGraph: {
    title: `${SITE_NAME} - Plataforma Completa de Gestão`,
    description: SITE_DESCRIPTION,
    url: SITE_URL,
    type: 'website',
    images: [
      {
        url: `${SITE_URL}/og-image.png`,
        width: 1200,
        height: 630,
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: `${SITE_NAME} - Gestão Fiscal`,
    description: SITE_DESCRIPTION,
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR">
      <body>
        {children}
      </body>
    </html>
  );
}
