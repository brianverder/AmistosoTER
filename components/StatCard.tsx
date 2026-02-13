'use client';

interface StatCardProps {
  label: string;
  value: number | string;
  icon: string;
  color?: string;
  href?: string;
}

export default function StatCard({ label, value, icon, color = 'bg-primary', href }: StatCardProps) {
  const CardContent = () => (
    <>
      <div>
        <p className="text-gray-600 mb-1 text-sm font-medium">{label}</p>
        <p className="text-4xl font-bold text-primary">{value}</p>
      </div>
      <div className={`w-16 h-16 ${color} rounded-2xl flex items-center justify-center text-3xl shadow-sm`}>
        {icon}
      </div>
    </>
  );

  if (href) {
    return (
      <a
        href={href}
        className="card hover:scale-105 hover:shadow-lg transition-all cursor-pointer block"
      >
        <div className="flex items-center justify-between">
          <CardContent />
        </div>
      </a>
    );
  }

  return (
    <div className="card">
      <div className="flex items-center justify-between">
        <CardContent />
      </div>
    </div>
  );
}
