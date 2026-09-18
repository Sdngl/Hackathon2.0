import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Wraps FirebaseAuth and keeps a matching profile document in Firestore.
///
/// Firebase Auth and Firestore are separate products: creating an account does
/// NOT create a database row. The `users/{uid}` document below is written by
/// this class explicitly.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Live profile document for the signed-in user.
  Stream<Map<String, dynamic>?> profileStream(String uid) =>
      _users.doc(uid).snapshots().map((snap) => snap.data());

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Refresh the last-login stamp. merge:true so nothing else is wiped.
    await _users.doc(credential.user!.uid).set({
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return credential;
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;
    final name = displayName?.trim() ?? '';

    if (name.isNotEmpty) {
      await user.updateDisplayName(name);
      await user.reload();
    }

    // This is the write that actually puts the user in Firestore.
    await _users.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': name,
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<void> updateProfile(Map<String, dynamic> data) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user');
    return _users.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

  static String describeError(Object error) {
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
        default:
          return error.message ?? 'Authentication failed.';
      }
    }
    if (error is FirebaseException && error.plugin == 'cloud_firestore') {
      if (error.code == 'permission-denied') {
        return 'Signed in, but the database rejected the write. '
            'Check your Firestore security rules.';
      }
      return error.message ?? 'Database error.';
    }
    return 'Something went wrong. Please try again.';
  }
}