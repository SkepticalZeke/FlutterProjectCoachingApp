/**
 * Coaches Microservice Functions
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import admin, { db } from '../firebase';
import { encryptionKeySecret, config } from '../config';
import { encryptFields, decryptFields, SENSITIVE_FIELDS } from '../utils/encryption';
import { requireAuth, requireRole, FunctionResponse } from '../shared';

const COLLECTION = 'coaches';

// =============================================================================
// Type Definitions
// =============================================================================

interface Coach {
    [key: string]: unknown;
    id?: string;
    name: string;
    email: string;
    phoneNumber?: string;
    address?: string;
    bankAccountDetails?: string;
    specialization?: string;
    bio?: string;
    athleteCount?: number;
    rating?: number;
}

// =============================================================================
// Functions
// =============================================================================

/**
 * Get all coaches
 */
export const getCoaches = onCall(
    { region: config.region, secrets: [encryptionKeySecret] },
    async (request: CallableRequest): Promise<FunctionResponse<Coach[]>> => {
        requireAuth(request.auth);

        const snapshot = await db.collection(COLLECTION)
            .orderBy('name')
            .limit(100)
            .get();

        const coaches: Coach[] = [];
        snapshot.forEach(doc => {
            const data = doc.data() as Coach;
            // Only return public info (no sensitive fields)
            coaches.push({
                id: doc.id,
                name: data.name,
                email: data.email,
                specialization: data.specialization,
                bio: data.bio,
                athleteCount: data.athleteCount,
                rating: data.rating
            });
        });

        return { success: true, data: coaches };
    }
);

/**
 * Get a single coach
 */
export const getCoach = onCall(
    { region: config.region, secrets: [encryptionKeySecret] },
    async (request: CallableRequest<{ coachId: string }>): Promise<FunctionResponse<Coach>> => {
        const uid = requireAuth(request.auth);
        const { coachId } = request.data;

        if (!coachId) {
            throw new HttpsError('invalid-argument', 'coachId is required');
        }

        const doc = await db.collection(COLLECTION).doc(coachId).get();

        if (!doc.exists) {
            throw new HttpsError('not-found', 'Coach not found');
        }

        const data = doc.data() as Coach;

        // Only decrypt sensitive fields for the coach themselves or admin
        const isSelf = doc.id === uid;
        const role = await requireRole(uid, ['athlete', 'coach', 'admin']);
        const isAdmin = role === 'admin';

        if (isSelf || isAdmin) {
            const decrypted = decryptFields(data, SENSITIVE_FIELDS.coach);
            return { success: true, data: { id: doc.id, ...decrypted } };
        } else {
            // Return only public info
            return {
                success: true,
                data: {
                    id: doc.id,
                    name: data.name,
                    email: data.email,
                    specialization: data.specialization,
                    bio: data.bio,
                    athleteCount: data.athleteCount,
                    rating: data.rating
                }
            };
        }
    }
);

/**
 * Create a new coach (admin only)
 */
export const createCoach = onCall(
    { region: config.region, secrets: [encryptionKeySecret] },
    async (request: CallableRequest<Coach>): Promise<FunctionResponse<{ id: string }>> => {
        const uid = requireAuth(request.auth);
        await requireRole(uid, ['admin']);

        const coachData = request.data;

        if (!coachData.name || !coachData.email) {
            throw new HttpsError('invalid-argument', 'Name and email are required');
        }

        const encrypted = encryptFields(coachData, SENSITIVE_FIELDS.coach);

        const docRef = await db.collection(COLLECTION).add({
            ...encrypted,
            athleteCount: 0,
            rating: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: uid
        });

        return { success: true, data: { id: docRef.id }, message: 'Coach created successfully' };
    }
);

/**
 * Update a coach profile
 */
export const updateCoach = onCall(
    { region: config.region, secrets: [encryptionKeySecret] },
    async (request: CallableRequest<{ coachId: string; updates: Partial<Coach> }>): Promise<FunctionResponse> => {
        const uid = requireAuth(request.auth);
        const { coachId, updates } = request.data;

        if (!coachId) {
            throw new HttpsError('invalid-argument', 'coachId is required');
        }

        const role = await requireRole(uid, ['coach', 'admin']);

        // Coaches can only update their own profile
        if (role === 'coach' && coachId !== uid) {
            throw new HttpsError('permission-denied', 'You can only update your own profile');
        }

        const docRef = db.collection(COLLECTION).doc(coachId);
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new HttpsError('not-found', 'Coach not found');
        }

        const encrypted = encryptFields(updates as Record<string, unknown>, SENSITIVE_FIELDS.coach);

        await docRef.update({
            ...encrypted,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedBy: uid
        });

        return { success: true, message: 'Coach updated successfully' };
    }
);
