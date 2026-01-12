"use strict";
/**
 * Coaches Service Router
 * Handles all coach-related CRUD operations
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
const admin = __importStar(require("firebase-admin"));
const auth_1 = require("../../middleware/auth");
const encryption_1 = require("../../utils/encryption");
const router = (0, express_1.Router)();
const db = admin.firestore();
const COLLECTION = 'coaches';
// =============================================================================
// Routes
// =============================================================================
/**
 * GET /coaches
 * Get all coaches
 */
router.get('/', auth_1.authMiddleware, async (req, res) => {
    try {
        const { specialization, limit = '50', offset = '0' } = req.query;
        let query = db.collection(COLLECTION);
        if (specialization) {
            query = query.where('specialization', '==', specialization);
        }
        query = query
            .orderBy('createdAt', 'desc')
            .limit(parseInt(limit))
            .offset(parseInt(offset));
        const snapshot = await query.get();
        const coaches = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            // Only decrypt sensitive fields for the coach themselves or admin
            const shouldDecrypt = req.user?.uid === doc.id || req.user?.role === 'admin';
            const processed = shouldDecrypt
                ? (0, encryption_1.decryptFields)(data, encryption_1.SENSITIVE_FIELDS.coach)
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
    }
    catch (error) {
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
router.get('/:id', auth_1.authMiddleware, async (req, res) => {
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
        const data = doc.data();
        // Only decrypt sensitive fields for the coach themselves or admin
        const shouldDecrypt = req.user?.uid === id || req.user?.role === 'admin';
        const processed = shouldDecrypt
            ? (0, encryption_1.decryptFields)(data, encryption_1.SENSITIVE_FIELDS.coach)
            : { ...data, phoneNumber: undefined, address: undefined, bankAccountDetails: undefined };
        res.json({
            success: true,
            data: {
                id: doc.id,
                ...processed
            }
        });
    }
    catch (error) {
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
router.post('/', auth_1.authMiddleware, (0, auth_1.requireRole)('admin'), async (req, res) => {
    try {
        const coachData = req.body;
        if (!coachData.name || !coachData.email) {
            res.status(400).json({
                success: false,
                error: 'Name and email are required'
            });
            return;
        }
        // Encrypt sensitive fields
        const encrypted = (0, encryption_1.encryptFields)(coachData, encryption_1.SENSITIVE_FIELDS.coach);
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
    }
    catch (error) {
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
router.put('/:id', auth_1.authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;
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
        const encrypted = (0, encryption_1.encryptFields)(updateData, encryption_1.SENSITIVE_FIELDS.coach);
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
    }
    catch (error) {
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
router.delete('/:id', auth_1.authMiddleware, (0, auth_1.requireRole)('admin'), async (req, res) => {
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
    }
    catch (error) {
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
router.get('/:id/athletes', auth_1.authMiddleware, async (req, res) => {
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
        const athletes = [];
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
    }
    catch (error) {
        console.error('Error fetching coach athletes:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch athletes'
        });
    }
});
exports.default = router;
//# sourceMappingURL=index.js.map