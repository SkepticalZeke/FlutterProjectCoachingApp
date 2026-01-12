"use strict";
/**
 * Firebase Cloud Functions Entry Point
 *
 * Exports all Cloud Functions as independent microservices
 * Each function is separately deployable and scalable
 *
 * Project: fitness-coaching-app-5633f
 * Region: asia-southeast1 (Singapore)
 * Runtime: Node.js 22 with TypeScript
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
exports.checkAthleteProgress = exports.onAthleteUpdate = exports.onDrillUpdate = exports.clearNotifications = exports.markAllNotificationsRead = exports.markNotificationRead = exports.getNotifications = exports.reviewDrill = exports.submitDrill = exports.createDrill = exports.getDrill = exports.getDrills = exports.updateCoach = exports.createCoach = exports.getCoach = exports.getCoaches = exports.deleteAthlete = exports.updateAthlete = exports.createAthlete = exports.getAthlete = exports.getAthletes = void 0;
const functions = __importStar(require("firebase-functions"));
// Initialize Firebase FIRST
const firebase_1 = __importStar(require("./firebase"));
const config_1 = require("./config");
// =============================================================================
// Athlete Functions
// =============================================================================
var athletes_1 = require("./functions/athletes");
Object.defineProperty(exports, "getAthletes", { enumerable: true, get: function () { return athletes_1.getAthletes; } });
Object.defineProperty(exports, "getAthlete", { enumerable: true, get: function () { return athletes_1.getAthlete; } });
Object.defineProperty(exports, "createAthlete", { enumerable: true, get: function () { return athletes_1.createAthlete; } });
Object.defineProperty(exports, "updateAthlete", { enumerable: true, get: function () { return athletes_1.updateAthlete; } });
Object.defineProperty(exports, "deleteAthlete", { enumerable: true, get: function () { return athletes_1.deleteAthlete; } });
// =============================================================================
// Coach Functions
// =============================================================================
var coaches_1 = require("./functions/coaches");
Object.defineProperty(exports, "getCoaches", { enumerable: true, get: function () { return coaches_1.getCoaches; } });
Object.defineProperty(exports, "getCoach", { enumerable: true, get: function () { return coaches_1.getCoach; } });
Object.defineProperty(exports, "createCoach", { enumerable: true, get: function () { return coaches_1.createCoach; } });
Object.defineProperty(exports, "updateCoach", { enumerable: true, get: function () { return coaches_1.updateCoach; } });
// =============================================================================
// Drill Functions
// =============================================================================
var drills_1 = require("./functions/drills");
Object.defineProperty(exports, "getDrills", { enumerable: true, get: function () { return drills_1.getDrills; } });
Object.defineProperty(exports, "getDrill", { enumerable: true, get: function () { return drills_1.getDrill; } });
Object.defineProperty(exports, "createDrill", { enumerable: true, get: function () { return drills_1.createDrill; } });
Object.defineProperty(exports, "submitDrill", { enumerable: true, get: function () { return drills_1.submitDrill; } });
Object.defineProperty(exports, "reviewDrill", { enumerable: true, get: function () { return drills_1.reviewDrill; } });
// =============================================================================
// Notification Functions
// =============================================================================
var notifications_1 = require("./functions/notifications");
Object.defineProperty(exports, "getNotifications", { enumerable: true, get: function () { return notifications_1.getNotifications; } });
Object.defineProperty(exports, "markNotificationRead", { enumerable: true, get: function () { return notifications_1.markNotificationRead; } });
Object.defineProperty(exports, "markAllNotificationsRead", { enumerable: true, get: function () { return notifications_1.markAllNotificationsRead; } });
Object.defineProperty(exports, "clearNotifications", { enumerable: true, get: function () { return notifications_1.clearNotifications; } });
// =============================================================================
// Firestore Triggers (kept from original)
// =============================================================================
const region = functions.region(config_1.config.region);
/**
 * On Drill Update Trigger
 * Fires when any drill document is updated
 */
exports.onDrillUpdate = region.firestore
    .document('drills/{drillId}')
    .onWrite(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    // Check if drill was completed
    if (beforeData?.completed === false && afterData?.completed === true) {
        console.log(`Drill ${context.params.drillId} marked as completed`);
        if (afterData?.athleteId) {
            await updateAthleteProgress(afterData.athleteId);
        }
    }
});
/**
 * On Athlete Update Trigger
 * Fires when an athlete document is updated
 */
exports.onAthleteUpdate = region.firestore
    .document('athletes/{athleteId}')
    .onWrite(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    // Streak milestone notification
    if (beforeData?.streak !== afterData?.streak && afterData?.streak) {
        if (afterData.streak % 7 === 0) {
            await sendNotification(context.params.athleteId, `Congratulations! You've maintained a ${afterData.streak}-day streak!`, 'streak_achievement');
        }
    }
    // Level up notification
    if (beforeData?.level !== afterData?.level && afterData?.level) {
        await sendNotification(context.params.athleteId, `Level up! You're now level ${afterData.level}!`, 'level_up');
    }
});
/**
 * Scheduled: Check Athlete Progress
 * Runs every 30 minutes during active hours
 */
exports.checkAthleteProgress = region.pubsub
    .schedule('every 30 minutes from 06:00 to 00:00')
    .timeZone('Asia/Singapore')
    .onRun(async () => {
    console.log('Checking athlete progress...');
    const athletesSnapshot = await firebase_1.db.collection('athletes').get();
    for (const athleteDoc of athletesSnapshot.docs) {
        const drillsSnapshot = await firebase_1.db
            .collection('drills')
            .where('athleteId', '==', athleteDoc.id)
            .where('completed', '==', false)
            .get();
        if (!drillsSnapshot.empty) {
            await sendNotification(athleteDoc.id, 'You have pending drills to complete!', 'drill_reminder');
        }
    }
    return null;
});
// =============================================================================
// Helper Functions
// =============================================================================
async function updateAthleteProgress(athleteId) {
    const athleteRef = firebase_1.db.collection('athletes').doc(athleteId);
    const athleteDoc = await athleteRef.get();
    if (!athleteDoc.exists)
        return;
    const drillsSnapshot = await firebase_1.db
        .collection('drills')
        .where('athleteId', '==', athleteId)
        .get();
    let completedCount = 0;
    let totalCount = 0;
    drillsSnapshot.forEach(doc => {
        totalCount++;
        if (doc.data().completed) {
            completedCount++;
        }
    });
    const progress = totalCount > 0 ? completedCount / totalCount : 0;
    await athleteRef.update({
        progress,
        completedDrills: completedCount,
        totalDrills: totalCount
    });
}
async function sendNotification(userId, message, type) {
    await firebase_1.db.collection('notifications').add({
        userId,
        type,
        message,
        timestamp: firebase_1.default.firestore.FieldValue.serverTimestamp(),
        read: false
    });
}
//# sourceMappingURL=index.js.map