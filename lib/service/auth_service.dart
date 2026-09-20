import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _googleInitialized = false;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Stream<Map<String, dynamic>?> profileStream(
      String uid,
      ) {
    return _users
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  // =========================================================
  // EMAIL LOGIN
  // =========================================================

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential =
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user != null) {
      await _users.doc(user.uid).set(
        {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? '',
          'photoUrl': user.photoURL,
          'provider': 'password',
          'lastLoginAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    return credential;
  }

  // =========================================================
  // EMAIL SIGNUP
  // =========================================================

  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential =
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    final name = displayName?.trim() ?? '';

    if (name.isNotEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
    }

    await _users.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': name,
      'photoUrl': user.photoURL,
      'provider': 'password',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  // =========================================================
  // GOOGLE INITIALIZATION
  // =========================================================

  Future<void> _initializeGoogleSignIn() async {
    if (_googleInitialized) {
      return;
    }

    await _googleSignIn.initialize();

    _googleInitialized = true;
  }

  // =========================================================
  // GOOGLE LOGIN / SIGNUP
  //
  // Same function for both.
  //
  // Existing account -> login
  // New account      -> Firebase creates account
  // =========================================================

  Future<UserCredential> signInWithGoogle() async {
    await _initializeGoogleSignIn();

    final GoogleSignInAccount googleUser =
    await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-id-token-missing',
        message:
        'Google authentication did not return an ID token.',
      );
    }

    final OAuthCredential credential =
    GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final UserCredential userCredential =
    await _auth.signInWithCredential(
      credential,
    );

    final User? user = userCredential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'google-user-missing',
        message:
        'Google authentication completed but no Firebase user was returned.',
      );
    }

    await _saveGoogleUser(
      user: user,
      isNewUser:
      userCredential.additionalUserInfo?.isNewUser ??
          false,
    );

    return userCredential;
  }

  // =========================================================
  // SAVE GOOGLE USER TO FIRESTORE
  // =========================================================

  Future<void> _saveGoogleUser({
    required User user,
    required bool isNewUser,
  }) async {
    final DocumentReference<Map<String, dynamic>>
    userRef = _users.doc(user.uid);

    final snapshot = await userRef.get();

    final Map<String, dynamic> data = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoUrl': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'provider': 'google',
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    // Only create createdAt the first time.
    if (!snapshot.exists || isNewUser) {
      data['createdAt'] =
          FieldValue.serverTimestamp();
    }

    await userRef.set(
      data,
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // PROFILE UPDATE
  // =========================================================

  Future<void> updateProfile(
      Map<String, dynamic> data,
      ) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      throw StateError('No signed-in user');
    }

    return _users.doc(uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // RESET PASSWORD
  // =========================================================

  Future<void> sendPasswordReset(
      String email,
      ) {
    return _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // =========================================================
  // SIGN OUT
  // =========================================================

  Future<void> signOut() async {
    try {
      await _initializeGoogleSignIn();
      await _googleSignIn.signOut();
    } catch (_) {
      // User may have logged in using email/password.
    }

    await _auth.signOut();
  }

  // =========================================================
  // ERROR MESSAGES
  // =========================================================

  static String describeError(
      Object error,
      ) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address does not look right.';

        case 'user-disabled':
          return 'This account has been disabled.';

        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';

        case 'email-already-in-use':
          return 'An account already exists for that email.';

        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';

        case 'too-many-requests':
          return 'Too many attempts. Try again in a moment.';

        case 'network-request-failed':
          return 'Network error. Check your connection.';

        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using another sign-in method.';

        case 'google-id-token-missing':
          return 'Google Sign-In could not be completed.';

        default:
          return error.message ??
              'Authentication failed.';
      }
    }

    if (error is GoogleSignInException) {
      return 'Google Sign-In was cancelled or could not be completed.';
    }

    if (error is FirebaseException &&
        error.plugin == 'cloud_firestore') {
      if (error.code == 'permission-denied') {
        return 'Signed in, but Firestore rejected the profile write. Check your Firestore rules.';
      }

      return error.message ??
          'Database error.';
    }

    return 'Something went wrong. Please try again.';
  }
}