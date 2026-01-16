// ============================================
// 1. src/components/common/Button.tsx
// ============================================
'use client';

import { ButtonHTMLAttributes } from 'react';
import cn from '@/lib/cn';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary';
  size?: 'sm' | 'md' | 'lg';
  isFullWidth?: boolean;
}

export default function Button({
  variant = 'primary',
  size = 'md',
  isFullWidth = false,
  className,
  ...props
}: ButtonProps) {
  return (
    <button
      className={cn(
        'inline-flex items-center justify-center font-medium rounded-lg transition-all duration-150 focus:outline-none focus:ring-2 focus:ring-offset-2',
        // Tamanhos
        size === 'sm' && 'px-4 py-2 text-sm',
        size === 'md' && 'px-6 py-3 text-base',
        size === 'lg' && 'px-8 py-4 text-lg',
        // Variantes
        variant === 'primary' &&
          'bg-emerald-500 text-white hover:bg-emerald-600 active:bg-emerald-700 focus:ring-emerald-500',
        variant === 'secondary' &&
          'bg-transparent text-slate-900 border-2 border-slate-300 hover:bg-emerald-50 hover:border-emerald-500',
        // Full width
        isFullWidth && 'w-full',
        className
      )}
      {...props}
    />
  );
}