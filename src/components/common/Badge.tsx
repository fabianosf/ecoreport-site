'use client';

interface BadgeProps {
  children: React.ReactNode;
}

export default function Badge({ children }: BadgeProps) {
  return (
    <div className="inline-block bg-gradient-to-r from-emerald-400 to-emerald-500 text-white px-4 py-2 rounded-full text-sm font-semibold mb-4">
      {children}
    </div>
  );
}
