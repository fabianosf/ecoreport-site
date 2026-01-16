'use client';

import Container from '@/components/common/Container';
import { BENEFITS } from '@/lib/constants';

export default function BenefitsSection() {
  return (
    <section className="py-20 bg-gradient-to-b from-white to-slate-50">
      <Container>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div>
            <h2 className="text-5xl font-bold text-slate-900 mb-12">
              Por que escolher o EcoReport?
            </h2>
            {BENEFITS.map((benefit, index) => (
              <div key={index} className="flex gap-4 mb-8">
                <div className="flex-shrink-0">
                  <div className="flex h-8 w-8 items-center justify-center rounded-full bg-emerald-500 text-white font-bold">
                    ✓
                  </div>
                </div>
                <div>
                  <h3 className="text-xl font-semibold text-slate-900 mb-2">
                    {benefit.title}
                  </h3>
                  <p className="text-slate-600">
                    {benefit.description}
                  </p>
                </div>
              </div>
            ))}
          </div>
          <div>
            <img
              src="https://agi-prod-file-upload-public-main-use1.s3.amazonaws.com/ab8cbb05-97e7-491e-95a7-c34cdccd86be"
              alt="Funcionalidades"
              className="rounded-2xl shadow-2xl"
            />
          </div>
        </div>
      </Container>
    </section>
  );
}
