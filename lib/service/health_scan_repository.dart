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
    final user = _requireUser();
    final normalizedType = type.trim().toLowerCase();
    final collectionName = _collectionForType(normalizedType);
    _validateImageSize(imageBase64);

    final document = _firestore
        .collection('users')
        .doc(user.uid)
        .collection(collectionName)
        .doc();

    await document.set({
      'type': normalizedType,
      'status': 'pending',
      'imageBase64': imageBase64,
      'imageMimeType': 'image/jpeg',
      'analysis': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<String> saveCompletedScan({
    required String type,
    required String imageBase64,
    required Map<String, dynamic> analysis,
  }) async {
    final user = _requireUser();
    final normalizedType = type.trim().toLowerCase();
    final collectionName = _collectionForType(normalizedType);
    _validateImageSize(imageBase64);

    final document = _firestore
        .collection('users')
        .doc(user.uid)
        .collection(collectionName)
        .doc();

    await document.set({
      'type': normalizedType,
      'status': 'completed',
      'imageBase64': imageBase64,
      'imageMimeType': 'image/jpeg',
      'analysis': analysis,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<void> completeScan({
    required String type,
    required String recordId,
    required Map<String, dynamic> analysis,
  }) async {
    final user = _requireUser();
    final collectionName = _collectionForType(type.trim().toLowerCase());

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection(collectionName)
        .doc(recordId)
        .update({
      'status': 'completed',
      'analysis': analysis,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteScan({
    required String type,
    required String recordId,
  }) async {
    final user = _requireUser();
    final collectionName = _collectionForType(type.trim().toLowerCase());

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection(collectionName)
        .doc(recordId)
        .delete();
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User is not logged in.');
    return user;
  }

  void _validateImageSize(String imageBase64) {
    const maxBase64Bytes = 700 * 1024;
    if (imageBase64.length > maxBase64Bytes) {
      throw Exception(
        'Compressed image is still too large. Please use a smaller image.',
      );
    }
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
