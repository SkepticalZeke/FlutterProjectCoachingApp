/**
 * Configuration Module
 * Uses Firebase Secrets for sensitive data (no .env files needed)
 */

import { defineSecret } from 'firebase-functions/params';

// =============================================================================
// Firebase Secrets (stored in Google Secret Manager)
// =============================================================================

/**
 * AES-256 Encryption Key
 * Set via: firebase functions:secrets:set AES_ENCRYPTION_KEY
 * 
 * Generate a key with: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
 */
export const encryptionKeySecret = defineSecret('AES_ENCRYPTION_KEY');

// =============================================================================
// Static Configuration
// =============================================================================

export const config = {
    // Project configuration (not secrets - these are public)
    projectId: 'fitness-coaching-app-5633f',
    region: 'asia-southeast1',
} as const;

/**
 * Get the encryption key at runtime
 * Must be called inside a function handler, not at module level
 */
export function getEncryptionKey(): string {
    const key = encryptionKeySecret.value();

    if (!key || key.length !== 64) {
        throw new Error(
            'AES_ENCRYPTION_KEY not configured or invalid. ' +
            'Run: firebase functions:secrets:set AES_ENCRYPTION_KEY'
        );
    }

    return key;
}

export default config;
