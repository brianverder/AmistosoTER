'use client';

interface LoadingStateProps {
  message?: string;
  icon?: string;
  size?: 'sm' | 'md' | 'lg';
}

export default function LoadingState({ 
  message = 'Cargando...', 
  icon = '⚽',
  size = 'md' 
}: LoadingStateProps) {
  const sizes = {
    sm: {
      icon: 'text-3xl',
      text: 'text-sm',
      container: 'py-8',
    },
    md: {
      icon: 'text-5xl',
      text: 'text-base',
      container: 'py-12',
    },
    lg: {
      icon: 'text-7xl',
      text: 'text-lg',
      container: 'py-20',
    },
  };

  const s = sizes[size];

  return (
    <div className={`flex items-center justify-center ${s.container}`}>
      <div className="text-center">
        <div className={`${s.icon} mb-4 animate-bounce`}>{icon}</div>
        <p className={`text-gray-600 font-medium ${s.text} animate-pulse`}>{message}</p>
      </div>
    </div>
  );
}
