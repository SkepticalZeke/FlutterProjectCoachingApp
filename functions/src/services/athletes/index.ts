/**
 * Athletes Service Router
 * Handles all athlete-related CRUD operations
 */

import { Router, Response } from 'express';
import admin, { db } from '../../firebase';
import { authMiddleware, AuthenticatedRequest, requireRole } from '../../middleware/auth';
import { encryptFields, decryptFields, SENSITIVE_FIELDS } from '../../utils/encryption';

const router = Router();
const COLLECTION = 'athletes';

// Type definitions
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
    createdAt?: FirebaseFirestore.Timestamp;
    updatedAt?: FirebaseFirestore.Timestamp;
}

// =============================================================================
// Routes
// =============================================================================

/**
 * GET /athletes
 * Get all athletes (optionally filtered by coach)
 */
router.get('/', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { coachId, limit = '50', offset = '0' } = req.query;

        let query: FirebaseFirestore.Query = db.collection(COLLECTION);

        // Filter by coach if specified or if user is a coach
        if (coachId) {
            query = query.where('coachId', '==', coachId);
        } else if (req.user?.role === 'coach') {
            // Coaches can only see their own athletes
            query = query.where('coachId', '==', req.user.uid);
        }

        // Apply pagination
        query = query
            .orderBy('createdAt', 'desc')
            .limit(parseInt(limit as string))
            .offset(parseInt(offset as string));

        const snapshot = await query.get();

        const athletes: Athlete[] = [];
        snapshot.forEach(doc => {
            const data = doc.data() as Athlete;
            // Decrypt sensitive fields before sending to client
            const decrypted = decryptFields(data, SENSITIVE_FIELDS.athlete);
            athletes.push({
                id: doc.id,
                ...decrypted
            });
        });

        res.json({
            success: true,
            data: athletes,
            count: athletes.length
        });
    } catch (error) {
        console.error('Error fetching athletes:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch athletes'
        });
    }
});

/**
 * GET /athletes/:id
 * Get a specific athlete by ID
 */
router.get('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;

        const doc = await db.collection(COLLECTION).doc(id).get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Athlete not found'
            });
            return;
        }

        const data = doc.data() as Athlete;

        // Check access permissions
        if (req.user?.role === 'coach' && data.coachId !== req.user.uid) {
            res.status(403).json({
                success: false,
                error: 'Access denied'
            });
            return;
        }

        // Decrypt sensitive fields
        const decrypted = decryptFields(data, SENSITIVE_FIELDS.athlete);

        res.json({
            success: true,
            data: {
                id: doc.id,
                ...decrypted
            }
        });
    } catch (error) {
        console.error('Error fetching athlete:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch athlete'
        });
    }
});

/**
 * POST /athletes
 * Create a new athlete
 */
router.post('/', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const athleteData: Athlete = req.body;

        // Validate required fields
        if (!athleteData.name || !athleteData.email) {
            res.status(400).json({
                success: false,
                error: 'Name and email are required'
            });
            return;
        }

        // Encrypt sensitive fields before storing
        const encrypted = encryptFields(athleteData, SENSITIVE_FIELDS.athlete);

        // Add metadata
        const dataToStore = {
            ...encrypted,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: req.user?.uid
        };

        const docRef = await db.collection(COLLECTION).add(dataToStore);

        res.status(201).json({
            success: true,
            data: {
                id: docRef.id,
                ...athleteData // Return unencrypted data
            },
            message: 'Athlete created successfully'
        });
    } catch (error) {
        console.error('Error creating athlete:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create athlete'
        });
    }
});

/**
 * PUT /athletes/:id
 * Update an existing athlete
 */
router.put('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;
        const updateData: Partial<Athlete> = req.body;

        // Check if athlete exists
        const docRef = db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Athlete not found'
            });
            return;
        }

        const existingData = doc.data() as Athlete;

        // Check access permissions
        if (req.user?.role === 'coach' && existingData.coachId !== req.user.uid) {
            res.status(403).json({
                success: false,
                error: 'Access denied'
            });
            return;
        }

        // Encrypt sensitive fields
        const encrypted = encryptFields(updateData as Record<string, unknown>, SENSITIVE_FIELDS.athlete);

        // Update with metadata
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
            message: 'Athlete updated successfully'
        });
    } catch (error) {
        console.error('Error updating athlete:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update athlete'
        });
    }
});

/**
 * DELETE /athletes/:id
 * Delete an athlete (admin only)
 */
router.delete('/:id', authMiddleware, requireRole('admin'), async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;

        const docRef = db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Athlete not found'
            });
            return;
        }

        await docRef.delete();

        res.json({
            success: true,
            message: 'Athlete deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting athlete:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete athlete'
        });
    }
});

export default router;
