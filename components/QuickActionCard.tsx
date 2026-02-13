import Link from 'next/link';

interface QuickActionCardProps {
  title: string;
  description: string;
  icon: string;
  href: string;
}

export default function QuickActionCard({ title, description, icon, href }: QuickActionCardProps) {
  return (
    <Link
      href={href}
      className="p-6 border-2 border-dashed border-gray-300 rounded-lg hover:border-primary hover:bg-gray-50 transition-all text-center group"
    >
      <div className="text-4xl mb-3 group-hover:scale-110 transition-transform">{icon}</div>
      <h3 className="text-lg font-semibold text-primary group-hover:underline mb-2">
        {title}
      </h3>
      <p className="text-gray-600 text-sm">
        {description}
      </p>
    </Link>
  );
}
