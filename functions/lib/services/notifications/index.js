"use strict";
/**
 * Notifications Service Router
 * Handles notification retrieval and management
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
const COLLECTION = 'notifications';
// =============================================================================
// Routes
// =============================================================================
/**
 * GET /notifications
 * Get notifications for the authenticated user
 */
router.get('/', auth_1.authMiddleware, async (req, res) => {
    try {
        const { read, type, limit = '50', offset = '0' } = req.query;
        let query = firebase_1.db.collection(COLLECTION)
            .where('userId', '==', req.user?.uid);
        if (read !== undefined) {
            query = query.where('read', '==', read === 'true');
        }
        if (type) {
            query = query.where('type', '==', type);
        }
        query = query
            .orderBy('timestamp', 'desc')
            .limit(parseInt(limit))
            .offset(parseInt(offset));
        const snapshot = await query.get();
        const notifications = [];
        snapshot.forEach(doc => {
            notifications.push({
                id: doc.id,
                ...doc.data()
            });
        });
        // Get unread count
        const unreadSnapshot = await firebase_1.db.collection(COLLECTION)
            .where('userId', '==', req.user?.uid)
            .where('read', '==', false)
            .count()
            .get();
        res.json({
            success: true,
            data: notifications,
            count: notifications.length,
            unreadCount: unreadSnapshot.data().count
        });
    }
    catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch notifications'
        });
    }
});
/**
 * GET /notifications/unread-count
 * Get the count of unread notifications
 */
router.get('/unread-count', auth_1.authMiddleware, async (req, res) => {
    try {
        const snapshot = await firebase_1.db.collection(COLLECTION)
            .where('userId', '==', req.user?.uid)
            .where('read', '==', false)
            .count()
            .get();
        res.json({
            success: true,
            data: {
                unreadCount: snapshot.data().count
            }
        });
    }
    catch (error) {
        console.error('Error fetching unread count:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to fetch unread count'
        });
    }
});
/**
 * PUT /notifications/:id/read
 * Mark a notification as read
 */
router.put('/:id/read', auth_1.authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const docRef = firebase_1.db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();
        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Notification not found'
            });
            return;
        }
        const data = doc.data();
        // Only the owner can mark as read
        if (data.userId !== req.user?.uid) {
            res.status(403).json({
                success: false,
                error: 'Access denied'
            });
            return;
        }
        await docRef.update({
            read: true,
            readAt: firebase_1.default.firestore.FieldValue.serverTimestamp()
        });
        res.json({
            success: true,
            message: 'Notification marked as read'
        });
    }
    catch (error) {
        console.error('Error marking notification as read:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update notification'
        });
    }
});
/**
 * PUT /notifications/read-all
 * Mark all notifications as read
 */
router.put('/read-all', auth_1.authMiddleware, async (req, res) => {
    try {
        const snapshot = await firebase_1.db.collection(COLLECTION)
            .where('userId', '==', req.user?.uid)
            .where('read', '==', false)
            .get();
        const batch = firebase_1.db.batch();
        snapshot.docs.forEach(doc => {
            batch.update(doc.ref, {
                read: true,
                readAt: firebase_1.default.firestore.FieldValue.serverTimestamp()
            });
        });
        await batch.commit();
        res.json({
            success: true,
            message: `${snapshot.size} notifications marked as read`
        });
    }
    catch (error) {
        console.error('Error marking all notifications as read:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to update notifications'
        });
    }
});
/**
 * DELETE /notifications/:id
 * Delete a notification
 */
router.delete('/:id', auth_1.authMiddleware, async (req, res) => {
    try {
        const { id } = req.params;
        const docRef = firebase_1.db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();
        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Notification not found'
            });
            return;
        }
        const data = doc.data();
        // Only the owner can delete
        if (data.userId !== req.user?.uid) {
            res.status(403).json({
                success: false,
                error: 'Access denied'
            });
            return;
        }
        await docRef.delete();
        res.json({
            success: true,
            message: 'Notification deleted'
        });
    }
    catch (error) {
        console.error('Error deleting notification:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete notification'
        });
    }
});
/**
 * DELETE /notifications/clear-all
 * Delete all notifications for the user
 */
router.delete('/clear-all', auth_1.authMiddleware, async (req, res) => {
    try {
        const snapshot = await firebase_1.db.collection(COLLECTION)
            .where('userId', '==', req.user?.uid)
            .get();
        const batch = firebase_1.db.batch();
        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        await batch.commit();
        res.json({
            success: true,
            message: `${snapshot.size} notifications deleted`
        });
    }
    catch (error) {
        console.error('Error clearing notifications:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to clear notifications'
        });
    }
});
exports.default = router;
//# sourceMappingURL=index.js.map