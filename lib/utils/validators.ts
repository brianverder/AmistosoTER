/**
 * Utility Functions - Validators
 * Funciones de validación
 */

/**
 * Valida un email
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Valida un teléfono argentino
 */
export function isValidPhone(phone: string): boolean {
  // Formato argentino: +54 9 11 1234-5678 o variantes
  const phoneRegex = /^(\+?54)?[\s-]?9?[\s-]?\d{2,4}[\s-]?\d{4}[\s-]?\d{4}$/;
  return phoneRegex.test(phone);
}

/**
 * Valida una contraseña segura
 */
export function isValidPassword(password: string): { valid: boolean; message?: string } {
  if (password.length < 8) {
    return { valid: false, message: 'La contraseña debe tener al menos 8 caracteres' };
  }
  
  if (!/[A-Z]/.test(password)) {
    return { valid: false, message: 'Debe incluir al menos una mayúscula' };
  }
  
  if (!/[a-z]/.test(password)) {
    return { valid: false, message: 'Debe incluir al menos una minúscula' };
  }
  
  if (!/[0-9]/.test(password)) {
    return { valid: false, message: 'Debe incluir al menos un número' };
  }
  
  return { valid: true };
}

/**
 * Valida un nombre de equipo
 */
export function isValidTeamName(name: string): { valid: boolean; message?: string } {
  if (!name || name.trim().length === 0) {
    return { valid: false, message: 'El nombre no puede estar vacío' };
  }
  
  if (name.length < 3) {
    return { valid: false, message: 'El nombre debe tener al menos 3 caracteres' };
  }
  
  if (name.length > 50) {
    return { valid: false, message: 'El nombre no puede exceder 50 caracteres' };
  }
  
  return { valid: true };
}

/**
 * Valida un resultado de partido
 */
export function isValidScore(score: number): { valid: boolean; message?: string } {
  if (score < 0) {
    return { valid: false, message: 'El marcador no puede ser negativo' };
  }
  
  if (score > 99) {
    return { valid: false, message: 'El marcador no puede exceder 99' };
  }
  
  if (!Number.isInteger(score)) {
    return { valid: false, message: 'El marcador debe ser un número entero' };
  }
  
  return { valid: true };
}

/**
 * Sanitiza un input de texto
 */
export function sanitizeInput(input: string): string {
  return input.trim().replace(/[<>]/g, '');
}
