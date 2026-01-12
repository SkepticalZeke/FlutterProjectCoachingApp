/**
 * AES-256-GCM Encryption Utilities
 * Provides secure encryption for sensitive data fields in Firestore
 * 
 * Uses AES-256-GCM which provides:
 * - Confidentiality (encryption)
 * - Integrity (authentication tag)
 * - Unique IV per encryption
 */

import * as crypto from 'crypto';
import { getEncryptionKey } from '../config';

// Encryption constants
const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16; // 128 bits for GCM
const AUTH_TAG_LENGTH = 16; // 128 bits

/**
 * Encrypt a plaintext string using AES-256-GCM
 * @param plaintext The text to encrypt
 * @returns Base64 encoded string containing IV + AuthTag + Ciphertext
 */
export function encrypt(plaintext: string): string {
    // Get key at runtime from Firebase Secrets
    const encryptionKey = getEncryptionKey();

    // Convert hex key to buffer
    const key = Buffer.from(encryptionKey, 'hex');

    // Generate random IV for each encryption
    const iv = crypto.randomBytes(IV_LENGTH);

    // Create cipher
    const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

    // Encrypt the plaintext
    const encrypted = Buffer.concat([
        cipher.update(plaintext, 'utf8'),
        cipher.final()
    ]);

    // Get the authentication tag
    const authTag = cipher.getAuthTag();

    // Combine IV + AuthTag + Ciphertext and encode as base64
    const combined = Buffer.concat([iv, authTag, encrypted]);

    return combined.toString('base64');
}

/**
 * Decrypt a ciphertext string using AES-256-GCM
 * @param ciphertext Base64 encoded string from encrypt()
 * @returns Original plaintext string
 */
export function decrypt(ciphertext: string): string {
    // Get key at runtime from Firebase Secrets
    const encryptionKey = getEncryptionKey();

    // Convert hex key to buffer
    const key = Buffer.from(encryptionKey, 'hex');

    // Decode base64
    const combined = Buffer.from(ciphertext, 'base64');

    // Extract IV, AuthTag, and Ciphertext
    const iv = combined.subarray(0, IV_LENGTH);
    const authTag = combined.subarray(IV_LENGTH, IV_LENGTH + AUTH_TAG_LENGTH);
    const encrypted = combined.subarray(IV_LENGTH + AUTH_TAG_LENGTH);

    // Create decipher
    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
    decipher.setAuthTag(authTag);

    // Decrypt
    const decrypted = Buffer.concat([
        decipher.update(encrypted),
        decipher.final()
    ]);

    return decrypted.toString('utf8');
}

/**
 * Encrypt specific fields in an object
 * @param data Object containing data to encrypt
 * @param fieldsToEncrypt Array of field names to encrypt
 * @returns Object with specified fields encrypted
 */
export function encryptFields<T extends Record<string, unknown>>(
    data: T,
    fieldsToEncrypt: readonly string[]
): T {
    const result = { ...data };

    for (const field of fieldsToEncrypt) {
        const value = result[field as keyof T];
        if (value !== undefined && value !== null && typeof value === 'string') {
            (result[field as keyof T] as unknown) = encrypt(value);
        }
    }

    return result;
}

/**
 * Decrypt specific fields in an object
 * @param data Object containing encrypted data
 * @param fieldsToDecrypt Array of field names to decrypt
 * @returns Object with specified fields decrypted
 */
export function decryptFields<T extends Record<string, unknown>>(
    data: T,
    fieldsToDecrypt: readonly string[]
): T {
    const result = { ...data };

    for (const field of fieldsToDecrypt) {
        const value = result[field as keyof T];
        if (value !== undefined && value !== null && typeof value === 'string') {
            try {
                (result[field as keyof T] as unknown) = decrypt(value);
            } catch (error) {
                console.error(`Failed to decrypt field ${String(field)}:`, error);
                // Keep the encrypted value if decryption fails
            }
        }
    }

    return result;
}

/**
 * List of sensitive fields that should be encrypted
 * These fields will be encrypted before storing in Firestore
 */
export const SENSITIVE_FIELDS = {
    athlete: ['phoneNumber', 'address', 'emergencyContact', 'medicalConditions', 'healthNotes'],
    coach: ['phoneNumber', 'address', 'bankAccountDetails'],
    user: ['phoneNumber', 'address', 'dateOfBirth'],
} as const;

/**
 * Generate a new 256-bit encryption key
 * Use this to create a key for production
 */
export function generateEncryptionKey(): string {
    return crypto.randomBytes(32).toString('hex');
}
