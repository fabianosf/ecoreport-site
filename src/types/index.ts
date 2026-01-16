export interface Feature {
  icon: string;
  title: string;
  description: string;
}

export interface Benefit {
  title: string;
  description: string;
}

export interface PricingPlan {
  name: string;
  price: number | string;
  period: string;
  badge?: string;
  highlighted?: boolean;
  features: string[];
  ctaText: string;
  ctaVariant: 'primary' | 'secondary';
}

export interface FAQItem {
  question: string;
  answer: string;
}
