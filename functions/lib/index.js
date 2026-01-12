"use strict";
/**
 * Firebase Cloud Functions Entry Point
 *
 * This file exports all Cloud Functions for the Fitness Coaching App
 *
 * Architecture:
 * - Express.js API wrapped in onRequest for HTTP endpoints
 * - Independent microservices for different business domains
 * - Firestore triggers for real-time updates
 * - Scheduled functions for periodic tasks
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.onAthleteUpdate = exports.onDrillUpdate = exports.checkAthleteProgress = exports.api = void 0;
const functions = __importStar(require("firebase-functions"));
const https_1 = require("firebase-functions/v2/https");
// Initialize Firebase FIRST - before any other imports that use it
const firebase_1 = __importStar(require("./firebase"));
// Import configuration (includes secret definitions)
const config_1 = require("./config");
// Import Express app (after firebase is initialized)
const app_1 = __importDefault(require("./app"));
// =============================================================================
// Region Configuration
// =============================================================================
const region = functions.region(config_1.config.region);
// =============================================================================
// HTTP API (Express.js wrapped in Cloud Function)
// =============================================================================
/**
 * Main API endpoint
 * All HTTP requests are handled by Express.js
 *
 * Base URL: https://asia-southeast1-fitness-coaching-app-5633f.cloudfunctions.net/api
 *
 * Uses Firebase Secrets for the encryption key
 */
exports.api = (0, https_1.onRequest)({
    region: config_1.config.region,
    secrets: [config_1.encryptionKeySecret], // Inject secret at runtime
}, app_1.default);
// =============================================================================
// Scheduled Functions
// =============================================================================
/**
 * Check Athlete Progress
 * Runs every 30 minutes during active hours to remind athletes of pending drills
 */
exports.checkAthleteProgress = region.pubsub
    .schedule('every 30 minutes from 06:00 to 00:00')
    .timeZone('Asia/Singapore') // Updated for singapore region
    .onRun(async () => {
    console.log('Checking athlete progress...');
    try {
        // Get all athletes from Firestore
        const athletesSnapshot = await firebase_1.db.collection('athletes').get();
        for (const athleteDoc of athletesSnapshot.docs) {
            const athleteId = athleteDoc.id;
            // Check for incomplete drills assigned to this athlete
            const drillsSnapshot = await firebase_1.db
                .collection('drills')
                .where('athleteId', '==', athleteId)
                .where('completed', '==', false)
                .get();
            if (!drillsSnapshot.empty) {
                // Send notification about pending drills
                await sendNotification(athleteId, 'You have pending drills to complete!', 'drill_reminder');
            }
        }
        console.log('Athlete progress check completed successfully');
        return null;
    }
    catch (error) {
        console.error('Error checking athlete progress:', error);
        throw new functions.https.HttpsError('internal', 'Failed to check athlete progress');
    }
});
// =============================================================================
// Firestore Triggers
// =============================================================================
/**
 * On Drill Update Trigger
 * Fires when any drill document is created, updated, or deleted
 */
exports.onDrillUpdate = region.firestore
    .document('drills/{drillId}')
    .onWrite(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    // Check if drill was completed
    if (beforeData?.completed === false && afterData?.completed === true) {
        console.log(`Drill ${context.params.drillId} marked as completed`);
        // Update athlete's progress
        if (afterData && afterData.athleteId) {
            await updateAthleteProgress(afterData.athleteId);
            // Send notification to coach about completion
            await notifyCoachOfCompletion(afterData.athleteId, context.params.drillId);
        }
    }
    // Check if drill status changed to "Pending Review"
    if (beforeData?.status !== 'Pending Review' && afterData?.status === 'Pending Review') {
        console.log(`Drill ${context.params.drillId} is pending review`);
        // Send notification to coach
        if (afterData && afterData.athleteId) {
            await sendNotificationToCoach(afterData.athleteId, 'A drill submission is pending your review', 'review_request');
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
    // Check if streak has changed
    if (beforeData?.streak !== afterData?.streak && afterData?.streak) {
        console.log(`Athlete ${context.params.athleteId} streak updated to ${afterData.streak}`);
        // Send achievement notification if streak milestone reached
        if (afterData.streak % 7 === 0) { // Every week streak
            await sendNotification(context.params.athleteId, `Congratulations! You've maintained a ${afterData.streak}-day streak!`, 'streak_achievement');
        }
    }
    // Check if level has changed
    if (beforeData?.level !== afterData?.level && afterData?.level) {
        console.log(`Athlete ${context.params.athleteId} leveled up to ${afterData.level}`);
        await sendNotification(context.params.athleteId, `Level up! You're now level ${afterData.level}!`, 'level_up');
    }
});
// =============================================================================
// Helper Functions
// =============================================================================
/**
 * Update athlete progress statistics
 */
async function updateAthleteProgress(athleteId) {
    try {
        const athleteRef = firebase_1.db.collection('athletes').doc(athleteId);
        const athleteDoc = await athleteRef.get();
        if (!athleteDoc.exists) {
            console.error(`Athlete ${athleteId} does not exist`);
            return;
        }
        // Calculate progress percentage
        const drillsSnapshot = await firebase_1.db
            .collection('drills')
            .where('athleteId', '==', athleteId)
            .get();
        let completedCount = 0;
        let totalCount = 0;
        drillsSnapshot.forEach((doc) => {
            const drillData = doc.data();
            totalCount++;
            if (drillData.completed) {
                completedCount++;
            }
        });
        const progress = totalCount > 0 ? completedCount / totalCount : 0;
        // Update athlete's progress
        await athleteRef.update({
            progress: progress,
            completedDrills: completedCount,
            totalDrills: totalCount
        });
        console.log(`Updated progress for athlete ${athleteId}: ${Math.round(progress * 100)}%`);
    }
    catch (error) {
        console.error('Error updating athlete progress:', error);
        throw error;
    }
}
/**
 * Notify coach when an athlete completes a drill
 */
async function notifyCoachOfCompletion(athleteId, drillId) {
    try {
        // Get athlete and coach info
        const athleteDoc = await firebase_1.db.collection('athletes').doc(athleteId).get();
        if (!athleteDoc.exists)
            return;
        const athleteData = athleteDoc.data();
        const coachId = athleteData.coachId;
        if (coachId) {
            console.log(`Notifying coach ${coachId} about drill ${drillId} completion by athlete ${athleteId}`);
            // Add notification to Firestore for the coach
            await firebase_1.db.collection('notifications').add({
                userId: coachId,
                type: 'drill_completion',
                message: `Athlete ${athleteData.name || 'Unknown Athlete'} has completed a drill`,
                drillId: drillId,
                athleteId: athleteId,
                timestamp: firebase_1.default.firestore.FieldValue.serverTimestamp(),
                read: false
            });
        }
    }
    catch (error) {
        console.error('Error notifying coach:', error);
        throw error;
    }
}
/**
 * Send notification to a user
 */
async function sendNotification(userId, message, type) {
    try {
        await firebase_1.db.collection('notifications').add({
            userId: userId,
            type: type,
            message: message,
            timestamp: firebase_1.default.firestore.FieldValue.serverTimestamp(),
            read: false
        });
        console.log(`Notification sent to user ${userId}: ${message}`);
    }
    catch (error) {
        console.error('Error sending notification:', error);
        throw error;
    }
}
/**
 * Send notification to an athlete's coach
 */
async function sendNotificationToCoach(athleteId, message, type) {
    try {
        const athleteDoc = await firebase_1.db.collection('athletes').doc(athleteId).get();
        if (!athleteDoc.exists)
            return;
        const athleteData = athleteDoc.data();
        const coachId = athleteData.coachId;
        if (coachId) {
            await firebase_1.db.collection('notifications').add({
                userId: coachId,
                type: type,
                message: message,
                athleteId: athleteId,
                timestamp: firebase_1.default.firestore.FieldValue.serverTimestamp(),
                read: false
            });
            console.log(`Notification sent to coach ${coachId}: ${message}`);
        }
    }
    catch (error) {
        console.error('Error sending notification to coach:', error);
        throw error;
    }
}
//# sourceMappingURL=index.js.map