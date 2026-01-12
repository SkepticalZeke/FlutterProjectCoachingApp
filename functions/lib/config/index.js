"use strict";
/**
 * Configuration Module
 * Uses Firebase Secrets for sensitive data (no .env files needed)
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.getEncryptionKey = exports.config = exports.encryptionKeySecret = void 0;
const params_1 = require("firebase-functions/params");
// =============================================================================
// Firebase Secrets (stored in Google Secret Manager)
// =============================================================================
/**
 * AES-256 Encryption Key
 * Set via: firebase functions:secrets:set AES_ENCRYPTION_KEY
 *
 * Generate a key with: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
 */
exports.encryptionKeySecret = (0, params_1.defineSecret)('AES_ENCRYPTION_KEY');
// =============================================================================
// Static Configuration
// =============================================================================
exports.config = {
    // Project configuration (not secrets - these are public)
    projectId: 'fitness-coaching-app-5633f',
    region: 'asia-southeast1',
};
/**
 * Get the encryption key at runtime
 * Must be called inside a function handler, not at module level
 */
function getEncryptionKey() {
    const key = exports.encryptionKeySecret.value();
    if (!key || key.length !== 64) {
        throw new Error('AES_ENCRYPTION_KEY not configured or invalid. ' +
            'Run: firebase functions:secrets:set AES_ENCRYPTION_KEY');
    }
    return key;
}
exports.getEncryptionKey = getEncryptionKey;
exports.default = exports.config;
//# sourceMappingURL=index.js.map