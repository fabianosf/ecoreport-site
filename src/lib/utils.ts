export function formatPrice(price: number): string {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(price);
}

export function formatDate(date: Date): string {
  return new Intl.DateTimeFormat('pt-BR').format(date);
}

export function scrollToElement(elementId: string): void {
  const element = document.getElementById(elementId);
  element?.scrollIntoView({ behavior: 'smooth' });
}
