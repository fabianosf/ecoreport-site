'use client';

interface SectionHeaderProps {
  title: string;      // ← OBRIGATÓRIO
  subtitle?: string;  // ← OPCIONAL
}

export default function SectionHeader({ 
  title, 
  subtitle 
}: SectionHeaderProps) {
  return (
    <div className="text-center mb-16">
      <h2 className="text-4xl sm:text-5xl font-bold text-slate-900 mb-4">
        {title}
      </h2>
      {subtitle && (
        <p className="text-lg text-slate-500 max-w-2xl mx-auto">
          {subtitle}
        </p>
      )}
    </div>
  );
}
