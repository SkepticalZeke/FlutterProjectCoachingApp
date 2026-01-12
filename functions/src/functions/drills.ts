/**
 * Drills Microservice Functions
 * Handles drill assignment, submission, and review workflow
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import admin, { db } from '../firebase';
import { config } from '../config';
import { requireAuth, requireRole, FunctionResponse } from '../shared';

const COLLECTION = 'drills';

// =============================================================================
// Type Definitions
// =============================================================================

interface Drill {
    id?: string;
    title: string;
    description?: string;
    athleteId: string;
    coachId?: string;
    status: 'assigned' | 'in_progress' | 'pending_review' | 'completed' | 'rejected';
    completed: boolean;
    dueDate?: FirebaseFirestore.Timestamp;
    videoUrl?: string;
    notes?: string;
    feedback?: string;
    rating?: number;
}

// =============================================================================
// Functions
// =============================================================================

/**
 * Get drills (filtered by role)
 */
export const getDrills = onCall(
    { region: config.region },
    async (request: CallableRequest<{ status?: string }>): Promise<FunctionResponse<Drill[]>> => {
        const uid = requireAuth(request.auth);
        const role = await requireRole(uid, ['athlete', 'coach', 'admin']);
        const { status } = request.data || {};

        let query: FirebaseFirestore.Query = db.collection(COLLECTION);

        // Filter by role
        if (role === 'athlete') {
            query = query.where('athleteId', '==', uid);
        } else if (role === 'coach') {
            query = query.where('coachId', '==', uid);
        }

        if (status) {
            query = query.where('status', '==', status);
        }

        const snapshot = await query.orderBy('createdAt', 'desc').limit(100).get();

        const drills: Drill[] = [];
        snapshot.forEach(doc => {
            drills.push({ id: doc.id, ...doc.data() } as Drill);
        });

        return { success: true, data: drills };
    }
);

/**
 * Get a single drill
 */
export const getDrill = onCall(
    { region: config.region },
    async (request: CallableRequest<{ drillId: string }>): Promise<FunctionResponse<Drill>> => {
        const uid = requireAuth(request.auth);
        const { drillId } = request.data;

        if (!drillId) {
            throw new HttpsError('invalid-argument', 'drillId is required');
        }

        const doc = await db.collection(COLLECTION).doc(drillId).get();

        if (!doc.exists) {
            throw new HttpsError('not-found', 'Drill not found');
        }

        const data = doc.data() as Drill;

        // Check access
        const role = await requireRole(uid, ['athlete', 'coach', 'admin']);
        if (role === 'athlete' && data.athleteId !== uid) {
            throw new HttpsError('permission-denied', 'Access denied');
        }
        if (role === 'coach' && data.coachId !== uid) {
            throw new HttpsError('permission-denied', 'Access denied');
        }

        return { success: true, data: { id: doc.id, ...data } };
    }
);

/**
 * Create/assign a new drill (coach only)
 */
export const createDrill = onCall(
    { region: config.region },
    async (request: CallableRequest<Drill>): Promise<FunctionResponse<{ id: string }>> => {
        const uid = requireAuth(request.auth);
        await requireRole(uid, ['coach', 'admin']);

        const drillData = request.data;

        if (!drillData.title || !drillData.athleteId) {
            throw new HttpsError('invalid-argument', 'Title and athleteId are required');
        }

        // Verify athlete exists
        const athleteDoc = await db.collection('athletes').doc(drillData.athleteId).get();
        if (!athleteDoc.exists) {
            throw new HttpsError('not-found', 'Athlete not found');
        }

        const docRef = await db.collection(COLLECTION).add({
            ...drillData,
            coachId: uid,
            status: 'assigned',
            completed: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Notify athlete
        await db.collection('notifications').add({
            userId: drillData.athleteId,
            type: 'drill_assigned',
            message: `New drill assigned: ${drillData.title}`,
            drillId: docRef.id,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            read: false
        });

        return { success: true, data: { id: docRef.id }, message: 'Drill created successfully' };
    }
);

/**
 * Submit a drill for review (athlete only)
 */
export const submitDrill = onCall(
    { region: config.region },
    async (request: CallableRequest<{ drillId: string; videoUrl?: string; notes?: string }>): Promise<FunctionResponse> => {
        const uid = requireAuth(request.auth);
        const { drillId, videoUrl, notes } = request.data;

        if (!drillId) {
            throw new HttpsError('invalid-argument', 'drillId is required');
        }

        const docRef = db.collection(COLLECTION).doc(drillId);
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new HttpsError('not-found', 'Drill not found');
        }

        const data = doc.data() as Drill;

        if (data.athleteId !== uid) {
            throw new HttpsError('permission-denied', 'Only the assigned athlete can submit');
        }

        await docRef.update({
            status: 'pending_review',
            videoUrl,
            notes,
            submittedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Notify coach
        if (data.coachId) {
            await db.collection('notifications').add({
                userId: data.coachId,
                type: 'drill_submitted',
                message: `Drill submitted for review: ${data.title}`,
                drillId,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                read: false
            });
        }

        return { success: true, message: 'Drill submitted for review' };
    }
);

/**
 * Review a drill (coach only)
 */
export const reviewDrill = onCall(
    { region: config.region },
    async (request: CallableRequest<{ drillId: string; approved: boolean; feedback?: string; rating?: number }>): Promise<FunctionResponse> => {
        const uid = requireAuth(request.auth);
        await requireRole(uid, ['coach', 'admin']);

        const { drillId, approved, feedback, rating } = request.data;

        if (!drillId || approved === undefined) {
            throw new HttpsError('invalid-argument', 'drillId and approved are required');
        }

        const docRef = db.collection(COLLECTION).doc(drillId);
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new HttpsError('not-found', 'Drill not found');
        }

        const data = doc.data() as Drill;

        if (data.coachId !== uid) {
            throw new HttpsError('permission-denied', 'Only the assigned coach can review');
        }

        const status = approved ? 'completed' : 'rejected';

        await docRef.update({
            status,
            completed: approved,
            completedAt: approved ? admin.firestore.FieldValue.serverTimestamp() : null,
            feedback,
            rating,
            reviewedBy: uid,
            reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Notify athlete
        await db.collection('notifications').add({
            userId: data.athleteId,
            type: approved ? 'drill_approved' : 'drill_rejected',
            message: approved ? `Drill approved: ${data.title}` : `Drill needs revision: ${data.title}`,
            drillId,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            read: false
        });

        return { success: true, message: approved ? 'Drill approved' : 'Drill sent back for revision' };
    }
);
