'use client';

import Container from '@/components/common/Container';
import Button from '@/components/common/Button';

interface CTAFinalSectionProps {
  onSignup?: () => void;
}

export default function CTAFinalSection({ onSignup }: CTAFinalSectionProps) {
  return (
    <section id="cta" className="py-20 bg-gradient-to-r from-emerald-500 to-emerald-600 text-white">
      <Container className="text-center">
        <h2 className="text-5xl font-bold mb-6">
          Pronto para simplificar sua gestão?
        </h2>
        <p className="text-xl mb-8 opacity-95 max-w-2xl mx-auto">
          Comece agora com 30 dias grátis. Sem cartão de crédito necessário. Acesso completo a todos os recursos.
        </p>
        <Button
          variant="primary"
          size="lg"
          className="bg-white text-emerald-600 hover:bg-slate-100"
          onClick={onSignup}
        >
          Começar Teste Gratuito Agora
        </Button>
      </Container>
    </section>
  );
}
