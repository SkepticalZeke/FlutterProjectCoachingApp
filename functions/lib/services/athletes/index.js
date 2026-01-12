"use strict";
/**
 * Athletes Service Router
 * Handles all athlete-related CRUD operations
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
const encryption_1 = require("../../utils/encryption");
const router = (0, express_1.Router)();
const COLLECTION = 'athletes';
// =============================================================================
// Routes
// =============================================================================
/**
 * GET /athletes
 * Get all athletes (optionally filtered by coach)
 */
router.get('/', auth_1.authMiddleware, async (req, res) => {
    try {
        const { coachId, limit = '50', offset = '0' } = req.query;
        let query = firebase_1.db.collection(COLLECTION);
        // Filter by coach if specified or if user is a coach
        if (coachId) {
            query = query.where('coachId', '==', coachId);
        }
        else if (req.user?.role === 'coach') {
            // Coaches can only see their own athletes
            query = query.where('coachId', '==', req.user.uid);
        }
        // Apply pagination
        query = query
            .orderBy('createdAt', 'desc')
            .limit(parseInt(limit))
            .offset(parseInt(offset));
        const snapshot = await query.get();
        const athletes = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            // Decrypt sensitive fields before sending to client
            const decrypted = (0, encryption_1.decryptFields)(data, encryption_1.SENSITIVE_FIELDS.athlete);
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
    }
    catch (error) {
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
router.get('/:id', auth_1.authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const doc = await firebase_1.db.collection(COLLECTION).doc(id).get();
        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Athlete not found'
            });
            return;
        }
        const data = doc.data();
        // Check access permissions
        if (req.user?.role === 'coach' && data.coachId !== req.user.uid) {
            res.status(403).json({
                success: false,
                error: 'Access denied'
            });
            return;
        }
        // Decrypt sensitive fields
        const decrypted = (0, encryption_1.decryptFields)(data, encryption_1.SENSITIVE_FIELDS.athlete);
        res.json({
            success: true,
            data: {
                id: doc.id,
                ...decrypted
            }
        });
    }
    catch (error) {
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
router.post('/', auth_1.authMiddleware, async (req, res) => {
    try {
        const athleteData = req.body;
        // Validate required fields
        if (!athleteData.name || !athleteData.email) {
            res.status(400).json({
                success: false,
                error: 'Name and email are required'
            });
            return;
        }
        // Encrypt sensitive fields before storing
        const encrypted = (0, encryption_1.encryptFields)(athleteData, encryption_1.SENSITIVE_FIELDS.athlete);
        // Add metadata
        const dataToStore = {
            ...encrypted,
            createdAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
            createdBy: req.user?.uid
        };
        const docRef = await firebase_1.db.collection(COLLECTION).add(dataToStore);
        res.status(201).json({
            success: true,
            data: {
                id: docRef.id,
                ...athleteData // Return unencrypted data
            },
            message: 'Athlete created successfully'
        });
    }
    catch (error) {
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
router.put('/:id', auth_1.authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;
        // Check if athlete exists
        const docRef = firebase_1.db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();
        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Athlete not found'
            });
            return;
        }
        const existingData = doc.data();
        // Check access permissions
        if (req.user?.role === 'coach' && existingData.coachId !== req.user.uid) {
            res.status(403).json({
                success: false,
                error: 'Access denied'
            });
            return;
        }
        // Encrypt sensitive fields
        const encrypted = (0, encryption_1.encryptFields)(updateData, encryption_1.SENSITIVE_FIELDS.athlete);
        // Update with metadata
        await docRef.update({
            ...encrypted,
            updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
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
    }
    catch (error) {
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
router.delete('/:id', auth_1.authMiddleware, (0, auth_1.requireRole)('admin'), async (req, res) => {
    try {
        const { id } = req.params;
        const docRef = firebase_1.db.collection(COLLECTION).doc(id);
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
    }
    catch (error) {
        console.error('Error deleting athlete:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete athlete'
        });
    }
});
exports.default = router;
//# sourceMappingURL=index.js.map