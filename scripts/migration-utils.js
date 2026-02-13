/**
 * ============================================
 * UTILIDADES DE VALIDACIÓN PARA MIGRACIÓN
 * ============================================
 * 
 * Funciones para validar y sanitizar datos antes de insertarlos
 * en la base de datos MySQL durante el proceso de migración.
 */

/**
 * Valida que un email tenga formato correcto
 */
function isValidEmail(email) {
  if (!email || typeof email !== 'string') return false;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Valida que un teléfono tenga formato correcto
 */
function isValidPhone(phone) {
  if (!phone) return true; // Opcional
  if (typeof phone !== 'string') return false;
  // Acepta formatos: +34612345678, 612345678, etc.
  const phoneRegex = /^\+?[\d\s\-()]{9,20}$/;
  return phoneRegex.test(phone);
}

/**
 * Valida que una fecha sea válida
 */
function isValidDate(date) {
  if (!date) return true; // Permitir null/undefined para fechas opcionales
  const parsed = new Date(date);
  return parsed instanceof Date && !isNaN(parsed);
}

/**
 * Valida que un ID sea válido (CUID o UUID)
 */
function isValidId(id) {
  if (!id || typeof id !== 'string') return false;
  // CUID: empieza con 'c' seguido de caracteres alfanuméricos
  // UUID: formato estándar
  const cuidRegex = /^c[a-z0-9]{24,25}$/;
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return cuidRegex.test(id) || uuidRegex.test(id);
}

/**
 * Valida que un string no esté vacío
 */
function isNonEmptyString(str) {
  return typeof str === 'string' && str.trim().length > 0;
}

/**
 * Valida que un número esté en un rango
 */
function isInRange(num, min, max) {
  if (typeof num !== 'number') return false;
  return num >= min && num <= max;
}

/**
 * Esquemas de validación por tipo de entidad
 */
const VALIDATION_SCHEMAS = {
  user: {
    id: (val) => isValidId(val),
    email: (val) => isValidEmail(val),
    password: (val) => isNonEmptyString(val) && val.length >= 6,
    name: (val) => isNonEmptyString(val) && val.length <= 100,
    phone: (val) => isValidPhone(val),
    createdAt: (val) => isValidDate(val),
    updatedAt: (val) => isValidDate(val)
  },
  
  team: {
    id: (val) => isValidId(val),
    name: (val) => isNonEmptyString(val) && val.length <= 100,
    userId: (val) => isValidId(val),
    gamesWon: (val) => val === null || val === undefined || (typeof val === 'number' && val >= 0),
    gamesLost: (val) => val === null || val === undefined || (typeof val === 'number' && val >= 0),
    gamesDraw: (val) => val === null || val === undefined || (typeof val === 'number' && val >= 0),
    totalGames: (val) => val === null || val === undefined || (typeof val === 'number' && val >= 0),
    createdAt: (val) => isValidDate(val),
    updatedAt: (val) => isValidDate(val)
  },
  
  matchRequest: {
    id: (val) => isValidId(val),
    userId: (val) => isValidId(val),
    teamId: (val) => isValidId(val),
    footballType: (val) => ['5', '7', '11'].includes(val),
    fieldAddress: (val) => isNonEmptyString(val),
    fieldName: (val) => !val || isNonEmptyString(val),
    date: (val) => !val || isValidDate(val),
    time: (val) => !val || typeof val === 'string',
    status: (val) => ['active', 'matched', 'cancelled'].includes(val),
    createdAt: (val) => isValidDate(val),
    updatedAt: (val) => isValidDate(val)
  },
  
  match: {
    id: (val) => isValidId(val),
    matchRequestId: (val) => !val || isValidId(val),
    team1Id: (val) => isValidId(val),
    team2Id: (val) => isValidId(val),
    userId1: (val) => isValidId(val),
    userId2: (val) => isValidId(val),
    status: (val) => ['pending', 'confirmed', 'completed', 'cancelled'].includes(val),
    proposedDate: (val) => !val || isValidDate(val),
    finalDate: (val) => !val || isValidDate(val),
    fieldAddress: (val) => !val || isNonEmptyString(val),
    fieldName: (val) => !val || isNonEmptyString(val),
    createdAt: (val) => isValidDate(val),
    updatedAt: (val) => isValidDate(val)
  },
  
  matchResult: {
    id: (val) => isValidId(val),
    matchId: (val) => isValidId(val),
    team1Score: (val) => typeof val === 'number' && isInRange(val, 0, 99),
    team2Score: (val) => typeof val === 'number' && isInRange(val, 0, 99),
    winnerId: (val) => !val || isValidId(val),
    createdAt: (val) => isValidDate(val),
    updatedAt: (val) => isValidDate(val)
  }
};

/**
 * Valida un objeto según su tipo
 * 
 * @param {string} type - Tipo de entidad (user, team, matchRequest, etc.)
 * @param {object} data - Datos a validar
 * @returns {object} { valid: boolean, errors: string[] }
 */
function validateMigrationData(type, data) {
  const schema = VALIDATION_SCHEMAS[type];
  
  if (!schema) {
    return {
      valid: false,
      errors: [`Tipo de entidad desconocido: ${type}`]
    };
  }
  
  if (!data || typeof data !== 'object') {
    return {
      valid: false,
      errors: ['Los datos deben ser un objeto']
    };
  }
  
  const errors = [];
  
  // Validar cada campo según el schema
  for (const [field, validator] of Object.entries(schema)) {
    const value = data[field];
    
    try {
      const isValid = validator(value);
      
      if (!isValid) {
        errors.push(`Campo '${field}' inválido: ${JSON.stringify(value)}`);
      }
    } catch (error) {
      errors.push(`Error validando campo '${field}': ${error.message}`);
    }
  }
  
  return {
    valid: errors.length === 0,
    errors
  };
}

/**
 * Sanitiza un string eliminando caracteres peligrosos
 */
function sanitizeString(str) {
  if (!str || typeof str !== 'string') return str;
  
  // Eliminar espacios al inicio/fin
  let sanitized = str.trim();
  
  // Eliminar caracteres de control ASCII (excepto saltos de línea y tabs)
  sanitized = sanitized.replace(/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]/g, '');
  
  // Limitar longitud
  if (sanitized.length > 1000) {
    sanitized = sanitized.substring(0, 1000);
  }
  
  return sanitized;
}

/**
 * Sanitiza un objeto completo recursivamente
 */
function sanitizeData(data) {
  if (!data || typeof data !== 'object') return data;
  
  const sanitized = {};
  
  for (const [key, value] of Object.entries(data)) {
    if (value === null || value === undefined) {
      sanitized[key] = value;
    } else if (typeof value === 'string') {
      sanitized[key] = sanitizeString(value);
    } else if (typeof value === 'number') {
      // Validar que sea un número válido
      sanitized[key] = isNaN(value) ? 0 : value;
    } else if (typeof value === 'boolean') {
      sanitized[key] = value;
    } else if (value instanceof Date) {
      sanitized[key] = value;
    } else if (Array.isArray(value)) {
      sanitized[key] = value.map(item => 
        typeof item === 'string' ? sanitizeString(item) : item
      );
    } else if (typeof value === 'object') {
      sanitized[key] = sanitizeData(value);
    } else {
      sanitized[key] = value;
    }
  }
  
  return sanitized;
}

/**
 * Normaliza las fechas al formato correcto
 */
function normalizeDates(data) {
  const normalized = { ...data };
  
  const dateFields = ['createdAt', 'updatedAt', 'date', 'proposedDate', 'finalDate'];
  
  for (const field of dateFields) {
    if (normalized[field]) {
      // Convertir a objeto Date si es string
      if (typeof normalized[field] === 'string') {
        normalized[field] = new Date(normalized[field]);
      }
      
      // Si la fecha es inválida, usar fecha actual
      if (isNaN(normalized[field])) {
        console.warn(`⚠️  Fecha inválida en campo '${field}', usando fecha actual`);
        normalized[field] = new Date();
      }
    }
  }
  
  return normalized;
}

/**
 * Valida la integridad referencial de un registro
 * (verifica que las FK apunten a registros existentes)
 */
async function validateReferences(type, data, prismaClient) {
  const errors = [];
  
  try {
    switch (type) {
      case 'team':
        if (data.userId) {
          const user = await prismaClient.user.findUnique({ where: { id: data.userId } });
          if (!user) errors.push(`Usuario ${data.userId} no existe`);
        }
        break;
        
      case 'matchRequest':
        if (data.userId) {
          const user = await prismaClient.user.findUnique({ where: { id: data.userId } });
          if (!user) errors.push(`Usuario ${data.userId} no existe`);
        }
        if (data.teamId) {
          const team = await prismaClient.team.findUnique({ where: { id: data.teamId } });
          if (!team) errors.push(`Equipo ${data.teamId} no existe`);
        }
        break;
        
      case 'match':
        if (data.matchRequestId) {
          const request = await prismaClient.matchRequest.findUnique({ where: { id: data.matchRequestId } });
          if (!request) errors.push(`Solicitud ${data.matchRequestId} no existe`);
        }
        if (data.team1Id) {
          const team = await prismaClient.team.findUnique({ where: { id: data.team1Id } });
          if (!team) errors.push(`Equipo1 ${data.team1Id} no existe`);
        }
        if (data.team2Id) {
          const team = await prismaClient.team.findUnique({ where: { id: data.team2Id } });
          if (!team) errors.push(`Equipo2 ${data.team2Id} no existe`);
        }
        if (data.userId1) {
          const user = await prismaClient.user.findUnique({ where: { id: data.userId1 } });
          if (!user) errors.push(`Usuario1 ${data.userId1} no existe`);
        }
        if (data.userId2) {
          const user = await prismaClient.user.findUnique({ where: { id: data.userId2 } });
          if (!user) errors.push(`Usuario2 ${data.userId2} no existe`);
        }
        break;
        
      case 'matchResult':
        if (data.matchId) {
          const match = await prismaClient.match.findUnique({ where: { id: data.matchId } });
          if (!match) errors.push(`Partido ${data.matchId} no existe`);
        }
        if (data.winnerId) {
          const team = await prismaClient.team.findUnique({ where: { id: data.winnerId } });
          if (!team) errors.push(`Equipo ganador ${data.winnerId} no existe`);
        }
        break;
    }
  } catch (error) {
    errors.push(`Error verificando referencias: ${error.message}`);
  }
  
  return {
    valid: errors.length === 0,
    errors
  };
}

/**
 * Verifica si un registro ya existe en la base de datos
 */
async function recordExists(type, id, prismaClient) {
  try {
    const model = prismaClient[type];
    if (!model) return false;
    
    const record = await model.findUnique({ where: { id } });
    return !!record;
  } catch (error) {
    console.error(`Error verificando existencia de ${type}:`, error);
    return false;
  }
}

/**
 * Prepara datos para inserción eliminando campos undefined
 */
function prepareForInsert(data) {
  const prepared = {};
  
  for (const [key, value] of Object.entries(data)) {
    // Solo incluir valores definidos
    if (value !== undefined) {
      prepared[key] = value;
    }
  }
  
  return prepared;
}

module.exports = {
  validateMigrationData,
  sanitizeData,
  sanitizeString,
  normalizeDates,
  validateReferences,
  recordExists,
  prepareForInsert,
  isValidEmail,
  isValidPhone,
  isValidDate,
  isValidId,
  isNonEmptyString,
  isInRange
};
