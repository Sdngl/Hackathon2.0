import 'package:firebase_auth/firebase_auth.dart';

Future<void>getFirebaseToken() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print('No Firebase user is logged in');
    return;
  }

  final token = await user.getIdToken(true);

  print('Firebase ID token: $token');
}