import { Feature, Benefit, PricingPlan, FAQItem } from '@/types';

export const SITE_NAME = 'EcoReport';
export const SITE_DESCRIPTION = 'Plataforma completa de gestão fiscal, financeira e pedidos';
export const SITE_URL = 'https://ecoreport.app';

export const FEATURES: Feature[] = [
  {
    icon: '📊',
    title: 'Dashboard Inteligente',
    description: 'Visão geral em tempo real de vendas, pedidos, pagamentos e indicadores principais do seu negócio.',
  },
  {
    icon: '🧾',
    title: 'Notas Fiscais (NFCe)',
    description: 'Emissão, consulta e gerenciamento completo de notas fiscais eletrônicas com segurança fiscal.',
  },
  {
    icon: '📦',
    title: 'Gestão de Pedidos',
    description: 'Criação e acompanhamento de pedidos com status visual e histórico detalhado.',
  },
  {
    icon: '💳',
    title: 'Controle de Pagamentos',
    description: 'Histórico detalhado de transações com suporte a cartão, boleto, PIX e débito.',
  },
  {
    icon: '🔵',
    title: 'Transações PIX',
    description: 'Criação de cobranças PIX com QR Code automático e acompanhamento em tempo real.',
  },
  {
    icon: '📈',
    title: 'Análises e Relatórios',
    description: 'Gráficos dinâmicos, insights de vendas e relatórios filtráveis por período, cliente ou produto.',
  },
];

export const BENEFITS: Benefit[] = [
  {
    title: 'Centralizado',
    description: 'Todos os seus dados em um único lugar. Notas fiscais, pedidos, pagamentos e análises sem dispersão.',
  },
  {
    title: 'Intuitivo',
    description: 'Interface fácil de usar. Sua equipe produz desde o primeiro dia, sem curva de aprendizado.',
  },
  {
    title: 'Em Tempo Real',
    description: 'Dados atualizados automaticamente. Saiba exatamente como está seu negócio a cada momento.',
  },
  {
    title: 'Seguro e Confiável',
    description: 'Backups automáticos e compliance fiscal. Seus dados estão sempre protegidos e seguros.',
  },
];

export const PRICING_PLANS: PricingPlan[] = [
  {
    name: 'Iniciante',
    price: 49,
    period: '/mês',
    features: [
      '✓ Dashboard básico',
      '✓ 100 NFCes/mês',
      '✓ Até 50 pedidos',
      '✓ Relatórios básicos',
      '✗ PIX avançado',
    ],
    ctaText: 'Começar',
    ctaVariant: 'secondary',
  },
  {
    name: 'Profissional',
    price: 149,
    period: '/mês',
    badge: 'MAIS POPULAR',
    highlighted: true,
    features: [
      '✓ Dashboard completo',
      '✓ 1000 NFCes/mês',
      '✓ Pedidos ilimitados',
      '✓ Relatórios avançados',
      '✓ PIX com QR Code',
    ],
    ctaText: 'Iniciar Agora',
    ctaVariant: 'primary',
  },
  {
    name: 'Enterprise',
    price: 'Custom',
    period: 'Entre em contato',
    features: [
      '✓ Tudo do Profissional',
      '✓ API ilimitada',
      '✓ Suporte 24/7',
      '✓ Integrações custom',
      '✓ Análises avançadas',
    ],
    ctaText: 'Contatar Sales',
    ctaVariant: 'secondary',
  },
];

export const FAQ_ITEMS: FAQItem[] = [
  {
    question: 'Como começar com o EcoReport?',
    answer: 'Começar é simples! Crie sua conta em segundos, configure seus dados da empresa e comece a emitir notas fiscais imediatamente. Oferecemos um período de teste gratuito para você explorar todas as funcionalidades.',
  },
  {
    question: 'Os meus dados estão seguros?',
    answer: 'Sim! Seus dados estão protegidos com criptografia de nível enterprise, backups automáticos diários e compliance total com regulamentações fiscais brasileiras. Você tem controle total sobre suas informações.',
  },
  {
    question: 'Posso cancelar a qualquer momento?',
    answer: 'Absolutamente! Sem contratos de longa duração ou multas de cancelamento. Você pode cancelar sua assinatura a qualquer momento. Seus dados permanecerão acessíveis por 30 dias após o cancelamento.',
  },
  {
    question: 'Há suporte disponível?',
    answer: 'Sim! Contamos com suporte por email e chat. Planos profissionais e enterprise têm acesso a suporte prioritário. Resposta em até 2 horas para temas críticos.',
  },
  {
    question: 'É compatível com meu negócio?',
    answer: 'EcoReport funciona para qualquer tipo de negócio que necessite gerenciar notas fiscais, pedidos e pagamentos. De pequenos empreendedores a grandes empresas. Oferecemos demonstração gratuita se tiver dúvidas.',
  },
];
