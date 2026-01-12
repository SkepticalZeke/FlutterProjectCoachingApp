/**
 * Shared types and utilities for Cloud Functions
 */

import { HttpsError } from 'firebase-functions/v2/https';
import admin from './firebase';

/**
 * Common response structure
 */
export interface FunctionResponse<T = unknown> {
    success: boolean;
    data?: T;
    message?: string;
    error?: string;
}

/**
 * Validate that user is authenticated
 */
export function requireAuth(auth: { uid: string; token: admin.auth.DecodedIdToken } | undefined): string {
    if (!auth) {
        throw new HttpsError('unauthenticated', 'You must be logged in to perform this action');
    }
    return auth.uid;
}

/**
 * Get user role from Firestore
 */
export async function getUserRole(uid: string): Promise<string | null> {
    const db = admin.firestore();
    const userDoc = await db.collection('users').doc(uid).get();
    return userDoc.exists ? userDoc.data()?.role || null : null;
}

/**
 * Require specific role(s)
 */
export async function requireRole(uid: string, allowedRoles: string[]): Promise<string> {
    const role = await getUserRole(uid);
    if (!role || !allowedRoles.includes(role)) {
        throw new HttpsError('permission-denied', `This action requires one of these roles: ${allowedRoles.join(', ')}`);
    }
    return role;
}
