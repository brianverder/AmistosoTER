/**
 * Utility Functions - Formatters
 * Funciones para formatear datos
 */

/**
 * Formatea una fecha a formato español legible
 */
export function formatDate(date: Date | string | null, includeTime = false): string {
  if (!date) return '-';
  
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  
  const options: Intl.DateTimeFormatOptions = {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  };
  
  if (includeTime) {
    options.hour = '2-digit';
    options.minute = '2-digit';
  }
  
  return dateObj.toLocaleDateString('es-ES', options);
}

/**
 * Formatea una fecha relativa (hace X días)
 */
export function formatRelativeDate(date: Date | string): string {
  const dateObj = typeof date === 'string' ? new Date(date) : date;
  const now = new Date();
  const diffMs = now.getTime() - dateObj.getTime();
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) return 'Hoy';
  if (diffDays === 1) return 'Ayer';
  if (diffDays < 7) return `Hace ${diffDays} días`;
  if (diffDays < 30) return `Hace ${Math.floor(diffDays / 7)} semanas`;
  if (diffDays < 365) return `Hace ${Math.floor(diffDays / 30)} meses`;
  return `Hace ${Math.floor(diffDays / 365)} años`;
}

/**
 * Formatea un precio en moneda
 */
export function formatCurrency(amount: number | null, currency = 'ARS'): string {
  if (amount === null) return '-';
  
  return new Intl.NumberFormat('es-AR', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

/**
 * Formatea un porcentaje
 */
export function formatPercentage(value: number, decimals = 1): string {
  return `${value.toFixed(decimals)}%`;
}

/**
 * Formatea un número grande con separadores
 */
export function formatNumber(value: number): string {
  return new Intl.NumberFormat('es-AR').format(value);
}

/**
 * Trunca un texto largo
 */
export function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength) + '...';
}

/**
 * Formatea el tipo de fútbol
 */
export function formatFootballType(type: string | null): string {
  if (!type) return 'No especificado';
  if (type === 'otro') return 'Otro';
  return `Fútbol ${type}`;
}
