/**
 * Firebase Admin SDK Initialization
 * This module should be imported FIRST to ensure Firebase is initialized
 * before any other modules try to use it.
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK (only once)
if (!admin.apps.length) {
    admin.initializeApp();
}

// Export initialized instances
export const db = admin.firestore();
export const auth = admin.auth();

export default admin;
