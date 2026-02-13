/**
 * Payment Domain Types
 * Tipos para sistema de pagos (PREPARADO PARA FUTURO)
 */

export type PaymentStatus = 'pending' | 'processing' | 'completed' | 'failed' | 'refunded';
export type PaymentMethod = 'credit_card' | 'debit_card' | 'paypal' | 'mercadopago' | 'bank_transfer';
export type TransactionType = 'field_rental' | 'membership' | 'tournament' | 'referee' | 'other';

export interface Payment {
  id: string;
  userId: string;
  matchId?: string | null;
  amount: number;
  currency: string;
  type: TransactionType;
  method: PaymentMethod;
  status: PaymentStatus;
  reference: string;
  metadata?: Record<string, any>;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export interface CreatePaymentDTO {
  matchId?: string;
  amount: number;
  type: TransactionType;
  method: PaymentMethod;
  metadata?: Record<string, any>;
}

export interface PaymentIntent {
  id: string;
  amount: number;
  currency: string;
  clientSecret: string;
}

export interface Invoice {
  id: string;
  paymentId: string;
  invoiceNumber: string;
  pdfUrl: string;
  createdAt: Date | string;
}
