/**
 * Notifications Service Router
 * Handles notification retrieval and management
 */

import { Router, Response } from 'express';
import admin, { db } from '../../firebase';
import { authMiddleware, AuthenticatedRequest } from '../../middleware/auth';

const router = Router();
const COLLECTION = 'notifications';

// Type definitions
interface Notification {
    id?: string;
    userId: string;
    type: string;
    message: string;
    read: boolean;
    drillId?: string;
    athleteId?: string;
    timestamp?: FirebaseFirestore.Timestamp;
}

// =============================================================================
// Routes
// =============================================================================

/**
 * GET /notifications
 * Get notifications for the authenticated user
 */
router.get('/', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { read, type, limit = '50', offset = '0' } = req.query;

        let query: FirebaseFirestore.Query = db.collection(COLLECTION)
            .where('userId', '==', req.user?.uid);

        if (read !== undefined) {
            query = query.where('read', '==', read === 'true');
        }

        if (type) {
            query = query.where('type', '==', type);
        }

        query = query
            .orderBy('timestamp', 'desc')
            .limit(parseInt(limit as string))
            .offset(parseInt(offset as string));

        const snapshot = await query.get();

        const notifications: Notification[] = [];
        snapshot.forEach(doc => {
            notifications.push({
                id: doc.id,
                ...doc.data() as Notification
            });
        });

        // Get unread count
        const unreadSnapshot = await db.collection(COLLECTION)
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
    } catch (error) {
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
router.get('/unread-count', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const snapshot = await db.collection(COLLECTION)
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
    } catch (error) {
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
router.put('/:id/read', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;

        const docRef = db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Notification not found'
            });
            return;
        }

        const data = doc.data() as Notification;

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
            readAt: admin.firestore.FieldValue.serverTimestamp()
        });

        res.json({
            success: true,
            message: 'Notification marked as read'
        });
    } catch (error) {
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
router.put('/read-all', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const snapshot = await db.collection(COLLECTION)
            .where('userId', '==', req.user?.uid)
            .where('read', '==', false)
            .get();

        const batch = db.batch();

        snapshot.docs.forEach(doc => {
            batch.update(doc.ref, {
                read: true,
                readAt: admin.firestore.FieldValue.serverTimestamp()
            });
        });

        await batch.commit();

        res.json({
            success: true,
            message: `${snapshot.size} notifications marked as read`
        });
    } catch (error) {
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
router.delete('/:id', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const { id } = req.params;

        const docRef = db.collection(COLLECTION).doc(id);
        const doc = await docRef.get();

        if (!doc.exists) {
            res.status(404).json({
                success: false,
                error: 'Notification not found'
            });
            return;
        }

        const data = doc.data() as Notification;

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
    } catch (error) {
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
router.delete('/clear-all', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
    try {
        const snapshot = await db.collection(COLLECTION)
            .where('userId', '==', req.user?.uid)
            .get();

        const batch = db.batch();

        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });

        await batch.commit();

        res.json({
            success: true,
            message: `${snapshot.size} notifications deleted`
        });
    } catch (error) {
        console.error('Error clearing notifications:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to clear notifications'
        });
    }
});

export default router;
