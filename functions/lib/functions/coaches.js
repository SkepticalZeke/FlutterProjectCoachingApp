"use strict";
/**
 * Coaches Microservice Functions
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
exports.updateCoach = exports.createCoach = exports.getCoach = exports.getCoaches = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = __importStar(require("../firebase"));
const config_1 = require("../config");
const encryption_1 = require("../utils/encryption");
const shared_1 = require("../shared");
const COLLECTION = 'coaches';
// =============================================================================
// Functions
// =============================================================================
/**
 * Get all coaches
 */
exports.getCoaches = (0, https_1.onCall)({ region: config_1.config.region, secrets: [config_1.encryptionKeySecret] }, async (request) => {
    (0, shared_1.requireAuth)(request.auth);
    const snapshot = await firebase_1.db.collection(COLLECTION)
        .orderBy('name')
        .limit(100)
        .get();
    const coaches = [];
    snapshot.forEach(doc => {
        const data = doc.data();
        // Only return public info (no sensitive fields)
        coaches.push({
            id: doc.id,
            name: data.name,
            email: data.email,
            specialization: data.specialization,
            bio: data.bio,
            athleteCount: data.athleteCount,
            rating: data.rating
        });
    });
    return { success: true, data: coaches };
});
/**
 * Get a single coach
 */
exports.getCoach = (0, https_1.onCall)({ region: config_1.config.region, secrets: [config_1.encryptionKeySecret] }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const { coachId } = request.data;
    if (!coachId) {
        throw new https_1.HttpsError('invalid-argument', 'coachId is required');
    }
    const doc = await firebase_1.db.collection(COLLECTION).doc(coachId).get();
    if (!doc.exists) {
        throw new https_1.HttpsError('not-found', 'Coach not found');
    }
    const data = doc.data();
    // Only decrypt sensitive fields for the coach themselves or admin
    const isSelf = doc.id === uid;
    const role = await (0, shared_1.requireRole)(uid, ['athlete', 'coach', 'admin']);
    const isAdmin = role === 'admin';
    if (isSelf || isAdmin) {
        const decrypted = (0, encryption_1.decryptFields)(data, encryption_1.SENSITIVE_FIELDS.coach);
        return { success: true, data: { id: doc.id, ...decrypted } };
    }
    else {
        // Return only public info
        return {
            success: true,
            data: {
                id: doc.id,
                name: data.name,
                email: data.email,
                specialization: data.specialization,
                bio: data.bio,
                athleteCount: data.athleteCount,
                rating: data.rating
            }
        };
    }
});
/**
 * Create a new coach (admin only)
 */
exports.createCoach = (0, https_1.onCall)({ region: config_1.config.region, secrets: [config_1.encryptionKeySecret] }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    await (0, shared_1.requireRole)(uid, ['admin']);
    const coachData = request.data;
    if (!coachData.name || !coachData.email) {
        throw new https_1.HttpsError('invalid-argument', 'Name and email are required');
    }
    const encrypted = (0, encryption_1.encryptFields)(coachData, encryption_1.SENSITIVE_FIELDS.coach);
    const docRef = await firebase_1.db.collection(COLLECTION).add({
        ...encrypted,
        athleteCount: 0,
        rating: 0,
        createdAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        createdBy: uid
    });
    return { success: true, data: { id: docRef.id }, message: 'Coach created successfully' };
});
/**
 * Update a coach profile
 */
exports.updateCoach = (0, https_1.onCall)({ region: config_1.config.region, secrets: [config_1.encryptionKeySecret] }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const { coachId, updates } = request.data;
    if (!coachId) {
        throw new https_1.HttpsError('invalid-argument', 'coachId is required');
    }
    const role = await (0, shared_1.requireRole)(uid, ['coach', 'admin']);
    // Coaches can only update their own profile
    if (role === 'coach' && coachId !== uid) {
        throw new https_1.HttpsError('permission-denied', 'You can only update your own profile');
    }
    const docRef = firebase_1.db.collection(COLLECTION).doc(coachId);
    const doc = await docRef.get();
    if (!doc.exists) {
        throw new https_1.HttpsError('not-found', 'Coach not found');
    }
    const encrypted = (0, encryption_1.encryptFields)(updates, encryption_1.SENSITIVE_FIELDS.coach);
    await docRef.update({
        ...encrypted,
        updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        updatedBy: uid
    });
    return { success: true, message: 'Coach updated successfully' };
});
//# sourceMappingURL=coaches.js.map