/**
 * Environment Configuration Module
 * Loads and validates environment variables for the Cloud Functions
 */

import * as dotenv from 'dotenv';
import * as path from 'path';

// Load .env file in development
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

/**
 * Configuration object with typed environment variables
 */
export const config = {
    // Project configuration
    projectId: process.env.FIREBASE_PROJECT_ID || 'fitness-coaching-app-5633f',
    region: 'asia-southeast1',

    // Encryption configuration
    encryptionKey: process.env.AES_ENCRYPTION_KEY || '',

    // Runtime environment
    isProduction: process.env.NODE_ENV === 'production',
    isDevelopment: process.env.NODE_ENV !== 'production',
} as const;

/**
 * Validate that required configuration is present
 * Call this during startup to fail fast if config is missing
 */
export function validateConfig(): void {
    const errors: string[] = [];

    if (!config.encryptionKey || config.encryptionKey.length !== 64) {
        errors.push('AES_ENCRYPTION_KEY must be a 64-character hex string (256 bits)');
    }

    if (errors.length > 0) {
        console.error('Configuration validation failed:');
        errors.forEach(err => console.error(`  - ${err}`));

        // In development, warn but don't crash (allows testing without full config)
        if (config.isProduction) {
            throw new Error('Configuration validation failed. See logs for details.');
        } else {
            console.warn('Running in development mode with incomplete configuration');
        }
    }
}

export default config;
