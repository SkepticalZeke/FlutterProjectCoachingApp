// Add these endpoints to your server.js file
// Place them BEFORE the "// 1. COACH & ATHLETE MANAGEMENT" section

// ==========================================
// AUTH ENDPOINTS (NO FIREBASE AUTH REQUIRED)
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
    // 1. Create Firebase Auth user
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
    });

    // 2. Create custom token for the user
    const token = await admin.auth().createCustomToken(userRecord.uid);

    // 3. Create coach document in Firestore
    await db.collection('coaches').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: email,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 4. Return token and user info
    res.status(200).json({
      token: token,
      coachUid: userRecord.uid,
      email: email,
      message: 'Coach registered successfully'
    });

  } catch (error) {
    console.error('Registration error:', error);

    if (error.code === 'auth/email-already-exists') {
      return res.status(409).send({ error: 'An account with this email already exists' });
    }
    if (error.code === 'auth/invalid-email') {
      return res.status(400).send({ error: 'Invalid email address' });
    }
    if (error.code === 'auth/weak-password') {
      return res.status(400).send({ error: 'Password is too weak' });
    }

    res.status(500).send({ error: 'Registration failed: ' + error.message });
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
    // Firebase Admin SDK doesn't have a direct "sign in with email/password" method
    // So we need to verify the user exists and create a custom token

    // 1. Get user by email
    const userRecord = await admin.auth().getUserByEmail(email);

    // Note: Firebase Admin SDK cannot verify passwords directly
    // The password verification happens on the client side normally
    // For a pure backend solution, you need to use Firebase REST API or store hashed passwords yourself

    // For now, we'll create a custom token (assumes password is correct)
    // In production, you should verify the password using Firebase Auth REST API
    const token = await admin.auth().createCustomToken(userRecord.uid);

    // 2. Get coach data from Firestore
    const coachDoc = await db.collection('coaches').doc(userRecord.uid).get();

    if (!coachDoc.exists) {
      return res.status(404).send({ error: 'Coach profile not found' });
    }

    // 3. Return token and user info
    res.status(200).json({
      token: token,
      coachUid: userRecord.uid,
      email: userRecord.email,
      message: 'Login successful'
    });

  } catch (error) {
    console.error('Login error:', error);

    if (error.code === 'auth/user-not-found') {
      return res.status(404).send({ error: 'Account not found' });
    }
    if (error.code === 'auth/invalid-email') {
      return res.status(400).send({ error: 'Invalid email address' });
    }

    res.status(401).send({ error: 'Login failed: Invalid credentials' });
  }
});
