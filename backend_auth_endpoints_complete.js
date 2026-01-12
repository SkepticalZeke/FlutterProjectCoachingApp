// COMPLETE AUTH ENDPOINTS FOR YOUR server.js
// Add these endpoints to your server.js file
// Place them BEFORE the "// 1. COACH & ATHLETE MANAGEMENT" section

// You'll need to add this at the top of server.js:
// const axios = require('axios');
// And add to package.json dependencies: "axios": "^1.6.0"

// ==========================================
// AUTH ENDPOINTS (COMPLETE SOLUTION)
// ==========================================

// Get your Firebase Web API Key from Firebase Console > Project Settings > General
const FIREBASE_WEB_API_KEY = 'YOUR_FIREBASE_WEB_API_KEY_HERE'; // Replace this!

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
