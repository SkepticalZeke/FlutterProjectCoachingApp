/**
 * Drills Service Router
 * Handles drill assignment, completion, and review operations
 */

import { Router, Response } from 'express';
import admin, { db } from '../../firebase';
import { authMiddleware, AuthenticatedRequest, requireRole } from '../../middleware/auth';

const router = Router();
const COLLECTION = 'drills';

// Type definitions
interface Drill {
    id?: string;
    title: string;
    description: string;
    athleteId: string;
    coachId: string;
    status: 'assigned' | 'in_progress' | 'Pending Review' | 'completed' | 'rejected';
    completed: boolean;
    dueDate?: FirebaseFirestore.Timestamp;
    completedAt?: FirebaseFirestore.Timestamp;
    videoUrl?: string;
    notes?: string;
    feedback?: string;
    rating?: number;
    createdAt?: FirebaseFirestore.Timestamp;
    updatedAt?: FirebaseFirestore.Timestamp;
}

// =============================================================================
// Routes
// =============================================================================

/**
 * GET /drills
 * Get drills (filtered by user role)
 */
router.get('/', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { athleteId, coachId, status, completed, limit = '50', offset = '0' } = req.query;

        let query: FirebaseFirestore.Query = db.collection(COLLECTION);

        // Apply filters based on user role
        if (req.user?.role === 'athlete') {
            // Athletes can only see their own drills
            query = query.where('athleteId', '==', req.user.uid);
        } else if (req.user?.role === 'coach') {
            // Coaches can see drills they assigned or filter by athleteId
            if (athleteId) {
                query = query.where('athleteId', '==', athleteId);
            }
            query = query.where('coachId', '==', req.user.uid);
        } else if (athleteId) {
            query = query.where('athleteId', '==', athleteId);
        }

        if (coachId && req.user?.role === 'admin') {
            query = query.where('coachId', '==', coachId);
        }

        if (status) {
            query = query.where('status', '==', status);
        }

        if (completed !== undefined) {
            query = query.where('completed', '==', completed === 'true');
        }

        query = query
            .orderBy('createdAt', 'desc')
            .limit(parseInt(limit as string))
            .offset(parseInt(offset as string));

        const snapshot = await query.get();

        const drills: Drill[] = [];
        snapshot.forEach(doc => {
            drills.push({
                id: doc.id,
                ...doc.data() as Drill
            });
        });

        res.json({
            success: true,
            data: drills,
            count: drills.length
        });
    } catch (error) {
        console.error('Error fetching drills:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch drills'
        });
    }
});

/**
 * GET /drills/:id
 * Get a specific drill
 */
router.get('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;

        const doc = await db.collection(COLLECTION).doc(id).get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Drill not found'
            });
            return;
        }

        const data = doc.data() as Drill;

        // Check access permissions
        const canAccess =
            req.user?.role === 'admin' ||
            data.athleteId === req.user?.uid ||
            data.coachId === req.user?.uid;

        if (!canAccess) {
            res.status(403).json({
                success: false,
                error: 'Access denied'
            });
            return;
        }

        res.json({
            success: true,
            data: {
                id: doc.id,
                ...data
            }
        });
    } catch (error) {
        console.error('Error fetching drill:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch drill'
        });
    }
});

/**
 * POST /drills
 * Create a new drill (coaches only)
 */
router.post('/', authMiddleware, requireRole('coach', 'admin'), async (req: AuthenticatedRequest, res: Response) => {
    try {
        const drillData: Drill = req.body;

        if (!drillData.title || !drillData.athleteId) {
            res.status(400).json({
                success: false,
                error: 'Title and athleteId are required'
            });
            return;
        }

        // Verify the athlete exists
        const athleteDoc = await db.collection('athletes').doc(drillData.athleteId).get();
        if (!athleteDoc.exists) {
            res.status(400).json({
                success: false,
                error: 'Athlete not found'
            });
            return;
        }

        const dataToStore = {
            ...drillData,
            coachId: req.user?.uid,
            status: 'assigned',
            completed: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };

        const docRef = await db.collection(COLLECTION).add(dataToStore);

        // Create notification for athlete
        await db.collection('notifications').add({
            userId: drillData.athleteId,
            type: 'drill_assigned',
            message: `New drill assigned: ${drillData.title}`,
            drillId: docRef.id,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            read: false
        });

        res.status(201).json({
            success: true,
            data: {
                id: docRef.id,
                ...dataToStore
            },
            message: 'Drill created successfully'
        });
    } catch (error) {
        console.error('Error creating drill:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to create drill'
        });
    }
});

/**
 * PUT /drills/:id
 * Update a drill
 */
router.put('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;
        const updateData: Partial<Drill> = req.body;

        const docRef = db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Drill not found'
            });
            return;
        }

        const existingData = doc.data() as Drill;

        // Check permissions
        const canUpdate =
            req.user?.role === 'admin' ||
            existingData.coachId === req.user?.uid ||
            existingData.athleteId === req.user?.uid;

        if (!canUpdate) {
            res.status(403).json({
                success: false,
                error: 'Access denied'
            });
            return;
        }

        await docRef.update({
            ...updateData,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedBy: req.user?.uid
        });

        res.json({
            success: true,
            data: {
                id,
                ...updateData
            },
            message: 'Drill updated successfully'
        });
    } catch (error) {
        console.error('Error updating drill:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update drill'
        });
    }
});

/**
 * POST /drills/:id/submit
 * Submit a drill for review (athlete action)
 */
router.post('/:id/submit', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;
        const { videoUrl, notes } = req.body;

        const docRef = db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Drill not found'
            });
            return;
        }

        const existingData = doc.data() as Drill;

        // Only the assigned athlete can submit
        if (existingData.athleteId !== req.user?.uid) {
            res.status(403).json({
                success: false,
                error: 'Only the assigned athlete can submit this drill'
            });
            return;
        }

        await docRef.update({
            status: 'Pending Review',
            videoUrl,
            notes,
            submittedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        res.json({
            success: true,
            message: 'Drill submitted for review'
        });
    } catch (error) {
        console.error('Error submitting drill:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to submit drill'
        });
    }
});

/**
 * POST /drills/:id/review
 * Review a submitted drill (coach action)
 */
router.post('/:id/review', authMiddleware, requireRole('coach', 'admin'), async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;
        const { approved, feedback, rating } = req.body;

        const docRef = db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Drill not found'
            });
            return;
        }

        const existingData = doc.data() as Drill;

        // Only the assigned coach or admin can review
        if (existingData.coachId !== req.user?.uid && req.user?.role !== 'admin') {
            res.status(403).json({
                success: false,
                error: 'Only the assigned coach can review this drill'
            });
            return;
        }

        const status = approved ? 'completed' : 'rejected';

        await docRef.update({
            status,
            completed: approved,
            completedAt: approved ? admin.firestore.FieldValue.serverTimestamp() : null,
            feedback,
            rating,
            reviewedBy: req.user?.uid,
            reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Notify athlete
        await db.collection('notifications').add({
            userId: existingData.athleteId,
            type: approved ? 'drill_approved' : 'drill_rejected',
            message: approved
                ? `Your drill "${existingData.title}" was approved!`
                : `Your drill "${existingData.title}" needs revision`,
            drillId: id,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            read: false
        });

        res.json({
            success: true,
            message: approved ? 'Drill approved' : 'Drill sent back for revision'
        });
    } catch (error) {
        console.error('Error reviewing drill:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to review drill'
        });
    }
});

/**
 * DELETE /drills/:id
 * Delete a drill (coach/admin only)
 */
router.delete('/:id', authMiddleware, requireRole('coach', 'admin'), async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;

        const docRef = db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Drill not found'
            });
            return;
        }

        const existingData = doc.data() as Drill;

        // Only the coach who created it or admin can delete
        if (existingData.coachId !== req.user?.uid && req.user?.role !== 'admin') {
            res.status(403).json({
                success: false,
                error: 'Access denied'
            });
            return;
        }

        await docRef.delete();

        res.json({
            success: true,
            message: 'Drill deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting drill:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete drill'
        });
    }
});

export default router;
