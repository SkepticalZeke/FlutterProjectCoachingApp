"use strict";
/**
 * Drills Microservice Functions
 * Handles drill assignment, submission, and review workflow
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
exports.reviewDrill = exports.submitDrill = exports.createDrill = exports.getDrill = exports.getDrills = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = __importStar(require("../firebase"));
const config_1 = require("../config");
const shared_1 = require("../shared");
const COLLECTION = 'drills';
// =============================================================================
// Functions
// =============================================================================
/**
 * Get drills (filtered by role)
 */
exports.getDrills = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const role = await (0, shared_1.requireRole)(uid, ['athlete', 'coach', 'admin']);
    const { status } = request.data || {};
    let query = firebase_1.db.collection(COLLECTION);
    // Filter by role
    if (role === 'athlete') {
        query = query.where('athleteId', '==', uid);
    }
    else if (role === 'coach') {
        query = query.where('coachId', '==', uid);
    }
    if (status) {
        query = query.where('status', '==', status);
    }
    const snapshot = await query.orderBy('createdAt', 'desc').limit(100).get();
    const drills = [];
    snapshot.forEach(doc => {
        drills.push({ id: doc.id, ...doc.data() });
    });
    return { success: true, data: drills };
});
/**
 * Get a single drill
 */
exports.getDrill = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const { drillId } = request.data;
    if (!drillId) {
        throw new https_1.HttpsError('invalid-argument', 'drillId is required');
    }
    const doc = await firebase_1.db.collection(COLLECTION).doc(drillId).get();
    if (!doc.exists) {
        throw new https_1.HttpsError('not-found', 'Drill not found');
    }
    const data = doc.data();
    // Check access
    const role = await (0, shared_1.requireRole)(uid, ['athlete', 'coach', 'admin']);
    if (role === 'athlete' && data.athleteId !== uid) {
        throw new https_1.HttpsError('permission-denied', 'Access denied');
    }
    if (role === 'coach' && data.coachId !== uid) {
        throw new https_1.HttpsError('permission-denied', 'Access denied');
    }
    return { success: true, data: { id: doc.id, ...data } };
});
/**
 * Create/assign a new drill (coach only)
 */
exports.createDrill = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    await (0, shared_1.requireRole)(uid, ['coach', 'admin']);
    const drillData = request.data;
    if (!drillData.title || !drillData.athleteId) {
        throw new https_1.HttpsError('invalid-argument', 'Title and athleteId are required');
    }
    // Verify athlete exists
    const athleteDoc = await firebase_1.db.collection('athletes').doc(drillData.athleteId).get();
    if (!athleteDoc.exists) {
        throw new https_1.HttpsError('not-found', 'Athlete not found');
    }
    const docRef = await firebase_1.db.collection(COLLECTION).add({
        ...drillData,
        coachId: uid,
        status: 'assigned',
        completed: false,
        createdAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp()
    });
    // Notify athlete
    await firebase_1.db.collection('notifications').add({
        userId: drillData.athleteId,
        type: 'drill_assigned',
        message: `New drill assigned: ${drillData.title}`,
        drillId: docRef.id,
        timestamp: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        read: false
    });
    return { success: true, data: { id: docRef.id }, message: 'Drill created successfully' };
});
/**
 * Submit a drill for review (athlete only)
 */
exports.submitDrill = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const { drillId, videoUrl, notes } = request.data;
    if (!drillId) {
        throw new https_1.HttpsError('invalid-argument', 'drillId is required');
    }
    const docRef = firebase_1.db.collection(COLLECTION).doc(drillId);
    const doc = await docRef.get();
    if (!doc.exists) {
        throw new https_1.HttpsError('not-found', 'Drill not found');
    }
    const data = doc.data();
    if (data.athleteId !== uid) {
        throw new https_1.HttpsError('permission-denied', 'Only the assigned athlete can submit');
    }
    await docRef.update({
        status: 'pending_review',
        videoUrl,
        notes,
        submittedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp()
    });
    // Notify coach
    if (data.coachId) {
        await firebase_1.db.collection('notifications').add({
            userId: data.coachId,
            type: 'drill_submitted',
            message: `Drill submitted for review: ${data.title}`,
            drillId,
            timestamp: firebase_1.default.firestore.FieldValue.serverTimestamp(),
            read: false
        });
    }
    return { success: true, message: 'Drill submitted for review' };
});
/**
 * Review a drill (coach only)
 */
exports.reviewDrill = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    await (0, shared_1.requireRole)(uid, ['coach', 'admin']);
    const { drillId, approved, feedback, rating } = request.data;
    if (!drillId || approved === undefined) {
        throw new https_1.HttpsError('invalid-argument', 'drillId and approved are required');
    }
    const docRef = firebase_1.db.collection(COLLECTION).doc(drillId);
    const doc = await docRef.get();
    if (!doc.exists) {
        throw new https_1.HttpsError('not-found', 'Drill not found');
    }
    const data = doc.data();
    if (data.coachId !== uid) {
        throw new https_1.HttpsError('permission-denied', 'Only the assigned coach can review');
    }
    const status = approved ? 'completed' : 'rejected';
    await docRef.update({
        status,
        completed: approved,
        completedAt: approved ? firebase_1.default.firestore.FieldValue.serverTimestamp() : null,
        feedback,
        rating,
        reviewedBy: uid,
        reviewedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp()
    });
    // Notify athlete
    await firebase_1.db.collection('notifications').add({
        userId: data.athleteId,
        type: approved ? 'drill_approved' : 'drill_rejected',
        message: approved ? `Drill approved: ${data.title}` : `Drill needs revision: ${data.title}`,
        drillId,
        timestamp: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        read: false
    });
    return { success: true, message: approved ? 'Drill approved' : 'Drill sent back for revision' };
});
//# sourceMappingURL=drills.js.map