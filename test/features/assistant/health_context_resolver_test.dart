import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hackthon2/features/assistant/models/context_resolution.dart';
import 'package:hackthon2/features/assistant/services/health_context_resolver.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late HealthContextResolver resolver;

  setUp(() {
    firestore = FakeFirebaseFirestore();

    auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'user_123',
        email: 'test@example.com',
      ),
    );

    resolver = HealthContextResolver(
      firestore: firestore,
      auth: auth,
    );
  });

  test('general question returns general', () async {
    final result = await resolver.resolve(
      message: 'What foods contain vitamin D?',
    );

    expect(
      result.status,
      ContextResolutionStatus.general,
    );
  });

  test('missing report returns missing', () async {
    final result = await resolver.resolve(
      message: 'Explain my report',
    );

    expect(
      result.status,
      ContextResolutionStatus.missing,
    );

    expect(
      result.contextType,
      HealthContextType.report,
    );
  });

  test('one saved report returns ready', () async {
    await firestore
        .collection('users')
        .doc('user_123')
        .collection('reports')
        .doc('report_1')
        .set({
      'title': 'Blood Test',
      'report_date': '2026-09-18',
    });

    final result = await resolver.resolve(
      message: 'Explain my report',
    );

    expect(
      result.status,
      ContextResolutionStatus.ready,
    );

    expect(
      result.selected?.id,
      'report_1',
    );
  });

  test('multiple reports returns needsSelection', () async {
    await firestore
        .collection('users')
        .doc('user_123')
        .collection('reports')
        .doc('report_1')
        .set({
      'title': 'Blood Test',
      'report_date': '2026-09-10',
    });

    await firestore
        .collection('users')
        .doc('user_123')
        .collection('reports')
        .doc('report_2')
        .set({
      'title': 'Liver Report',
      'report_date': '2026-09-15',
    });

    final result = await resolver.resolve(
      message: 'Explain my report',
    );

    expect(
      result.status,
      ContextResolutionStatus.needsSelection,
    );

    expect(
      result.candidates.length,
      2,
    );
  });

  test('latest report automatically uses newest report', () async {
    await firestore
        .collection('users')
        .doc('user_123')
        .collection('reports')
        .doc('report_old')
        .set({
      'title': 'Old Report',
      'report_date': '2026-09-10',
    });

    await firestore
        .collection('users')
        .doc('user_123')
        .collection('reports')
        .doc('report_new')
        .set({
      'title': 'New Report',
      'report_date': '2026-09-18',
    });

    final result = await resolver.resolve(
      message: 'Explain my latest report',
    );

    expect(
      result.status,
      ContextResolutionStatus.ready,
    );

    expect(
      result.selected?.id,
      'report_new',
    );
  });

  test('base64 image data is removed', () async {
    await firestore
        .collection('users')
        .doc('user_123')
        .collection('reports')
        .doc('report_1')
        .set({
      'title': 'Blood Test',
      'imageBase64': 'large-image-data',
    });

    final result = await resolver.resolve(
      message: 'Explain my report',
    );

    expect(
      result.selected!.data.containsKey('imageBase64'),
      false,
    );
  });
}
