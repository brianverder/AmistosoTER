/**
 * Card Component
 * Componente reutilizable de tarjeta
 */

import React from 'react';

interface CardProps {
  children: React.ReactNode;
  className?: string;
  onClick?: () => void;
}

export function Card({ children, className = '', onClick }: CardProps) {
  const clickableClass = onClick ? 'cursor-pointer hover:shadow-xl' : '';
  
  return (
    <div 
      className={`card ${clickableClass} ${className}`}
      onClick={onClick}
    >
      {children}
    </div>
  );
}
