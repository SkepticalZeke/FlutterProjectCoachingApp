const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
const axios = require('axios');
const multer = require('multer');
const path = require('path');

// Initialize Firebase
admin.initializeApp();
const db = admin.firestore();
const storage = admin.storage();
const app = express();

// Configure multer for file uploads (store in memory)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB limit
  },
  fileFilter: (req, file, cb) => {
    // Accept only video files
    if (file.mimetype.startsWith('video/')) {
      cb(null, true);
    } else {
      cb(new Error('Only video files are allowed'), false);
    }
  }
});

// --- 1. CORS FIX ---
// This allows your Flutter app to talk to the server
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin']
}));
app.options('*', cors()); // Handle pre-flight checks

app.use(express.json());

// Firebase Web API Key - Get this from Firebase Console > Project Settings > General
const FIREBASE_WEB_API_KEY = 'AIzaSyB0cy2Ss1f5jSsvoSeTA8sXi-0jGP_oVK0';

// --- 2. AUTH MIDDLEWARE ---
const authenticate = async (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).send('Unauthorized: No token provided');
  }
  const token = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    res.status(401).send('Unauthorized: Invalid token');
  }
};

// ==========================================
// AUTH ENDPOINTS
// ==========================================

// Coach Registration
app.post('/auth/coach/register', async (req, res) => {
  const { email, password } = req.body;

  // Validate input
  if (!email || !password) {
    return res.status(400).send({ error: 'Email and password are required' });
  }

  if (password.length < 6) {
    return res.status(400).send({ error: 'Password must be at least 6 characters' });
  }

  try {
    // 1. Create Firebase Auth user using REST API
    const authResponse = await axios.post(
      `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FIREBASE_WEB_API_KEY}`,
      {
        email: email,
        password: password,
        returnSecureToken: true
      }
    );

    const { idToken, localId } = authResponse.data;

    // 2. Create coach document in Firestore
    await db.collection('coaches').doc(localId).set({
      uid: localId,
      email: email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 3. Return token and user info
    res.status(200).json({
      token: idToken,
      coachUid: localId,
      email: email,
      message: 'Coach registered successfully'
    });

  } catch (error) {
    console.error('Registration error:', error.response?.data || error.message);

    const errorMessage = error.response?.data?.error?.message || '';

    if (errorMessage.includes('EMAIL_EXISTS')) {
      return res.status(409).send({ error: 'An account with this email already exists' });
    }
    if (errorMessage.includes('INVALID_EMAIL')) {
      return res.status(400).send({ error: 'Invalid email address' });
    }
    if (errorMessage.includes('WEAK_PASSWORD')) {
      return res.status(400).send({ error: 'Password must be at least 6 characters' });
    }

    res.status(500).send({ error: 'Registration failed. Please try again.' });
  }
});

// Coach Login
app.post('/auth/coach/login', async (req, res) => {
  const { email, password } = req.body;

  // Validate input
  if (!email || !password) {
    return res.status(400).send({ error: 'Email and password are required' });
  }

  try {
    // 1. Sign in using Firebase Auth REST API
    const authResponse = await axios.post(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_WEB_API_KEY}`,
      {
        email: email,
        password: password,
        returnSecureToken: true
      }
    );

    const { idToken, localId } = authResponse.data;

    // 2. Verify coach exists in Firestore
    const coachDoc = await db.collection('coaches').doc(localId).get();

    if (!coachDoc.exists) {
      return res.status(404).send({ error: 'Coach profile not found. Please register first.' });
    }

    // 3. Return token and user info
    res.status(200).json({
      token: idToken,
      coachUid: localId,
      email: email,
      message: 'Login successful'
    });

  } catch (error) {
    console.error('Login error:', error.response?.data || error.message);

    const errorMessage = error.response?.data?.error?.message || '';

    if (errorMessage.includes('INVALID_LOGIN_CREDENTIALS') ||
        errorMessage.includes('INVALID_PASSWORD') ||
        errorMessage.includes('EMAIL_NOT_FOUND')) {
      return res.status(401).send({ error: 'Invalid email or password' });
    }
    if (errorMessage.includes('USER_DISABLED')) {
      return res.status(403).send({ error: 'This account has been disabled' });
    }
    if (errorMessage.includes('TOO_MANY_ATTEMPTS_TRY_LATER')) {
      return res.status(429).send({ error: 'Too many login attempts. Please try again later.' });
    }

    res.status(401).send({ error: 'Login failed. Please check your credentials.' });
  }
});

// =======================
// ROUTES (SAME AS BEFORE)
// =======================
// ==========================================
// 1. COACH & ATHLETE MANAGEMENT
// ==========================================

// Create Coach & First Athlete (Batch Write)
app.post('/api/coach/setup', authenticate, async (req, res) => {
  const { coachUid, coachEmail, athleteName, athletePin } = req.body;

  // Security check: Ensure the caller is setting up their own account
  if (req.user.uid !== coachUid) return res.status(403).send('Forbidden');

  try {
    const batch = db.batch();

    const coachRef = db.collection('coaches').doc(coachUid);
    batch.set(coachRef, {
      uid: coachUid,
      email: coachEmail,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true }); // Use merge to avoid overwriting existing data

    const athleteRef = db.collection('athletes').doc();
    batch.set(athleteRef, {
      name: athleteName,
      pin: athletePin,
      coachUid: coachUid,
      level: 1,
      streak: 0,
      progress: 0.0,
      status: 'Training Not Started',
      skill_focus: 'General',
      difficulty: 'Easy',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      stars: 0,
      unlockedItems: [101, 201, 301],
      selectedOutfit: 101,
      selectedShoe: 201,
      selectedEquipment: 301,
      currentXp: 0.0,
      requiredXp: 1000.0,
      totalXp: 0,
      skillProgress: { General: 0.0, Agility: 0.0, Strength: 0.0, Cardio: 0.0 },
    });

    await batch.commit();
    res.status(200).send({ message: 'Setup complete', athleteId: athleteRef.id });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Add New Athlete (From Coach Dashboard)
app.post('/api/coach/add-athlete', authenticate, async (req, res) => {
  const { coachUid, name, pin } = req.body;

  try {
    const athleteRef = db.collection('athletes').doc();
    await athleteRef.set({
      name: name,
      pin: pin,
      coachUid: coachUid,
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
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      skillProgress: { General: 0.0, Agility: 0.0, Strength: 0.0, Cardio: 0.0 },
    });
    res.status(200).send({ message: 'Athlete added', id: athleteRef.id });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Register New Athlete (Public/Self-Serve via Coach Email)
// Note: This is public because a new user doesn't have a token yet.
app.post('/api/athlete/register', async (req, res) => {
  const { name, pin, coachEmail } = req.body;

  try {
    // 1. Find Coach by Email
    const coachSnapshot = await db.collection('coaches')
      .where('email', '==', coachEmail)
      .limit(1)
      .get();

    if (coachSnapshot.empty) {
      return res.status(404).send({ error: `Coach with email ${coachEmail} not found` });
    }

    const coachUid = coachSnapshot.docs[0].id;

    // 2. Create Athlete
    const athleteRef = db.collection('athletes').doc();
    const newAthleteData = {
      name: name,
      pin: pin,
      coachUid: coachUid,
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
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      skillProgress: { General: 0.0, Agility: 0.0, Strength: 0.0, Cardio: 0.0 },
    };

    await athleteRef.set(newAthleteData);

    // Return data including ID so Flutter can build the object
    res.status(200).json({ id: athleteRef.id, ...newAthleteData });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// ==========================================
// 2. DRILL & TRAINING LOGIC
// ==========================================

// Upload Video (For Drills and Submissions)
app.post('/api/upload/video', authenticate, upload.single('video'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).send({ error: 'No video file provided' });
    }

    const coachUid = req.user.uid;
    const { uploadType } = req.body; // 'coach_drill' or 'athlete_submission'
    const athleteId = req.body.athleteId; // Only for athlete submissions

    // Generate unique filename
    const timestamp = Date.now();
    const extension = path.extname(req.file.originalname) || '.mp4';
    const filename = `${coachUid}_${timestamp}${extension}`;

    // Determine storage path based on upload type
    let storagePath;
    if (uploadType === 'coach_drill') {
      storagePath = `coach_drills/${coachUid}/${filename}`;
    } else if (uploadType === 'athlete_submission' && athleteId) {
      storagePath = `athlete_submissions/${athleteId}/${filename}`;
    } else {
      return res.status(400).send({ error: 'Invalid upload type or missing athleteId' });
    }

    // Get a reference to the storage bucket
    const bucket = storage.bucket();
    const file = bucket.file(storagePath);

    // Create a write stream and upload the file
    await file.save(req.file.buffer, {
      metadata: {
        contentType: req.file.mimetype,
      },
      resumable: false,
    });

    // Make the file publicly accessible and get the download URL
    await file.makePublic();
    const downloadUrl = `https://storage.googleapis.com/${bucket.name}/${storagePath}`;

    res.status(200).send({
      message: 'Video uploaded successfully',
      downloadUrl: downloadUrl
    });

  } catch (e) {
    console.error('Video upload error:', e);
    res.status(500).send({ error: e.message || 'Failed to upload video' });
  }
});

// Create Coach Drill
app.post('/api/drill/create', authenticate, async (req, res) => {
  const { name, goal, skillFocus, xp, videoUrl } = req.body;
  const coachUid = req.user.uid;

  try {
    await db.collection('coaches').doc(coachUid).collection('drills').add({
      name,
      goal,
      skillFocus,
      xp,
      videoUrl,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    res.status(200).send({ message: 'Drill created' });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Assign Drill to Athlete
app.post('/api/drill/assign', authenticate, async (req, res) => {
  const { athleteId, drillData } = req.body;
  const coachUid = req.user.uid;

  try {
    await db.collection('athletes').doc(athleteId).collection('todayDrills').add({
      name: drillData.name,
      goal: drillData.goal,
      skillFocus: drillData.skillFocus,
      xp: drillData.xp,
      videoUrl: drillData.videoUrl,
      coachDrillId: drillData.id,
      coachUid: coachUid,
      athleteId: athleteId,
      assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      completed: false,
      iconData: 0xe722,
    });
    res.status(200).send({ message: 'Drill assigned' });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Complete Drill (Logic heavy: XP, Stats, Logging)
app.post('/api/drill/complete', async (req, res) => {
  const { athleteId, drillId, drillName, xpGained, coachVideoUrl, athleteVideoUrl, coachUid } = req.body;

  try {
    await db.runTransaction(async (t) => {
      const athleteRef = db.collection('athletes').doc(athleteId);
      const doc = await t.get(athleteRef);
      if (!doc.exists) throw new Error('Athlete not found');

      const data = doc.data();
      const skillFocus = data.skill_focus || 'General';
      const skillProgressField = `skillProgress.${skillFocus}`;

      // 1. Update Drill Status
      const drillRef = athleteRef.collection('todayDrills').doc(drillId);
      t.update(drillRef, {
        completed: true,
        status: 'Pending Review',
        athleteVideoUrl: athleteVideoUrl
      });

      // 2. Create Log
      const logRef = athleteRef.collection('logs').doc();
      t.set(logRef, {
        drill: drillName,
        status: 'Pending Review',
        xp: xpGained,
        date: admin.firestore.FieldValue.serverTimestamp(),
        skillFocus: skillFocus,
        coachVideoUrl: coachVideoUrl,
        athleteVideoUrl: athleteVideoUrl,
        coachUid: coachUid,
        athleteId: athleteId
      });

      // 3. Update Athlete Stats (XP)
      t.update(athleteRef, {
        totalXp: admin.firestore.FieldValue.increment(xpGained),
        currentXp: admin.firestore.FieldValue.increment(xpGained),
        [skillProgressField]: admin.firestore.FieldValue.increment(xpGained),
      });
    });

    res.status(200).send({ message: 'Drill completed' });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Submit Review (Coach Grading)
app.post('/api/review/submit', authenticate, async (req, res) => {
  const { athleteId, logId, isApproved, feedback } = req.body;

  try {
    const newStatus = isApproved ? 'Approved' : 'Needs Work';
    const bonusXp = isApproved ? 25 : 0;
    const bonusStars = isApproved ? 10 : 0;

    const batch = db.batch();
    const logRef = db.collection('athletes').doc(athleteId).collection('logs').doc(logId);
    const athleteRef = db.collection('athletes').doc(athleteId);

    batch.update(logRef, {
      status: newStatus,
      feedback: feedback
    });

    if (isApproved) {
      batch.update(athleteRef, {
        totalXp: admin.firestore.FieldValue.increment(bonusXp),
        currentXp: admin.firestore.FieldValue.increment(bonusXp),
        stars: admin.firestore.FieldValue.increment(bonusStars)
      });
    }

    await batch.commit();
    res.status(200).send({ message: 'Review submitted' });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// ==========================================
// 3. STORE & PROFILE
// ==========================================

// Buy Item
app.post('/api/store/buy', async (req, res) => {
  const { athleteId, itemId, itemCost } = req.body;

  try {
    await db.runTransaction(async (t) => {
      const athleteRef = db.collection('athletes').doc(athleteId);
      const doc = await t.get(athleteRef);
      const currentStars = doc.data().stars || 0;

      if (currentStars < itemCost) {
        throw new Error(`Need ${itemCost - currentStars} more Stars to unlock!`);
      }

      t.update(athleteRef, {
        stars: admin.firestore.FieldValue.increment(-itemCost),
        unlockedItems: admin.firestore.FieldValue.arrayUnion(itemId)
      });
    });

    res.status(200).send({ message: 'Item purchased' });
  } catch (e) {
    res.status(400).send({ error: e.message });
  }
});

// Equip Item
app.post('/api/athlete/equip', async (req, res) => {
  const { athleteId, field, itemId } = req.body;
  try {
    // field will be 'selectedOutfit', 'selectedShoe', etc.
    await db.collection('athletes').doc(athleteId).update({
      [field]: itemId
    });
    res.status(200).send({ message: 'Item equipped' });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Update Profile (Name/Pin)
app.post('/api/athlete/update-profile', async (req, res) => {
  const { athleteId, newName, newPin } = req.body;

  const updates = {};
  if (newName) updates.name = newName;
  if (newPin) updates.pin = newPin;

  try {
    if (Object.keys(updates).length > 0) {
      await db.collection('athletes').doc(athleteId).update(updates);
    }
    res.status(200).send({ message: 'Profile updated' });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Update Details (Routine/Difficulty)
app.post('/api/athlete/update-details', async (req, res) => {
  const { athleteId, difficulty, skillFocus, notes } = req.body;
  try {
    await db.collection('athletes').doc(athleteId).update({
      difficulty: difficulty,
      skill_focus: skillFocus,
      notes: notes
    });
    res.status(200).send({ message: 'Details updated' });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Add Rest Day
app.post('/api/athlete/rest-day', async (req, res) => {
  const { athleteId } = req.body;
  try {
    await db.collection('athletes').doc(athleteId).update({
      status: 'Rest Day (Completed)',
      progress: 1.0,
    });
    res.status(200).send({ message: 'Rest day recorded' });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Athlete Login
app.post('/api/athlete/login', async (req, res) => {
  const { name, pin } = req.body;

  try {
    // 1. Search for athlete by Name
    const snapshot = await db.collection('athletes')
      .where('name', '==', name)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return res.status(404).send({ error: 'Athlete not found' });
    }

    const doc = snapshot.docs[0];
    const data = doc.data();

    // 2. Check PIN (Convert both to strings to be safe)
    if (String(data.pin) !== String(pin)) {
      return res.status(401).send({ error: 'Incorrect PIN' });
    }

    // 3. Success: Return the data
    res.status(200).send({
      message: 'Login successful',
      id: doc.id,
      ...data
    });

  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Get Single Athlete
app.post('/api/athlete/get', async (req, res) => {
  const { athleteId } = req.body;
  try {
    const doc = await db.collection('athletes').doc(athleteId).get();
    if (!doc.exists) return res.status(404).send({});
    res.status(200).send({ id: doc.id, ...doc.data() });
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Get Today's Drills
app.post('/api/athlete/get-drills', async (req, res) => {
  const { athleteId } = req.body;
  try {
    const snapshot = await db.collection('athletes').doc(athleteId).collection('todayDrills').get();
    const drills = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).send(drills);
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Get Logs
app.post('/api/athlete/get-logs', async (req, res) => {
  const { athleteId } = req.body;
  try {
    const snapshot = await db.collection('athletes').doc(athleteId).collection('logs')
      .orderBy('date', 'desc').limit(30).get();
    const logs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).send(logs);
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Get Coach's Athletes
app.post('/api/coach/get-athletes', authenticate, async (req, res) => {
  const { coachUid } = req.body;
  try {
    const snapshot = await db.collection('athletes').where('coachUid', '==', coachUid).get();
    const athletes = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).send(athletes);
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Get Coach's Drills
app.post('/api/coach/get-drills', authenticate, async (req, res) => {
  const coachUid = req.user.uid;
  try {
    const snapshot = await db.collection('coaches').doc(coachUid).collection('drills').orderBy('createdAt', 'desc').get();
    const drills = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).send(drills);
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Get Pending Reviews
app.post('/api/coach/get-pending', authenticate, async (req, res) => {
  const coachUid = req.user.uid;
  try {
    const snapshot = await db.collectionGroup('logs')
      .where('coachUid', '==', coachUid).where('status', '==', 'Pending Review').get();
    const submissions = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).send(submissions);
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// Get Coach Drills (For Athlete View)
app.post('/api/athlete/get-coach-drills', async (req, res) => {
  const { coachUid } = req.body;
  try {
    const snapshot = await db.collection('coaches')
      .doc(coachUid)
      .collection('drills')
      .orderBy('createdAt', 'desc')
      .get();

    const drills = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).send(drills);
  } catch (e) {
    res.status(500).send({ error: e.message });
  }
});

// ============================================
// --- EXPORT AND START SERVER ---
// ============================================

// Export the app as "server" to satisfy Cloud Run requirements
exports.server = app;

// Only start listening manually if we are NOT in "Function Mode"
if (require.main === module) {
  const PORT = process.env.PORT || 8080;
  app.listen(PORT, () => {
    console.log(`✅ Server listening on port ${PORT}...`);
  });
}
