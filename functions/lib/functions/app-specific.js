"use strict";
/**
 * App-Specific Functions
 * Custom business logic for the coaching app
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
exports.updateAthleteProfile = exports.addRestDay = exports.updateAthleteDetails = exports.submitReview = exports.completeDrill = exports.assignDrill = exports.createCoachDrill = exports.addAthlete = exports.createCoachProfile = void 0;
const https_1 = require("firebase-functions/v2/https");
const firebase_1 = __importStar(require("../firebase"));
const config_1 = require("../config");
const shared_1 = require("../shared");
// =============================================================================
// Coach-Athlete Setup Functions
// =============================================================================
/**
 * Create coach profile during registration
 */
exports.createCoachProfile = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const uid = (0, shared_1.requireAuth)(request.auth);
    const { email } = request.data;
    // User creating their own profile
    if (request.data.uid !== uid) {
        throw new https_1.HttpsError('permission-denied', 'You can only create your own profile');
    }
    const coachRef = firebase_1.db.collection('coaches').doc(uid);
    await coachRef.set({
        uid,
        email,
        createdAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, data: { id: uid }, message: 'Coach profile created' };
});
/**
 * Add a new athlete to a coach
 */
exports.addAthlete = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const coachUid = (0, shared_1.requireAuth)(request.auth);
    await (0, shared_1.requireRole)(coachUid, ['coach', 'admin']);
    const { name, pin } = request.data;
    if (!name || !pin) {
        throw new https_1.HttpsError('invalid-argument', 'Name and PIN are required');
    }
    const athleteRef = firebase_1.db.collection('athletes').doc();
    await athleteRef.set({
        name,
        pin,
        coachUid,
        level: 1,
        streak: 0,
        progress: 0.0,
        status: 'Training Not Started',
        skill_focus: 'General',
        difficulty: 'Easy',
        stars: 0,
        unlockedItems: [101, 201, 301],
        selectedOutfit: 101,
        selectedShoe: 201,
        selectedEquipment: 301,
        currentXp: 0.0,
        requiredXp: 1000.0,
        totalXp: 0,
        skillProgress: {
            General: 0.0,
            Agility: 0.0,
            Strength: 0.0,
            Cardio: 0.0,
        },
        createdAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, data: { id: athleteRef.id }, message: 'Athlete added successfully' };
});
// =============================================================================
// Drill Management Functions
// =============================================================================
/**
 * Create a coach drill template
 */
exports.createCoachDrill = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const coachUid = (0, shared_1.requireAuth)(request.auth);
    await (0, shared_1.requireRole)(coachUid, ['coach', 'admin']);
    const { name, goal, skillFocus, xp, videoUrl } = request.data;
    if (!name || !goal || !skillFocus || xp === undefined) {
        throw new https_1.HttpsError('invalid-argument', 'Name, goal, skillFocus, and xp are required');
    }
    const drillRef = await firebase_1.db
        .collection('coaches')
        .doc(coachUid)
        .collection('drills')
        .add({
        name,
        goal,
        skillFocus,
        xp,
        videoUrl,
        createdAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, data: { id: drillRef.id }, message: 'Drill template created' };
});
/**
 * Assign a drill to an athlete
 */
exports.assignDrill = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const coachUid = (0, shared_1.requireAuth)(request.auth);
    await (0, shared_1.requireRole)(coachUid, ['coach', 'admin']);
    const { athleteId, drillData } = request.data;
    if (!athleteId || !drillData) {
        throw new https_1.HttpsError('invalid-argument', 'athleteId and drillData are required');
    }
    // Verify athlete belongs to coach
    const athleteDoc = await firebase_1.db.collection('athletes').doc(athleteId).get();
    if (!athleteDoc.exists) {
        throw new https_1.HttpsError('not-found', 'Athlete not found');
    }
    const athleteData = athleteDoc.data();
    if (athleteData?.coachUid !== coachUid) {
        throw new https_1.HttpsError('permission-denied', 'You can only assign drills to your own athletes');
    }
    await firebase_1.db
        .collection('athletes')
        .doc(athleteId)
        .collection('todayDrills')
        .add({
        name: drillData.name,
        goal: drillData.goal,
        skillFocus: drillData.skillFocus,
        xp: drillData.xp,
        videoUrl: drillData.videoUrl,
        coachDrillId: drillData.id,
        coachUid,
        athleteId,
        assignedAt: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        completed: false,
        iconData: 0xe722,
    });
    return { success: true, message: 'Drill assigned successfully' };
});
/**
 * Complete a drill (athlete submits)
 */
exports.completeDrill = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    (0, shared_1.requireAuth)(request.auth);
    const { athleteId, drillId, drillName, xpGained, coachVideoUrl, athleteVideoUrl, coachUid } = request.data;
    if (!athleteId || !drillId || !drillName || xpGained === undefined) {
        throw new https_1.HttpsError('invalid-argument', 'Missing required fields');
    }
    const athleteRef = firebase_1.db.collection('athletes').doc(athleteId);
    const drillRef = athleteRef.collection('todayDrills').doc(drillId);
    const logRef = athleteRef.collection('logs').doc();
    const athleteDoc = await athleteRef.get();
    if (!athleteDoc.exists) {
        throw new https_1.HttpsError('not-found', 'Athlete not found');
    }
    const athleteData = athleteDoc.data();
    const skillFocus = athleteData?.skill_focus || 'General';
    const skillProgressField = `skillProgress.${skillFocus}`;
    const batch = firebase_1.db.batch();
    batch.update(drillRef, {
        completed: true,
        status: 'Pending Review',
        athleteVideoUrl,
    });
    batch.set(logRef, {
        drill: drillName,
        status: 'Pending Review',
        xp: xpGained,
        date: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        skillFocus,
        coachVideoUrl,
        athleteVideoUrl,
        coachUid,
        athleteId,
    });
    batch.update(athleteRef, {
        totalXp: firebase_1.default.firestore.FieldValue.increment(xpGained),
        currentXp: firebase_1.default.firestore.FieldValue.increment(xpGained),
        [skillProgressField]: firebase_1.default.firestore.FieldValue.increment(xpGained),
    });
    await batch.commit();
    return { success: true, message: 'Drill completed successfully' };
});
/**
 * Submit a review for a drill
 */
exports.submitReview = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const coachUid = (0, shared_1.requireAuth)(request.auth);
    await (0, shared_1.requireRole)(coachUid, ['coach', 'admin']);
    const { athleteId, logId, isApproved, feedback } = request.data;
    if (!athleteId || !logId || isApproved === undefined) {
        throw new https_1.HttpsError('invalid-argument', 'Missing required fields');
    }
    const newStatus = isApproved ? 'Approved' : 'Needs Work';
    const bonusXp = isApproved ? 25 : 0;
    const logRef = firebase_1.db.collection('athletes').doc(athleteId).collection('logs').doc(logId);
    const athleteRef = firebase_1.db.collection('athletes').doc(athleteId);
    const batch = firebase_1.db.batch();
    batch.update(logRef, {
        status: newStatus,
        feedback,
    });
    if (isApproved) {
        batch.update(athleteRef, {
            totalXp: firebase_1.default.firestore.FieldValue.increment(bonusXp),
            currentXp: firebase_1.default.firestore.FieldValue.increment(bonusXp),
            stars: firebase_1.default.firestore.FieldValue.increment(10),
        });
    }
    await batch.commit();
    return { success: true, message: isApproved ? 'Drill approved' : 'Feedback sent' };
});
// =============================================================================
// Athlete Management Functions
// =============================================================================
/**
 * Update athlete details (difficulty, focus, notes)
 */
exports.updateAthleteDetails = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const coachUid = (0, shared_1.requireAuth)(request.auth);
    await (0, shared_1.requireRole)(coachUid, ['coach', 'admin']);
    const { athleteId, difficulty, skillFocus, notes } = request.data;
    if (!athleteId) {
        throw new https_1.HttpsError('invalid-argument', 'athleteId is required');
    }
    const athleteRef = firebase_1.db.collection('athletes').doc(athleteId);
    const athleteDoc = await athleteRef.get();
    if (!athleteDoc.exists) {
        throw new https_1.HttpsError('not-found', 'Athlete not found');
    }
    const athleteData = athleteDoc.data();
    if (athleteData?.coachUid !== coachUid) {
        throw new https_1.HttpsError('permission-denied', 'You can only update your own athletes');
    }
    await athleteRef.update({
        difficulty,
        skill_focus: skillFocus,
        notes,
    });
    return { success: true, message: 'Athlete details updated' };
});
/**
 * Add a rest day for an athlete
 */
exports.addRestDay = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    const coachUid = (0, shared_1.requireAuth)(request.auth);
    await (0, shared_1.requireRole)(coachUid, ['coach', 'admin']);
    const { athleteId } = request.data;
    if (!athleteId) {
        throw new https_1.HttpsError('invalid-argument', 'athleteId is required');
    }
    const athleteRef = firebase_1.db.collection('athletes').doc(athleteId);
    const athleteDoc = await athleteRef.get();
    if (!athleteDoc.exists) {
        throw new https_1.HttpsError('not-found', 'Athlete not found');
    }
    const athleteData = athleteDoc.data();
    if (athleteData?.coachUid !== coachUid) {
        throw new https_1.HttpsError('permission-denied', 'You can only update your own athletes');
    }
    await athleteRef.update({
        status: 'Rest Day (Completed)',
        progress: 1.0,
    });
    return { success: true, message: 'Rest day added' };
});
/**
 * Update athlete profile (name, pin)
 */
exports.updateAthleteProfile = (0, https_1.onCall)({ region: config_1.config.region }, async (request) => {
    (0, shared_1.requireAuth)(request.auth);
    const { athleteId, newName, newPin } = request.data;
    if (!athleteId) {
        throw new https_1.HttpsError('invalid-argument', 'athleteId is required');
    }
    const updates = {};
    if (newName)
        updates.name = newName;
    if (newPin)
        updates.pin = newPin;
    if (Object.keys(updates).length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'At least one field to update is required');
    }
    await firebase_1.db.collection('athletes').doc(athleteId).update(updates);
    return { success: true, message: 'Profile updated successfully' };
});
//# sourceMappingURL=app-specific.js.map