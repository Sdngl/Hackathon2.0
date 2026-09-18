import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthScanRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HealthScanRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<String> createPendingScan({
    required String type,
    required String imageBase64,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final collectionName = _collectionForType(type);

    const maxBase64Bytes = 700 * 1024;
    final imageSizeBytes = imageBase64.length;

    if (imageSizeBytes > maxBase64Bytes) {
      throw Exception(
        'Compressed image is still too large. Please use a smaller image.',
      );
    }

    final document = _firestore
        .collection('users')
        .doc(user.uid)
        .collection(collectionName)
        .doc();

    await document.set({
      'type': type,
      'status': 'pending',
      'imageBase64': imageBase64,
      'imageMimeType': 'image/jpeg',
      'analysis': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  String _collectionForType(String type) {
    switch (type) {
      case 'report':
        return 'reports';
      case 'medicine':
        return 'medicines';
      case 'meal':
        return 'meals';
      default:
        throw Exception('Unsupported scan type: $type');
    }
  }
}
