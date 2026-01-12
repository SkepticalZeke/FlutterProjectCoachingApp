/**
 * Coaches Service Router
 * Handles all coach-related CRUD operations
 */

import { Router, Response } from 'express';
import * as admin from 'firebase-admin';
import { authMiddleware, AuthenticatedRequest, requireRole } from '../../middleware/auth';
import { encryptFields, decryptFields, SENSITIVE_FIELDS } from '../../utils/encryption';

const router = Router();
const db = admin.firestore();
const COLLECTION = 'coaches';

// Type definitions
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
    createdAt?: FirebaseFirestore.Timestamp;
    updatedAt?: FirebaseFirestore.Timestamp;
}

// =============================================================================
// Routes
// =============================================================================

/**
 * GET /coaches
 * Get all coaches
 */
router.get('/', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { specialization, limit = '50', offset = '0' } = req.query;

        let query: FirebaseFirestore.Query = db.collection(COLLECTION);

        if (specialization) {
            query = query.where('specialization', '==', specialization);
        }

        query = query
            .orderBy('createdAt', 'desc')
            .limit(parseInt(limit as string))
            .offset(parseInt(offset as string));

        const snapshot = await query.get();

        const coaches: Coach[] = [];
        snapshot.forEach(doc => {
            const data = doc.data() as Coach;
            // Only decrypt sensitive fields for the coach themselves or admin
            const shouldDecrypt = req.user?.uid === doc.id || req.user?.role === 'admin';
            const processed = shouldDecrypt
                ? decryptFields(data, SENSITIVE_FIELDS.coach)
                : { ...data, phoneNumber: undefined, address: undefined, bankAccountDetails: undefined };

            coaches.push({
                id: doc.id,
                ...processed
            });
        });

        res.json({
            success: true,
            data: coaches,
            count: coaches.length
        });
    } catch (error) {
        console.error('Error fetching coaches:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch coaches'
        });
    }
});

/**
 * GET /coaches/:id
 * Get a specific coach by ID
 */
router.get('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;

        const doc = await db.collection(COLLECTION).doc(id).get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Coach not found'
            });
            return;
        }

        const data = doc.data() as Coach;

        // Only decrypt sensitive fields for the coach themselves or admin
        const shouldDecrypt = req.user?.uid === id || req.user?.role === 'admin';
        const processed = shouldDecrypt
            ? decryptFields(data, SENSITIVE_FIELDS.coach)
            : { ...data, phoneNumber: undefined, address: undefined, bankAccountDetails: undefined };

        res.json({
            success: true,
            data: {
                id: doc.id,
                ...processed
            }
        });
    } catch (error) {
        console.error('Error fetching coach:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch coach'
        });
    }
});

/**
 * POST /coaches
 * Create a new coach (admin only)
 */
router.post('/', authMiddleware, requireRole('admin'), async (req: AuthenticatedRequest, res: Response) => {
    try {
        const coachData: Coach = req.body;

        if (!coachData.name || !coachData.email) {
            res.status(400).json({
                success: false,
                error: 'Name and email are required'
            });
            return;
        }

        // Encrypt sensitive fields
        const encrypted = encryptFields(coachData, SENSITIVE_FIELDS.coach);

        const dataToStore = {
            ...encrypted,
            athleteCount: 0,
            rating: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: req.user?.uid
        };

        const docRef = await db.collection(COLLECTION).add(dataToStore);

        res.status(201).json({
            success: true,
            data: {
                id: docRef.id,
                ...coachData
            },
            message: 'Coach created successfully'
        });
    } catch (error) {
        console.error('Error creating coach:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create coach'
        });
    }
});

/**
 * PUT /coaches/:id
 * Update a coach profile
 */
router.put('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;
        const updateData: Partial<Coach> = req.body;

        // Only allow coaches to update their own profile, or admin to update any
        if (req.user?.uid !== id && req.user?.role !== 'admin') {
            res.status(403).json({
                success: false,
                error: 'Access denied'
            });
            return;
        }

        const docRef = db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Coach not found'
            });
            return;
        }

        // Encrypt sensitive fields
        const encrypted = encryptFields(updateData as Record<string, unknown>, SENSITIVE_FIELDS.coach);

        await docRef.update({
            ...encrypted,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedBy: req.user?.uid
        });

        res.json({
            success: true,
            data: {
                id,
                ...updateData
            },
            message: 'Coach updated successfully'
        });
    } catch (error) {
        console.error('Error updating coach:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update coach'
        });
    }
});

/**
 * DELETE /coaches/:id
 * Delete a coach (admin only)
 */
router.delete('/:id', authMiddleware, requireRole('admin'), async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;

        const docRef = db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Coach not found'
            });
            return;
        }

        await docRef.delete();

        res.json({
            success: true,
            message: 'Coach deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting coach:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete coach'
        });
    }
});

/**
 * GET /coaches/:id/athletes
 * Get all athletes assigned to a coach
 */
router.get('/:id/athletes', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;

        // Only allow coaches to view their own athletes, or admin
        if (req.user?.uid !== id && req.user?.role !== 'admin') {
            res.status(403).json({
                success: false,
                error: 'Access denied'
            });
            return;
        }

        const snapshot = await db.collection('athletes')
            .where('coachId', '==', id)
            .orderBy('name')
            .get();

        const athletes: unknown[] = [];
        snapshot.forEach(doc => {
            athletes.push({
                id: doc.id,
                ...doc.data()
            });
        });

        res.json({
            success: true,
            data: athletes,
            count: athletes.length
        });
    } catch (error) {
        console.error('Error fetching coach athletes:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch athletes'
        });
    }
});

export default router;
