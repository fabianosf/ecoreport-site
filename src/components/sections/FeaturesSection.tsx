'use client';

import Container from '@/components/common/Container';
import SectionHeader from '@/components/common/SectionHeader';
import { FEATURES } from '@/lib/constants';

export default function FeaturesSection() {
  return (
    <section className="py-20 bg-white">
      <Container>
        <SectionHeader
          title="Funcionalidades Poderosas"
          subtitle="Tudo que você precisa para gerenciar seu negócio de forma profissional e eficiente"
        />
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {FEATURES.map((feature, index) => (
            <div
              key={index}
              className="p-8 rounded-xl bg-gradient-to-br from-emerald-50 to-transparent border border-slate-200 hover:border-emerald-300 hover:shadow-lg transition-all duration-300 group"
            >
              <div className="absolute inset-0 bg-gradient-to-r from-emerald-400 to-emerald-600 h-1 rounded-t-xl transform scale-x-0 group-hover:scale-x-100 transition-transform origin-left duration-300"></div>
              <div className="text-4xl mb-4">{feature.icon}</div>
              <h3 className="text-xl font-semibold text-slate-900 mb-3">
                {feature.title}
              </h3>
              <p className="text-slate-600 leading-relaxed">
                {feature.description}
              </p>
            </div>
          ))}
        </div>
      </Container>
    </section>
  );
}
