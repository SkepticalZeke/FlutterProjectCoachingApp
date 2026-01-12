/**
 * Notifications Microservice Functions
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import admin, { db } from '../firebase';
import { config } from '../config';
import { requireAuth, FunctionResponse } from '../shared';

const COLLECTION = 'notifications';

// =============================================================================
// Type Definitions
// =============================================================================

interface Notification {
    id?: string;
    userId: string;
    type: string;
    message: string;
    read: boolean;
    drillId?: string;
    timestamp?: FirebaseFirestore.Timestamp;
}

// =============================================================================
// Functions
// =============================================================================

/**
 * Get notifications for the current user
 */
export const getNotifications = onCall(
    { region: config.region },
    async (request: CallableRequest<{ unreadOnly?: boolean }>): Promise<FunctionResponse<{ notifications: Notification[]; unreadCount: number }>> => {
        const uid = requireAuth(request.auth);
        const { unreadOnly } = request.data || {};

        let query: FirebaseFirestore.Query = db.collection(COLLECTION)
            .where('userId', '==', uid);

        if (unreadOnly) {
            query = query.where('read', '==', false);
        }

        const snapshot = await query
            .orderBy('timestamp', 'desc')
            .limit(50)
            .get();

        const notifications: Notification[] = [];
        snapshot.forEach(doc => {
            notifications.push({ id: doc.id, ...doc.data() } as Notification);
        });

        // Get unread count
        const unreadSnapshot = await db.collection(COLLECTION)
            .where('userId', '==', uid)
            .where('read', '==', false)
            .count()
            .get();

        return {
            success: true,
            data: {
                notifications,
                unreadCount: unreadSnapshot.data().count
            }
        };
    }
);

/**
 * Mark a notification as read
 */
export const markNotificationRead = onCall(
    { region: config.region },
    async (request: CallableRequest<{ notificationId: string }>): Promise<FunctionResponse> => {
        const uid = requireAuth(request.auth);
        const { notificationId } = request.data;

        if (!notificationId) {
            throw new HttpsError('invalid-argument', 'notificationId is required');
        }

        const docRef = db.collection(COLLECTION).doc(notificationId);
        const doc = await docRef.get();

        if (!doc.exists) {
            throw new HttpsError('not-found', 'Notification not found');
        }

        const data = doc.data() as Notification;

        if (data.userId !== uid) {
            throw new HttpsError('permission-denied', 'Access denied');
        }

        await docRef.update({
            read: true,
            readAt: admin.firestore.FieldValue.serverTimestamp()
        });

        return { success: true, message: 'Notification marked as read' };
    }
);

/**
 * Mark all notifications as read
 */
export const markAllNotificationsRead = onCall(
    { region: config.region },
    async (request: CallableRequest): Promise<FunctionResponse<{ count: number }>> => {
        const uid = requireAuth(request.auth);

        const snapshot = await db.collection(COLLECTION)
            .where('userId', '==', uid)
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

        return { success: true, data: { count: snapshot.size }, message: `${snapshot.size} notifications marked as read` };
    }
);

/**
 * Clear all notifications
 */
export const clearNotifications = onCall(
    { region: config.region },
    async (request: CallableRequest): Promise<FunctionResponse<{ count: number }>> => {
        const uid = requireAuth(request.auth);

        const snapshot = await db.collection(COLLECTION)
            .where('userId', '==', uid)
            .get();

        const batch = db.batch();
        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });

        await batch.commit();

        return { success: true, data: { count: snapshot.size }, message: `${snapshot.size} notifications deleted` };
    }
);
