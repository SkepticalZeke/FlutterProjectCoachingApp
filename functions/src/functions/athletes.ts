/**
 * Athletes Microservice Functions
 * Each function is independently deployable and scalable
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import admin, { db } from '../firebase';
import { encryptionKeySecret, config } from '../config';
import { encryptFields, decryptFields, SENSITIVE_FIELDS } from '../utils/encryption';
import { requireAuth, requireRole, FunctionResponse } from '../shared';

const COLLECTION = 'athletes';

// =============================================================================
// Type Definitions
// =============================================================================

interface Athlete {
    [key: string]: unknown;
    id?: string;
    name: string;
    email: string;
    phoneNumber?: string;
    address?: string;
    emergencyContact?: string;
    medicalConditions?: string;
    healthNotes?: string;
    coachId?: string;
    level?: number;
    streak?: number;
    progress?: number;
}

// =============================================================================
// Functions
// =============================================================================

/**
 * Get all athletes (filtered by role)
 */
export const getAthletes = onCall(
    { region: config.region, secrets: [encryptionKeySecret] },
    async (request: CallableRequest): Promise<FunctionResponse<Athlete[]>> => {
        const uid = requireAuth(request.auth);
        const role = await requireRole(uid, ['coach', 'admin']);

        let query: FirebaseFirestore.Query = db.collection(COLLECTION);

        // Coaches can only see their own athletes
        if (role === 'coach') {
            query = query.where('coachId', '==', uid);
        }

        const snapshot = await query.orderBy('name').limit(100).get();

        const athletes: Athlete[] = [];
        snapshot.forEach(doc => {
            const data = doc.data() as Athlete;
            const decrypted = decryptFields(data, SENSITIVE_FIELDS.athlete);
            athletes.push({ id: doc.id, ...decrypted });
        });

        return { success: true, data: athletes };
    }
);

/**
 * Get a single athlete by ID
 */
export const getAthlete = onCall(
    { region: config.region, secrets: [encryptionKeySecret] },
    async (request: CallableRequest<{ athleteId: string }>): Promise<FunctionResponse<Athlete>> => {
        const uid = requireAuth(request.auth);
        const { athleteId } = request.data;

        if (!athleteId) {
            throw new HttpsError('invalid-argument', 'athleteId is required');
        }

        const doc = await db.collection(COLLECTION).doc(athleteId).get();

        if (!doc.exists) {
            throw new HttpsError('not-found', 'Athlete not found');
        }

        const data = doc.data() as Athlete;

        // Check access: athlete can view themselves, coach can view their athletes, admin can view all
        const role = await requireRole(uid, ['athlete', 'coach', 'admin']);
        if (role === 'athlete' && doc.id !== uid) {
            throw new HttpsError('permission-denied', 'You can only view your own profile');
        }
        if (role === 'coach' && data.coachId !== uid) {
            throw new HttpsError('permission-denied', 'You can only view your own athletes');
        }

        const decrypted = decryptFields(data, SENSITIVE_FIELDS.athlete);
        return { success: true, data: { id: doc.id, ...decrypted } };
    }
);

/**
 * Create a new athlete
 */
export const createAthlete = onCall(
    { region: config.region, secrets: [encryptionKeySecret] },
    async (request: CallableRequest<Athlete>): Promise<FunctionResponse<{ id: string }>> => {
        const uid = requireAuth(request.auth);
        await requireRole(uid, ['coach', 'admin']);

        const athleteData = request.data;

        if (!athleteData.name || !athleteData.email) {
            throw new HttpsError('invalid-argument', 'Name and email are required');
        }

        // Encrypt sensitive fields
        const encrypted = encryptFields(athleteData, SENSITIVE_FIELDS.athlete);

        const docRef = await db.collection(COLLECTION).add({
            ...encrypted,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: uid
        });

        return { success: true, data: { id: docRef.id }, message: 'Athlete created successfully' };
    }
);

/**
 * Update an existing athlete
 */
export const updateAthlete = onCall(
    { region: config.region, secrets: [encryptionKeySecret] },
    async (request: CallableRequest<{ athleteId: string; updates: Partial<Athlete> }>): Promise<FunctionResponse> => {
        const uid = requireAuth(request.auth);
        const { athleteId, updates } = request.data;

        if (!athleteId) {
            throw new HttpsError('invalid-argument', 'athleteId is required');
        }

        const docRef = db.collection(COLLECTION).doc(athleteId);
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new HttpsError('not-found', 'Athlete not found');
        }

        const existingData = doc.data() as Athlete;
        const role = await requireRole(uid, ['athlete', 'coach', 'admin']);

        // Check permissions
        if (role === 'athlete' && doc.id !== uid) {
            throw new HttpsError('permission-denied', 'You can only update your own profile');
        }
        if (role === 'coach' && existingData.coachId !== uid) {
            throw new HttpsError('permission-denied', 'You can only update your own athletes');
        }

        // Encrypt sensitive fields
        const encrypted = encryptFields(updates as Record<string, unknown>, SENSITIVE_FIELDS.athlete);

        await docRef.update({
            ...encrypted,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedBy: uid
        });

        return { success: true, message: 'Athlete updated successfully' };
    }
);

/**
 * Delete an athlete (admin only)
 */
export const deleteAthlete = onCall(
    { region: config.region },
    async (request: CallableRequest<{ athleteId: string }>): Promise<FunctionResponse> => {
        const uid = requireAuth(request.auth);
        await requireRole(uid, ['admin']);

        const { athleteId } = request.data;

        if (!athleteId) {
            throw new HttpsError('invalid-argument', 'athleteId is required');
        }

        const docRef = db.collection(COLLECTION).doc(athleteId);
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new HttpsError('not-found', 'Athlete not found');
        }

        await docRef.delete();

        return { success: true, message: 'Athlete deleted successfully' };
    }
);
