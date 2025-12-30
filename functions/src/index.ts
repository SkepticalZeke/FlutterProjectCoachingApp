import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize the Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();

// Scheduled function to periodically check athlete progress
export const checkAthleteProgress = functions.pubsub
  .schedule('every 30 minutes from 06:00 to 00:00')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    console.log('Checking athlete progress...');

    try {
      // Get all athletes from Firestore
      const athletesSnapshot = await db.collection('athletes').get();

      for (const athleteDoc of athletesSnapshot.docs) {
        const athleteId = athleteDoc.id;
        
        // Check for incomplete drills assigned to this athlete
        const drillsSnapshot = await db
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
    } catch (error) {
      console.error('Error checking athlete progress:', error);
      throw new functions.https.HttpsError('internal', 'Failed to check athlete progress');
    }
  });

// Firestore trigger for real-time checks when drills are updated
export const onDrillUpdate = functions.firestore
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

// Firestore trigger for athlete updates
export const onAthleteUpdate = functions.firestore
  .document('athletes/{athleteId}')
  .onWrite(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if streak has changed
    if (beforeData?.streak !== afterData?.streak && afterData?.streak) {
      console.log(`Athlete ${context.params.athleteId} streak updated to ${afterData.streak}`);

      // Send achievement notification if streak milestone reached
      if (afterData.streak % 7 === 0) { // Every week streak
        await sendNotification(
          context.params.athleteId,
          `Congratulations! You've maintained a ${afterData.streak}-day streak!`,
          'streak_achievement'
        );
      }
    }

    // Check if level has changed
    if (beforeData?.level !== afterData?.level && afterData?.level) {
      console.log(`Athlete ${context.params.athleteId} leveled up to ${afterData.level}`);

      await sendNotification(
        context.params.athleteId,
        `Level up! You're now level ${afterData.level}!`,
        'level_up'
      );
    }
  });

// Helper function to update athlete progress
async function updateAthleteProgress(athleteId: string) {
  try {
    const athleteRef = db.collection('athletes').doc(athleteId);
    const athleteDoc = await athleteRef.get();
    
    if (!athleteDoc.exists) {
      console.error(`Athlete ${athleteId} does not exist`);
      return;
    }

    // Calculate progress percentage
    const drillsSnapshot = await db
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
  } catch (error) {
    console.error('Error updating athlete progress:', error);
    throw error;
  }
}

// Helper function to notify coach of drill completion
async function notifyCoachOfCompletion(athleteId: string, drillId: string) {
  try {
    // Get athlete and coach info
    const athleteDoc = await db.collection('athletes').doc(athleteId).get();
    if (!athleteDoc.exists) return;

    const athleteData = athleteDoc.data()!;
    const coachId = athleteData.coachId; // Assuming athletes have a coachId field

    if (coachId) {
      // In a real implementation, you would send a push notification or email
      console.log(`Notifying coach ${coachId} about drill ${drillId} completion by athlete ${athleteId}`);

      // Add notification to Firestore for the coach
      await db.collection('notifications').add({
        userId: coachId,
        type: 'drill_completion',
        message: `Athlete ${athleteData.name || 'Unknown Athlete'} has completed a drill`,
        drillId: drillId,
        athleteId: athleteId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false
      });
    }
  } catch (error) {
    console.error('Error notifying coach:', error);
    throw error;
  }
}

// Helper function to send notification to athlete
async function sendNotification(userId: string, message: string, type: string) {
  try {
    // Add notification to Firestore
    await db.collection('notifications').add({
      userId: userId,
      type: type,
      message: message,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false
    });
    
    console.log(`Notification sent to user ${userId}: ${message}`);
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
}

// Helper function to send notification to coach
async function sendNotificationToCoach(athleteId: string, message: string, type: string) {
  try {
    const athleteDoc = await db.collection('athletes').doc(athleteId).get();
    if (!athleteDoc.exists) return;
    
    const athleteData = athleteDoc.data()!;
    const coachId = athleteData.coachId;
    
    if (coachId) {
      await db.collection('notifications').add({
        userId: coachId,
        type: type,
        message: message,
        athleteId: athleteId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false
      });
      
      console.log(`Notification sent to coach ${coachId}: ${message}`);
    }
  } catch (error) {
    console.error('Error sending notification to coach:', error);
    throw error;
  }
}