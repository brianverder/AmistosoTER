/**
 * User Domain Types
 * Tipos relacionados con usuarios
 */

export interface User {
  id: string;
  name: string;
  email: string;
  phone: string | null;
  createdAt: Date | string;
}

export interface UserProfile extends User {
  teamsCount: number;
  matchesCount: number;
  requestsCount: number;
}

export interface RegisterUserDTO {
  name: string;
  email: string;
  password: string;
  phone?: string;
}

export interface LoginCredentials {
  email: string;
  password: string;
}
