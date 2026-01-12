"use strict";
/**
 * AES-256-GCM Encryption Utilities
 * Provides secure encryption for sensitive data fields in Firestore
 *
 * Uses AES-256-GCM which provides:
 * - Confidentiality (encryption)
 * - Integrity (authentication tag)
 * - Unique IV per encryption
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.SENSITIVE_FIELDS = void 0;
exports.encrypt = encrypt;
exports.decrypt = decrypt;
exports.encryptFields = encryptFields;
exports.decryptFields = decryptFields;
exports.generateEncryptionKey = generateEncryptionKey;
const crypto = __importStar(require("crypto"));
const config_1 = require("../config");
// Encryption constants
const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16; // 128 bits for GCM
const AUTH_TAG_LENGTH = 16; // 128 bits
/**
 * Encrypt a plaintext string using AES-256-GCM
 * @param plaintext The text to encrypt
 * @returns Base64 encoded string containing IV + AuthTag + Ciphertext
 */
function encrypt(plaintext) {
    // Get key at runtime from Firebase Secrets
    const encryptionKey = (0, config_1.getEncryptionKey)();
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
function decrypt(ciphertext) {
    // Get key at runtime from Firebase Secrets
    const encryptionKey = (0, config_1.getEncryptionKey)();
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
function encryptFields(data, fieldsToEncrypt) {
    const result = { ...data };
    for (const field of fieldsToEncrypt) {
        const value = result[field];
        if (value !== undefined && value !== null && typeof value === 'string') {
            result[field] = encrypt(value);
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
function decryptFields(data, fieldsToDecrypt) {
    const result = { ...data };
    for (const field of fieldsToDecrypt) {
        const value = result[field];
        if (value !== undefined && value !== null && typeof value === 'string') {
            try {
                result[field] = decrypt(value);
            }
            catch (error) {
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
exports.SENSITIVE_FIELDS = {
    athlete: ['phoneNumber', 'address', 'emergencyContact', 'medicalConditions', 'healthNotes'],
    coach: ['phoneNumber', 'address', 'bankAccountDetails'],
    user: ['phoneNumber', 'address', 'dateOfBirth'],
};
/**
 * Generate a new 256-bit encryption key
 * Use this to create a key for production
 */
function generateEncryptionKey() {
    return crypto.randomBytes(32).toString('hex');
}
//# sourceMappingURL=encryption.js.map