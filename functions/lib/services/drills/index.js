"use strict";
/**
 * Drills Service Router
 * Handles drill assignment, completion, and review operations
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const firebase_1 = __importStar(require("../../firebase"));
const auth_1 = require("../../middleware/auth");
const router = (0, express_1.Router)();
const COLLECTION = 'drills';
// =============================================================================
// Routes
// =============================================================================
/**
 * GET /drills
 * Get drills (filtered by user role)
 */
router.get('/', auth_1.authMiddleware, async (req, res) => {
    try {
        const { athleteId, coachId, status, completed, limit = '50', offset = '0' } = req.query;
        let query = firebase_1.db.collection(COLLECTION);
        // Apply filters based on user role
        if (req.user?.role === 'athlete') {
            // Athletes can only see their own drills
            query = query.where('athleteId', '==', req.user.uid);
        }
        else if (req.user?.role === 'coach') {
            // Coaches can see drills they assigned or filter by athleteId
            if (athleteId) {
                query = query.where('athleteId', '==', athleteId);
            }
            query = query.where('coachId', '==', req.user.uid);
        }
        else if (athleteId) {
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
            .limit(parseInt(limit))
            .offset(parseInt(offset));
        const snapshot = await query.get();
        const drills = [];
        snapshot.forEach(doc => {
            drills.push({
                id: doc.id,
                ...doc.data()
            });
        });
        res.json({
            success: true,
            data: drills,
            count: drills.length
        });
    }
    catch (error) {
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
router.get('/:id', auth_1.authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const doc = await firebase_1.db.collection(COLLECTION).doc(id).get();
        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Drill not found'
            });
            return;
        }
        const data = doc.data();
        // Check access permissions
        const canAccess = req.user?.role === 'admin' ||
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
    }
    catch (error) {
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
router.post('/', auth_1.authMiddleware, (0, auth_1.requireRole)('coach', 'admin'), async (req, res) => {
    try {
        const drillData = req.body;
        if (!drillData.title || !drillData.athleteId) {
            res.status(400).json({
                success: false,
                error: 'Title and athleteId are required'
            });
            return;
        }
        // Verify the athlete exists
        const athleteDoc = await firebase_1.db.collection('athletes').doc(drillData.athleteId).get();
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
            createdAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp()
        };
        const docRef = await firebase_1.db.collection(COLLECTION).add(dataToStore);
        // Create notification for athlete
        await firebase_1.db.collection('notifications').add({
            userId: drillData.athleteId,
            type: 'drill_assigned',
            message: `New drill assigned: ${drillData.title}`,
            drillId: docRef.id,
            timestamp: firebase_1.default.firestore.FieldValue.serverTimestamp(),
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
    }
    catch (error) {
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
router.put('/:id', auth_1.authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;
        const docRef = firebase_1.db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();
        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Drill not found'
            });
            return;
        }
        const existingData = doc.data();
        // Check permissions
        const canUpdate = req.user?.role === 'admin' ||
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
            updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
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
    }
    catch (error) {
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
router.post('/:id/submit', auth_1.authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const { videoUrl, notes } = req.body;
        const docRef = firebase_1.db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();
        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Drill not found'
            });
            return;
        }
        const existingData = doc.data();
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
            submittedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp()
        });
        res.json({
            success: true,
            message: 'Drill submitted for review'
        });
    }
    catch (error) {
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
router.post('/:id/review', auth_1.authMiddleware, (0, auth_1.requireRole)('coach', 'admin'), async (req, res) => {
    try {
        const { id } = req.params;
        const { approved, feedback, rating } = req.body;
        const docRef = firebase_1.db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();
        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Drill not found'
            });
            return;
        }
        const existingData = doc.data();
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
            completedAt: approved ? firebase_1.default.firestore.FieldValue.serverTimestamp() : null,
            feedback,
            rating,
            reviewedBy: req.user?.uid,
            reviewedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp()
        });
        // Notify athlete
        await firebase_1.db.collection('notifications').add({
            userId: existingData.athleteId,
            type: approved ? 'drill_approved' : 'drill_rejected',
            message: approved
                ? `Your drill "${existingData.title}" was approved!`
                : `Your drill "${existingData.title}" needs revision`,
            drillId: id,
            timestamp: firebase_1.default.firestore.FieldValue.serverTimestamp(),
            read: false
        });
        res.json({
            success: true,
            message: approved ? 'Drill approved' : 'Drill sent back for revision'
        });
    }
    catch (error) {
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
router.delete('/:id', auth_1.authMiddleware, (0, auth_1.requireRole)('coach', 'admin'), async (req, res) => {
    try {
        const { id } = req.params;
        const docRef = firebase_1.db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();
        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Drill not found'
            });
            return;
        }
        const existingData = doc.data();
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
    }
    catch (error) {
        console.error('Error deleting drill:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete drill'
        });
    }
});
exports.default = router;
//# sourceMappingURL=index.js.map