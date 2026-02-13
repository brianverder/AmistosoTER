/**
 * Input Component
 * Componente reutilizable de input con label
 */

import React from 'react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  helperText?: string;
}

export function Input({
  label,
  error,
  helperText,
  className = '',
  ...props
}: InputProps) {
  return (
    <div className="mb-4">
      {label && (
        <label className="label">
          {label}
          {props.required && <span className="text-red-600 ml-1">*</span>}
        </label>
      )}
      <input
        className={`input ${error ? 'border-red-600' : ''} ${className}`}
        {...props}
      />
      {error && (
        <p className="text-red-600 text-xs mt-1">{error}</p>
      )}
      {helperText && !error && (
        <p className="text-gray-500 text-xs mt-1">{helperText}</p>
      )}
    </div>
  );
}
