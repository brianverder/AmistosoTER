'use client';

import { useEffect } from 'react';

export type ToastType = 'success' | 'error' | 'info' | 'warning';

interface ToastProps {
  message: string;
  type?: ToastType;
  onClose: () => void;
  duration?: number;
}

export default function Toast({ message, type = 'info', onClose, duration = 4000 }: ToastProps) {
  useEffect(() => {
    const timer = setTimeout(() => {
      onClose();
    }, duration);

    return () => clearTimeout(timer);
  }, [duration, onClose]);

  const styles = {
    success: {
      bg: 'bg-green-50 border-green-500',
      icon: '✅',
      text: 'text-green-900',
      title: '¡Éxito!',
    },
    error: {
      bg: 'bg-red-50 border-red-500',
      icon: '❌',
      text: 'text-red-900',
      title: 'Error',
    },
    warning: {
      bg: 'bg-yellow-50 border-yellow-500',
      icon: '⚠️',
      text: 'text-yellow-900',
      title: 'Atención',
    },
    info: {
      bg: 'bg-blue-50 border-blue-500',
      icon: 'ℹ️',
      text: 'text-blue-900',
      title: 'Información',
    },
  };

  const style = styles[type];

  return (
    <div
      className={`fixed top-4 right-4 z-50 ${style.bg} border-l-4 p-4 rounded-lg shadow-lg max-w-md animate-fadeIn`}
      role="alert"
    >
      <div className="flex items-start gap-3">
        <span className="text-2xl flex-shrink-0">{style.icon}</span>
        <div className="flex-1">
          <p className={`font-bold ${style.text} mb-1`}>{style.title}</p>
          <p className={`text-sm ${style.text}`}>{message}</p>
        </div>
        <button
          onClick={onClose}
          className={`${style.text} hover:opacity-70 text-xl leading-none`}
          aria-label="Cerrar"
        >
          ×
        </button>
      </div>
    </div>
  );
}
