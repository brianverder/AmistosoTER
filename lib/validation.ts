/**
 * Validadores centralizados para inputs de usuario
 * Protección contra XSS, SQL Injection y validación de formato
 */

// Expresiones regulares seguras
const EMAIL_REGEX = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
const PHONE_REGEX = /^[\d\s\-\+\(\)]{7,20}$/;
const NAME_REGEX = /^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]{2,100}$/;
const SAFE_STRING_REGEX = /^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ\s\-_.,!?¡¿]{1,500}$/;

/**
 * Sanitiza strings para prevenir XSS
 * Elimina caracteres peligrosos pero preserva tildes y ñ
 */
export function sanitizeString(input: string): string {
  if (typeof input !== 'string') return '';
  
  return input
    .trim()
    .replace(/<script[^>]*>.*?<\/script>/gi, '') // Remove scripts
    .replace(/<[^>]+>/g, '') // Remove HTML tags
    .replace(/javascript:/gi, '') // Remove javascript: protocol
    .replace(/on\w+\s*=/gi, '') // Remove event handlers
    .slice(0, 1000); // Max length
}

/**
 * Valida y sanitiza email
 */
export interface ValidateEmailResult {
  isValid: boolean;
  sanitized: string;
  error?: string;
}

export function validateEmail(email: string): ValidateEmailResult {
  if (!email || typeof email !== 'string') {
    return { isValid: false, sanitized: '', error: 'Email es requerido' };
  }

  const sanitized = email.trim().toLowerCase().slice(0, 255);

  if (!EMAIL_REGEX.test(sanitized)) {
    return { isValid: false, sanitized, error: 'Formato de email inválido' };
  }

  // Lista negra de dominios temporales (opcional)
  const temporaryDomains = ['tempmail.com', '10minutemail.com', 'guerrillamail.com'];
  const domain = sanitized.split('@')[1];
  if (temporaryDomains.includes(domain)) {
    return { isValid: false, sanitized, error: 'No se permiten emails temporales' };
  }

  return { isValid: true, sanitized };
}

/**
 * Valida fuerza de contraseña
 */
export interface ValidatePasswordResult {
  isValid: boolean;
  error?: string;
  strength?: 'weak' | 'medium' | 'strong';
}

export function validatePassword(password: string): ValidatePasswordResult {
  if (!password || typeof password !== 'string') {
    return { isValid: false, error: 'Contraseña es requerida' };
  }

  // Mínimo 6 caracteres
  if (password.length < 6) {
    return { isValid: false, error: 'La contraseña debe tener al menos 6 caracteres' };
  }

  // Máximo 72 caracteres (límite de bcrypt)
  if (password.length > 72) {
    return { isValid: false, error: 'La contraseña no puede exceder 72 caracteres' };
  }

  // Calcular fuerza basada solo en longitud
  let strength: 'weak' | 'medium' | 'strong' = 'weak';
  if (password.length >= 12) {
    strength = 'strong';
  } else if (password.length >= 8) {
    strength = 'medium';
  }

  return { isValid: true, strength };
}

/**
 * Valida nombre de persona o equipo
 */
export interface ValidateNameResult {
  isValid: boolean;
  sanitized: string;
  error?: string;
}

export function validateName(name: string): ValidateNameResult {
  if (!name || typeof name !== 'string') {
    return { isValid: false, sanitized: '', error: 'Nombre es requerido' };
  }

  const sanitized = sanitizeString(name).slice(0, 255);

  if (sanitized.length < 2) {
    return { isValid: false, sanitized, error: 'El nombre debe tener al menos 2 caracteres' };
  }

  if (!NAME_REGEX.test(sanitized)) {
    return { isValid: false, sanitized, error: 'El nombre contiene caracteres no permitidos' };
  }

  return { isValid: true, sanitized };
}

/**
 * Valida teléfono
 */
export interface ValidatePhoneResult {
  isValid: boolean;
  sanitized: string | null;
  error?: string;
}

export function validatePhone(phone: string | null | undefined): ValidatePhoneResult {
  // El teléfono es obligatorio
  if (!phone || phone.trim() === '') {
    return { isValid: false, sanitized: null, error: 'El teléfono es obligatorio' };
  }

  const sanitized = phone.trim().slice(0, 50);

  if (!PHONE_REGEX.test(sanitized)) {
    return { isValid: false, sanitized, error: 'Formato de teléfono inválido' };
  }

  return { isValid: true, sanitized };
}

/**
 * Valida texto libre (descripción, dirección)
 */
export interface ValidateTextResult {
  isValid: boolean;
  sanitized: string;
  error?: string;
}

export function validateText(
  text: string | null | undefined,
  options: { required?: boolean; maxLength?: number } = {}
): ValidateTextResult {
  const { required = false, maxLength = 500 } = options;

  if (!text || text.trim() === '') {
    if (required) {
      return { isValid: false, sanitized: '', error: 'Este campo es requerido' };
    }
    return { isValid: true, sanitized: '' };
  }

  const sanitized = sanitizeString(text).slice(0, maxLength);

  if (sanitized.length === 0 && required) {
    return { isValid: false, sanitized, error: 'El texto no es válido' };
  }

  return { isValid: true, sanitized };
}

/**
 * Valida precio
 */
export interface ValidatePriceResult {
  isValid: boolean;
  value: number | null;
  error?: string;
}

export function validatePrice(price: number | null | undefined): ValidatePriceResult {
  // El precio es opcional
  if (price === null || price === undefined) {
    return { isValid: true, value: null };
  }

  if (typeof price !== 'number' || isNaN(price)) {
    return { isValid: false, value: null, error: 'El precio debe ser un número' };
  }

  if (price < 0) {
    return { isValid: false, value: null, error: 'El precio no puede ser negativo' };
  }

  if (price > 1000000) {
    return { isValid: false, value: null, error: 'El precio es demasiado alto' };
  }

  // Redondear a 2 decimales
  const rounded = Math.round(price * 100) / 100;

  return { isValid: true, value: rounded };
}

/**
 * Valida fecha
 */
export interface ValidateDateResult {
  isValid: boolean;
  date: Date | null;
  error?: string;
}

export function validateDate(
  date: string | Date | null | undefined,
  options: { allowPast?: boolean; maxFutureDays?: number } = {}
): ValidateDateResult {
  const { allowPast = false, maxFutureDays = 365 } = options;

  // La fecha es opcional
  if (!date) {
    return { isValid: true, date: null };
  }

  let parsedDate: Date;
  try {
    parsedDate = new Date(date);
    if (isNaN(parsedDate.getTime())) {
      return { isValid: false, date: null, error: 'Fecha inválida' };
    }
  } catch {
    return { isValid: false, date: null, error: 'Fecha inválida' };
  }

  const now = new Date();
  const maxFuture = new Date();
  maxFuture.setDate(maxFuture.getDate() + maxFutureDays);

  if (!allowPast && parsedDate < now) {
    return { isValid: false, date: null, error: 'La fecha no puede estar en el pasado' };
  }

  if (parsedDate > maxFuture) {
    return { isValid: false, date: null, error: `La fecha no puede estar a más de ${maxFutureDays} días en el futuro` };
  }

  return { isValid: true, date: parsedDate };
}

/**
 * Valida footballType
 */
export type FootballType = 'ELEVEN' | 'EIGHT' | 'SEVEN' | 'FIVE' | 'OTHER';

export interface ValidateFootballTypeResult {
  isValid: boolean;
  value: FootballType | null;
  error?: string;
}

export function validateFootballType(type: string | null | undefined): ValidateFootballTypeResult {
  // Es opcional
  if (!type) {
    return { isValid: true, value: null };
  }

  const validTypes: FootballType[] = ['ELEVEN', 'EIGHT', 'SEVEN', 'FIVE', 'OTHER'];
  const upperType = type.toUpperCase() as FootballType;

  if (!validTypes.includes(upperType)) {
    return { isValid: false, value: null, error: 'Tipo de fútbol inválido' };
  }

  return { isValid: true, value: upperType };
}

/**
 * Valida ID (cuid)
 */
export interface ValidateIdResult {
  isValid: boolean;
  error?: string;
}

export function validateId(id: string | undefined): ValidateIdResult {
  if (!id || typeof id !== 'string') {
    return { isValid: false, error: 'ID es requerido' };
  }

  // cuid format: 25 caracteres alfanuméricos que empiezan con 'c'
  const cuidRegex = /^c[a-z0-9]{24}$/;
  
  if (!cuidRegex.test(id)) {
    return { isValid: false, error: 'ID tiene formato inválido' };
  }

  return { isValid: true };
}

/**
 * Valida paginación
 */
export interface ValidatePaginationResult {
  isValid: boolean;
  take: number;
  skip: number;
  error?: string;
}

export function validatePagination(
  page?: string | number,
  limit?: string | number
): ValidatePaginationResult {
  const pageNum = typeof page === 'string' ? parseInt(page, 10) : (page || 1);
  const limitNum = typeof limit === 'string' ? parseInt(limit, 10) : (limit || 10);

  if (isNaN(pageNum) || pageNum < 1) {
    return { isValid: false, take: 10, skip: 0, error: 'Página inválida' };
  }

  if (isNaN(limitNum) || limitNum < 1 || limitNum > 100) {
    return { isValid: false, take: 10, skip: 0, error: 'Límite debe estar entre 1 y 100' };
  }

  const skip = (pageNum - 1) * limitNum;
  const take = limitNum;

  return { isValid: true, take, skip };
}

/**
 * Helper para construir respuesta de error de validación
 */
export function validationError(message: string, field?: string) {
  return {
    error: message,
    field,
    timestamp: new Date().toISOString()
  };
}
