/**
 * App-Specific Functions
 * Custom business logic for the coaching app
 */

import { onCall, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import admin, { db } from '../firebase';
import { config } from '../config';
import { requireAuth, requireRole, FunctionResponse } from '../shared';

// =============================================================================
// Coach-Athlete Setup Functions
// =============================================================================

/**
 * Create coach profile during registration
 */
export const createCoachProfile = onCall(
  { region: config.region },
  async (request: CallableRequest<{ uid: string; email: string }>): Promise<FunctionResponse<{ id: string }>> => {
    const uid = requireAuth(request.auth);
    const { email } = request.data;

    // User creating their own profile
    if (request.data.uid !== uid) {
      throw new HttpsError('permission-denied', 'You can only create your own profile');
    }

    const coachRef = db.collection('coaches').doc(uid);
    await coachRef.set({
      uid,
      email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, data: { id: uid }, message: 'Coach profile created' };
  }
);

/**
 * Add a new athlete to a coach
 */
export const addAthlete = onCall(
  { region: config.region },
  async (request: CallableRequest<{ name: string; pin: string }>): Promise<FunctionResponse<{ id: string }>> => {
    const coachUid = requireAuth(request.auth);
    await requireRole(coachUid, ['coach', 'admin']);

    const { name, pin } = request.data;

    if (!name || !pin) {
      throw new HttpsError('invalid-argument', 'Name and PIN are required');
    }

    const athleteRef = db.collection('athletes').doc();
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
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, data: { id: athleteRef.id }, message: 'Athlete added successfully' };
  }
);

// =============================================================================
// Drill Management Functions
// =============================================================================

/**
 * Create a coach drill template
 */
export const createCoachDrill = onCall(
  { region: config.region },
  async (request: CallableRequest<{
    name: string;
    goal: string;
    skillFocus: string;
    xp: number;
    videoUrl: string;
  }>): Promise<FunctionResponse<{ id: string }>> => {
    const coachUid = requireAuth(request.auth);
    await requireRole(coachUid, ['coach', 'admin']);

    const { name, goal, skillFocus, xp, videoUrl } = request.data;

    if (!name || !goal || !skillFocus || xp === undefined) {
      throw new HttpsError('invalid-argument', 'Name, goal, skillFocus, and xp are required');
    }

    const drillRef = await db
      .collection('coaches')
      .doc(coachUid)
      .collection('drills')
      .add({
        name,
        goal,
        skillFocus,
        xp,
        videoUrl,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return { success: true, data: { id: drillRef.id }, message: 'Drill template created' };
  }
);

/**
 * Assign a drill to an athlete
 */
export const assignDrill = onCall(
  { region: config.region },
  async (request: CallableRequest<{
    athleteId: string;
    drillData: {
      id: string;
      name: string;
      goal: string;
      skillFocus: string;
      xp: number;
      videoUrl: string;
    };
  }>): Promise<FunctionResponse> => {
    const coachUid = requireAuth(request.auth);
    await requireRole(coachUid, ['coach', 'admin']);

    const { athleteId, drillData } = request.data;

    if (!athleteId || !drillData) {
      throw new HttpsError('invalid-argument', 'athleteId and drillData are required');
    }

    // Verify athlete belongs to coach
    const athleteDoc = await db.collection('athletes').doc(athleteId).get();
    if (!athleteDoc.exists) {
      throw new HttpsError('not-found', 'Athlete not found');
    }

    const athleteData = athleteDoc.data();
    if (athleteData?.coachUid !== coachUid) {
      throw new HttpsError('permission-denied', 'You can only assign drills to your own athletes');
    }

    await db
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
        assignedAt: admin.firestore.FieldValue.serverTimestamp(),
        completed: false,
        iconData: 0xe722,
      });

    return { success: true, message: 'Drill assigned successfully' };
  }
);

/**
 * Complete a drill (athlete submits)
 */
export const completeDrill = onCall(
  { region: config.region },
  async (request: CallableRequest<{
    athleteId: string;
    drillId: string;
    drillName: string;
    xpGained: number;
    coachVideoUrl: string;
    athleteVideoUrl: string;
    coachUid: string;
  }>): Promise<FunctionResponse> => {
    requireAuth(request.auth);

    const { athleteId, drillId, drillName, xpGained, coachVideoUrl, athleteVideoUrl, coachUid } = request.data;

    if (!athleteId || !drillId || !drillName || xpGained === undefined) {
      throw new HttpsError('invalid-argument', 'Missing required fields');
    }

    const athleteRef = db.collection('athletes').doc(athleteId);
    const drillRef = athleteRef.collection('todayDrills').doc(drillId);
    const logRef = athleteRef.collection('logs').doc();

    const athleteDoc = await athleteRef.get();
    if (!athleteDoc.exists) {
      throw new HttpsError('not-found', 'Athlete not found');
    }

    const athleteData = athleteDoc.data();
    const skillFocus = athleteData?.skill_focus || 'General';
    const skillProgressField = `skillProgress.${skillFocus}`;

    const batch = db.batch();

    batch.update(drillRef, {
      completed: true,
      status: 'Pending Review',
      athleteVideoUrl,
    });

    batch.set(logRef, {
      drill: drillName,
      status: 'Pending Review',
      xp: xpGained,
      date: admin.firestore.FieldValue.serverTimestamp(),
      skillFocus,
      coachVideoUrl,
      athleteVideoUrl,
      coachUid,
      athleteId,
    });

    batch.update(athleteRef, {
      totalXp: admin.firestore.FieldValue.increment(xpGained),
      currentXp: admin.firestore.FieldValue.increment(xpGained),
      [skillProgressField]: admin.firestore.FieldValue.increment(xpGained),
    });

    await batch.commit();

    return { success: true, message: 'Drill completed successfully' };
  }
);

/**
 * Submit a review for a drill
 */
export const submitReview = onCall(
  { region: config.region },
  async (request: CallableRequest<{
    athleteId: string;
    logId: string;
    isApproved: boolean;
    feedback: string;
  }>): Promise<FunctionResponse> => {
    const coachUid = requireAuth(request.auth);
    await requireRole(coachUid, ['coach', 'admin']);

    const { athleteId, logId, isApproved, feedback } = request.data;

    if (!athleteId || !logId || isApproved === undefined) {
      throw new HttpsError('invalid-argument', 'Missing required fields');
    }

    const newStatus = isApproved ? 'Approved' : 'Needs Work';
    const bonusXp = isApproved ? 25 : 0;

    const logRef = db.collection('athletes').doc(athleteId).collection('logs').doc(logId);
    const athleteRef = db.collection('athletes').doc(athleteId);

    const batch = db.batch();

    batch.update(logRef, {
      status: newStatus,
      feedback,
    });

    if (isApproved) {
      batch.update(athleteRef, {
        totalXp: admin.firestore.FieldValue.increment(bonusXp),
        currentXp: admin.firestore.FieldValue.increment(bonusXp),
        stars: admin.firestore.FieldValue.increment(10),
      });
    }

    await batch.commit();

    return { success: true, message: isApproved ? 'Drill approved' : 'Feedback sent' };
  }
);

// =============================================================================
// Athlete Management Functions
// =============================================================================

/**
 * Update athlete details (difficulty, focus, notes)
 */
export const updateAthleteDetails = onCall(
  { region: config.region },
  async (request: CallableRequest<{
    athleteId: string;
    difficulty: string;
    skillFocus: string;
    notes: string;
  }>): Promise<FunctionResponse> => {
    const coachUid = requireAuth(request.auth);
    await requireRole(coachUid, ['coach', 'admin']);

    const { athleteId, difficulty, skillFocus, notes } = request.data;

    if (!athleteId) {
      throw new HttpsError('invalid-argument', 'athleteId is required');
    }

    const athleteRef = db.collection('athletes').doc(athleteId);
    const athleteDoc = await athleteRef.get();

    if (!athleteDoc.exists) {
      throw new HttpsError('not-found', 'Athlete not found');
    }

    const athleteData = athleteDoc.data();
    if (athleteData?.coachUid !== coachUid) {
      throw new HttpsError('permission-denied', 'You can only update your own athletes');
    }

    await athleteRef.update({
      difficulty,
      skill_focus: skillFocus,
      notes,
    });

    return { success: true, message: 'Athlete details updated' };
  }
);

/**
 * Add a rest day for an athlete
 */
export const addRestDay = onCall(
  { region: config.region },
  async (request: CallableRequest<{ athleteId: string }>): Promise<FunctionResponse> => {
    const coachUid = requireAuth(request.auth);
    await requireRole(coachUid, ['coach', 'admin']);

    const { athleteId } = request.data;

    if (!athleteId) {
      throw new HttpsError('invalid-argument', 'athleteId is required');
    }

    const athleteRef = db.collection('athletes').doc(athleteId);
    const athleteDoc = await athleteRef.get();

    if (!athleteDoc.exists) {
      throw new HttpsError('not-found', 'Athlete not found');
    }

    const athleteData = athleteDoc.data();
    if (athleteData?.coachUid !== coachUid) {
      throw new HttpsError('permission-denied', 'You can only update your own athletes');
    }

    await athleteRef.update({
      status: 'Rest Day (Completed)',
      progress: 1.0,
    });

    return { success: true, message: 'Rest day added' };
  }
);

/**
 * Update athlete profile (name, pin)
 */
export const updateAthleteProfile = onCall(
  { region: config.region },
  async (request: CallableRequest<{
    athleteId: string;
    newName?: string;
    newPin?: string;
  }>): Promise<FunctionResponse> => {
    requireAuth(request.auth);

    const { athleteId, newName, newPin } = request.data;

    if (!athleteId) {
      throw new HttpsError('invalid-argument', 'athleteId is required');
    }

    const updates: Record<string, string> = {};
    if (newName) updates.name = newName;
    if (newPin) updates.pin = newPin;

    if (Object.keys(updates).length === 0) {
      throw new HttpsError('invalid-argument', 'At least one field to update is required');
    }

    await db.collection('athletes').doc(athleteId).update(updates);

    return { success: true, message: 'Profile updated successfully' };
  }
);
