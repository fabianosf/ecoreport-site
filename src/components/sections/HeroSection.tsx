'use client';

import Container from '@/components/common/Container';
import Button from '@/components/common/Button';

interface HeroSectionProps {
  onSignup?: () => void;
}

export default function HeroSection({ onSignup }: HeroSectionProps) {
  return (
    <section className="py-20 bg-gradient-to-b from-slate-50 to-white overflow-hidden">
      <Container>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div>
            <h1 className="text-5xl lg:text-6xl font-bold text-slate-900 leading-tight mb-6">
              Transformando dados em{' '}
              <span className="bg-gradient-to-r from-emerald-400 to-emerald-600 bg-clip-text text-transparent">
                crescimento sustentável
              </span>
            </h1>
            <p className="text-xl text-slate-600 mb-8 leading-relaxed">
              Plataforma completa de gestão fiscal, financeira e pedidos. Centralize notas fiscais, pedidos, pagamentos e análises em um único lugar intuitivo e poderoso.
            </p>
            <div className="flex flex-col sm:flex-row gap-4">
              <Button 
                variant="primary" 
                size="lg"
                onClick={onSignup}
              >
                Iniciar Teste Gratuito
              </Button>
              <Button variant="secondary" size="lg">
                Ver Demo
              </Button>
            </div>
          </div>
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-r from-emerald-400 to-emerald-600 rounded-2xl opacity-10 blur-3xl"></div>
            <img
              src="https://agi-prod-file-upload-public-main-use1.s3.amazonaws.com/ab8cbb05-97e7-491e-95a7-c34cdccd86be"
              alt="EcoReport Dashboard"
              className="relative z-10 rounded-2xl shadow-2xl"
            />
          </div>
        </div>
      </Container>
    </section>
  );
}
