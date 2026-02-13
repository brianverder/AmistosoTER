interface StatusBadgeProps {
  status: 'active' | 'matched' | 'completed' | 'cancelled' | 'pending';
  size?: 'sm' | 'md' | 'lg';
}

export default function StatusBadge({ status, size = 'md' }: StatusBadgeProps) {
  const badges = {
    active: { text: 'Activa', class: 'bg-green-100 text-green-800 border-green-200' },
    matched: { text: 'Matched', class: 'bg-blue-100 text-blue-800 border-blue-200' },
    completed: { text: 'Completada', class: 'bg-gray-100 text-gray-800 border-gray-200' },
    cancelled: { text: 'Cancelada', class: 'bg-red-100 text-red-800 border-red-200' },
    pending: { text: 'Pendiente', class: 'bg-yellow-100 text-yellow-800 border-yellow-200' },
  };

  const sizeClasses = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-3 py-1 text-xs',
    lg: 'px-4 py-2 text-sm',
  };

  const badge = badges[status];

  return (
    <span className={`${badge.class} ${sizeClasses[size]} rounded-full font-semibold border inline-block`}>
      {badge.text}
    </span>
  );
}
