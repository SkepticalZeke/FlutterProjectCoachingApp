/**
 * Firebase Cloud Functions Entry Point
 * 
 * Exports all Cloud Functions as independent microservices
 * Each function is separately deployable and scalable
 * ALL functions use Gen 2 (Cloud Run) infrastructure
 * 
 * Project: fitness-coaching-app-5633f
 * Region: asia-southeast1 (Singapore)
 * Runtime: Node.js 22 with TypeScript
 */

// Gen 2 imports
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';

// Initialize Firebase FIRST
import admin, { db } from './firebase';
import { config } from './config';

// =============================================================================
// Athlete Functions (Gen 2 Callable)
// =============================================================================

export {
  getAthletes,
  getAthlete,
  createAthlete,
  updateAthlete,
  deleteAthlete
} from './functions/athletes';

// =============================================================================
// Coach Functions (Gen 2 Callable)
// =============================================================================

export {
  getCoaches,
  getCoach,
  createCoach,
  updateCoach
} from './functions/coaches';

// =============================================================================
// Drill Functions (Gen 2 Callable)
// =============================================================================

export {
  getDrills,
  getDrill,
  createDrill,
  submitDrill,
  reviewDrill
} from './functions/drills';

// =============================================================================
// Notification Functions (Gen 2 Callable)
// =============================================================================

export {
  getNotifications,
  markNotificationRead,
  markAllNotificationsRead,
  clearNotifications
} from './functions/notifications';

// =============================================================================
// App-Specific Functions (Gen 2 Callable)
// =============================================================================

export {
  createCoachProfile,
  addAthlete,
  createCoachDrill,
  assignDrill,
  completeDrill,
  submitReview,
  updateAthleteDetails,
  addRestDay,
  updateAthleteProfile
} from './functions/app-specific';

// =============================================================================
// Firestore Triggers (Gen 2)
// =============================================================================

/**
 * On Drill Update Trigger (Gen 2)
 * Fires when any drill document is created, updated, or deleted
 */
export const onDrillUpdate = onDocumentWritten(
  {
    document: 'drills/{drillId}',
    region: config.region,
  },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    // Check if drill was completed
    if (beforeData?.completed === false && afterData?.completed === true) {
      console.log(`Drill ${event.params.drillId} marked as completed`);

      if (afterData?.athleteId) {
        await updateAthleteProgress(afterData.athleteId);
      }
    }
  }
);

/**
 * On Athlete Update Trigger (Gen 2)
 * Fires when an athlete document is created, updated, or deleted
 */
export const onAthleteUpdate = onDocumentWritten(
  {
    document: 'athletes/{athleteId}',
    region: config.region,
  },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    // Streak milestone notification
    if (beforeData?.streak !== afterData?.streak && afterData?.streak) {
      if (afterData.streak % 7 === 0) {
        await sendNotification(
          event.params.athleteId,
          `Congratulations! You've maintained a ${afterData.streak}-day streak!`,
          'streak_achievement'
        );
      }
    }

    // Level up notification
    if (beforeData?.level !== afterData?.level && afterData?.level) {
      await sendNotification(
        event.params.athleteId,
        `Level up! You're now level ${afterData.level}!`,
        'level_up'
      );
    }
  }
);

// =============================================================================
// Scheduled Functions (Gen 2)
// =============================================================================

/**
 * Scheduled: Check Athlete Progress (Gen 2)
 * Runs every 30 minutes during active hours (Singapore time)
 */
export const checkAthleteProgress = onSchedule(
  {
    schedule: 'every 30 minutes from 06:00 to 23:30',
    timeZone: 'Asia/Singapore',
    region: config.region,
  },
  async () => {
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
  }
);

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