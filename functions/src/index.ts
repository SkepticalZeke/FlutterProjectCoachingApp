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

import * as functions from 'firebase-functions';

// Initialize Firebase FIRST
import admin, { db } from './firebase';
import { config } from './config';

// =============================================================================
// Athlete Functions
// =============================================================================

export {
  getAthletes,
  getAthlete,
  createAthlete,
  updateAthlete,
  deleteAthlete
} from './functions/athletes';

// =============================================================================
// Coach Functions
// =============================================================================

export {
  getCoaches,
  getCoach,
  createCoach,
  updateCoach
} from './functions/coaches';

// =============================================================================
// Drill Functions
// =============================================================================

export {
  getDrills,
  getDrill,
  createDrill,
  submitDrill,
  reviewDrill
} from './functions/drills';

// =============================================================================
// Notification Functions
// =============================================================================

export {
  getNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  clearNotifications
} from './functions/notifications';

// =============================================================================
// Firestore Triggers (kept from original)
// =============================================================================

const region = functions.region(config.region);

/**
 * On Drill Update Trigger
 * Fires when any drill document is updated
 */
export const onDrillUpdate = region.firestore
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
export const onAthleteUpdate = region.firestore
  .document('athletes/{athleteId}')
  .onWrite(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Streak milestone notification
    if (beforeData?.streak !== afterData?.streak && afterData?.streak) {
      if (afterData.streak % 7 === 0) {
        await sendNotification(
          context.params.athleteId,
          `Congratulations! You've maintained a ${afterData.streak}-day streak!`,
          'streak_achievement'
        );
      }
    }

    // Level up notification
    if (beforeData?.level !== afterData?.level && afterData?.level) {
      await sendNotification(
        context.params.athleteId,
        `Level up! You're now level ${afterData.level}!`,
        'level_up'
      );
    }
  });

/**
 * Scheduled: Check Athlete Progress
 * Runs every 30 minutes during active hours
 */
export const checkAthleteProgress = region.pubsub
  .schedule('every 30 minutes from 06:00 to 00:00')
  .timeZone('Asia/Singapore')
  .onRun(async () => {
    console.log('Checking athlete progress...');

    const athletesSnapshot = await db.collection('athletes').get();

    for (const athleteDoc of athletesSnapshot.docs) {
      const drillsSnapshot = await db
        .collection('drills')
        .where('athleteId', '==', athleteDoc.id)
        .where('completed', '==', false)
        .get();

      if (!drillsSnapshot.empty) {
        await sendNotification(
          athleteDoc.id,
          'You have pending drills to complete!',
          'drill_reminder'
        );
      }
    }

    return null;
  });

// =============================================================================
// Helper Functions
// =============================================================================

async function updateAthleteProgress(athleteId: string): Promise<void> {
  const athleteRef = db.collection('athletes').doc(athleteId);
  const athleteDoc = await athleteRef.get();

  if (!athleteDoc.exists) return;

  const drillsSnapshot = await db
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

async function sendNotification(userId: string, message: string, type: string): Promise<void> {
  await db.collection('notifications').add({
    userId,
    type,
    message,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    read: false
  });
}