'use client';

import Link from 'next/link';
import Container from '@/components/common/Container';
import Button from '@/components/common/Button';

export default function Header() {
  const handleScrollToSection = (id: string) => {
    const element = document.getElementById(id);
    element?.scrollIntoView({ behavior: 'smooth' });
  };

  return (
    <header className="sticky top-0 z-50 bg-white border-b border-slate-200 shadow-sm">
      <Container className="py-4 flex justify-between items-center">
        <Link href="/" className="flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-br from-emerald-400 to-emerald-600 rounded-lg flex items-center justify-center text-xl font-bold text-white">
            🌱
          </div>
          <span className="text-2xl font-bold text-emerald-500">EcoReport</span>
        </Link>

        <nav className="hidden md:flex gap-4">
          <button
            onClick={() => handleScrollToSection('pricing')}
            className="text-slate-700 hover:text-emerald-600 font-medium transition-colors"
          >
            Planos
          </button>
          <Button
            variant="primary"
            size="md"
            onClick={() => handleScrollToSection('cta')}
          >
            Começar Grátis
          </Button>
        </nav>

        <div className="md:hidden">
          <Button variant="primary" size="sm">
            Iniciar
          </Button>
        </div>
      </Container>
    </header>
  );
}
