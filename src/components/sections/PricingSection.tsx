'use client';

import Container from '@/components/common/Container';
import SectionHeader from '@/components/common/SectionHeader';
import Button from '@/components/common/Button';
import Badge from '@/components/common/Badge';
import { PRICING_PLANS } from '@/lib/constants';

interface PricingSectionProps {
  onSignup?: () => void;
}

export default function PricingSection({ onSignup }: PricingSectionProps) {
  return (
    <section id="pricing" className="py-20 bg-white">
      <Container>
        <SectionHeader
          title="Planos Simples e Transparentes"
          subtitle="Escolha o plano perfeito para seu negócio. Sem contratos longos, cancele quando quiser."
        />
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {PRICING_PLANS.map((plan, index) => (
            <div
              key={index}
              className={`rounded-xl p-8 transition-all duration-300 ${
                plan.highlighted
                  ? 'border-2 border-emerald-500 shadow-2xl lg:scale-105'
                  : 'border-2 border-slate-200 hover:shadow-lg'
              } bg-white`}
            >
              {plan.badge && <Badge>{plan.badge}</Badge>}
              <h3 className="text-2xl font-bold text-slate-900 mb-2">
                {plan.name}
              </h3>
              <div className="mb-8">
                <div className="text-5xl font-bold text-emerald-500">
                  {typeof plan.price === 'number' ? `R$ ${plan.price}` : plan.price}
                </div>
                <div className="text-slate-600">{plan.period}</div>
              </div>
              <ul className="space-y-3 mb-8">
                {plan.features.map((feature, idx) => (
                  <li key={idx} className="text-slate-600 text-sm">
                    {feature}
                  </li>
                ))}
              </ul>
              <Button
                variant={plan.ctaVariant}
                size="lg"
                isFullWidth
                onClick={onSignup}
              >
                {plan.ctaText}
              </Button>
            </div>
          ))}
        </div>
      </Container>
    </section>
  );
}
