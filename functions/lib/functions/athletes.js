"use strict";
/**
 * Athletes Microservice Functions
 * Each function is independently deployable and scalable
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
exports.deleteAthlete = exports.updateAthlete = exports.createAthlete = exports.getAthlete = exports.getAthletes = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = __importStar(require("../firebase"));
const config_1 = require("../config");
const encryption_1 = require("../utils/encryption");
const shared_1 = require("../shared");
const COLLECTION = 'athletes';
// =============================================================================
// Functions
// =============================================================================
/**
 * Get all athletes (filtered by role)
 */
exports.getAthletes = (0, https_1.onCall)({ region: config_1.config.region, secrets: [config_1.encryptionKeySecret] }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const role = await (0, shared_1.requireRole)(uid, ['coach', 'admin']);
    let query = firebase_1.db.collection(COLLECTION);
    // Coaches can only see their own athletes
    if (role === 'coach') {
        query = query.where('coachId', '==', uid);
    }
    const snapshot = await query.orderBy('name').limit(100).get();
    const athletes = [];
    snapshot.forEach(doc => {
        const data = doc.data();
        const decrypted = (0, encryption_1.decryptFields)(data, encryption_1.SENSITIVE_FIELDS.athlete);
        athletes.push({ id: doc.id, ...decrypted });
    });
    return { success: true, data: athletes };
});
/**
 * Get a single athlete by ID
 */
exports.getAthlete = (0, https_1.onCall)({ region: config_1.config.region, secrets: [config_1.encryptionKeySecret] }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const { athleteId } = request.data;
    if (!athleteId) {
        throw new https_1.HttpsError('invalid-argument', 'athleteId is required');
    }
    const doc = await firebase_1.db.collection(COLLECTION).doc(athleteId).get();
    if (!doc.exists) {
        throw new https_1.HttpsError('not-found', 'Athlete not found');
    }
    const data = doc.data();
    // Check access: athlete can view themselves, coach can view their athletes, admin can view all
    const role = await (0, shared_1.requireRole)(uid, ['athlete', 'coach', 'admin']);
    if (role === 'athlete' && doc.id !== uid) {
        throw new https_1.HttpsError('permission-denied', 'You can only view your own profile');
    }
    if (role === 'coach' && data.coachId !== uid) {
        throw new https_1.HttpsError('permission-denied', 'You can only view your own athletes');
    }
    const decrypted = (0, encryption_1.decryptFields)(data, encryption_1.SENSITIVE_FIELDS.athlete);
    return { success: true, data: { id: doc.id, ...decrypted } };
});
/**
 * Create a new athlete
 */
exports.createAthlete = (0, https_1.onCall)({ region: config_1.config.region, secrets: [config_1.encryptionKeySecret] }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    await (0, shared_1.requireRole)(uid, ['coach', 'admin']);
    const athleteData = request.data;
    if (!athleteData.name || !athleteData.email) {
        throw new https_1.HttpsError('invalid-argument', 'Name and email are required');
    }
    // Encrypt sensitive fields
    const encrypted = (0, encryption_1.encryptFields)(athleteData, encryption_1.SENSITIVE_FIELDS.athlete);
    const docRef = await firebase_1.db.collection(COLLECTION).add({
        ...encrypted,
        createdAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        createdBy: uid
    });
    return { success: true, data: { id: docRef.id }, message: 'Athlete created successfully' };
});
/**
 * Update an existing athlete
 */
exports.updateAthlete = (0, https_1.onCall)({ region: config_1.config.region, secrets: [config_1.encryptionKeySecret] }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const { athleteId, updates } = request.data;
    if (!athleteId) {
        throw new https_1.HttpsError('invalid-argument', 'athleteId is required');
    }
    const docRef = firebase_1.db.collection(COLLECTION).doc(athleteId);
    const doc = await docRef.get();
    if (!doc.exists) {
        throw new https_1.HttpsError('not-found', 'Athlete not found');
    }
    const existingData = doc.data();
    const role = await (0, shared_1.requireRole)(uid, ['athlete', 'coach', 'admin']);
    // Check permissions
    if (role === 'athlete' && doc.id !== uid) {
        throw new https_1.HttpsError('permission-denied', 'You can only update your own profile');
    }
    if (role === 'coach' && existingData.coachId !== uid) {
        throw new https_1.HttpsError('permission-denied', 'You can only update your own athletes');
    }
    // Encrypt sensitive fields
    const encrypted = (0, encryption_1.encryptFields)(updates, encryption_1.SENSITIVE_FIELDS.athlete);
    await docRef.update({
        ...encrypted,
        updatedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        updatedBy: uid
    });
    return { success: true, message: 'Athlete updated successfully' };
});
/**
 * Delete an athlete (admin only)
 */
exports.deleteAthlete = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    await (0, shared_1.requireRole)(uid, ['admin']);
    const { athleteId } = request.data;
    if (!athleteId) {
        throw new https_1.HttpsError('invalid-argument', 'athleteId is required');
    }
    const docRef = firebase_1.db.collection(COLLECTION).doc(athleteId);
    const doc = await docRef.get();
    if (!doc.exists) {
        throw new https_1.HttpsError('not-found', 'Athlete not found');
    }
    await docRef.delete();
    return { success: true, message: 'Athlete deleted successfully' };
});
//# sourceMappingURL=athletes.js.map