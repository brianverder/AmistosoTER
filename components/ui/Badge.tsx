/**
 * Badge Component
 * Componente reutilizable para badges de estado
 */

import React from 'react';

interface BadgeProps {
  text: string;
  icon?: string;
  className?: string;
}

export function Badge({ text, icon, className = '' }: BadgeProps) {
  return (
    <span className={`px-3 py-1 text-xs font-semibold flex items-center gap-1 ${className}`}>
      {icon && <span>{icon}</span>}
      <span>{text}</span>
    </span>
  );
}
