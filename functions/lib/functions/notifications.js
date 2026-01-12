"use strict";
/**
 * Notifications Microservice Functions
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
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.clearNotifications = exports.markAllNotificationsRead = exports.markNotificationRead = exports.getNotifications = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = __importStar(require("../firebase"));
const config_1 = require("../config");
const shared_1 = require("../shared");
const COLLECTION = 'notifications';
// =============================================================================
// Functions
// =============================================================================
/**
 * Get notifications for the current user
 */
exports.getNotifications = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const { unreadOnly } = request.data || {};
    let query = firebase_1.db.collection(COLLECTION)
        .where('userId', '==', uid);
    if (unreadOnly) {
        query = query.where('read', '==', false);
    }
    const snapshot = await query
        .orderBy('timestamp', 'desc')
        .limit(50)
        .get();
    const notifications = [];
    snapshot.forEach(doc => {
        notifications.push({ id: doc.id, ...doc.data() });
    });
    // Get unread count
    const unreadSnapshot = await firebase_1.db.collection(COLLECTION)
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
});
/**
 * Mark a notification as read
 */
exports.markNotificationRead = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const { notificationId } = request.data;
    if (!notificationId) {
        throw new https_1.HttpsError('invalid-argument', 'notificationId is required');
    }
    const docRef = firebase_1.db.collection(COLLECTION).doc(notificationId);
    const doc = await docRef.get();
    if (!doc.exists) {
        throw new https_1.HttpsError('not-found', 'Notification not found');
    }
    const data = doc.data();
    if (data.userId !== uid) {
        throw new https_1.HttpsError('permission-denied', 'Access denied');
    }
    await docRef.update({
        read: true,
        readAt: firebase_1.default.firestore.FieldValue.serverTimestamp()
    });
    return { success: true, message: 'Notification marked as read' };
});
/**
 * Mark all notifications as read
 */
exports.markAllNotificationsRead = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const snapshot = await firebase_1.db.collection(COLLECTION)
        .where('userId', '==', uid)
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
    return { success: true, data: { count: snapshot.size }, message: `${snapshot.size} notifications marked as read` };
});
/**
 * Clear all notifications
 */
exports.clearNotifications = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const snapshot = await firebase_1.db.collection(COLLECTION)
        .where('userId', '==', uid)
        .get();
    const batch = firebase_1.db.batch();
    snapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
    });
    await batch.commit();
    return { success: true, data: { count: snapshot.size }, message: `${snapshot.size} notifications deleted` };
});
//# sourceMappingURL=notifications.js.map