interface EmptyStateProps {
  icon: string;
  title: string;
  description: string;
  actionLabel?: string;
  actionHref?: string;
}

export default function EmptyState({ 
  icon, 
  title, 
  description, 
  actionLabel, 
  actionHref 
}: EmptyStateProps) {
  return (
    <div className="card text-center py-12">
      <div className="text-6xl mb-4">{icon}</div>
      <h2 className="text-2xl font-bold text-primary mb-2">{title}</h2>
      <p className="text-gray-600 mb-6">{description}</p>
      {actionLabel && actionHref && (
        <a href={actionHref} className="btn-primary inline-block">
          {actionLabel}
        </a>
      )}
    </div>
  );
}
