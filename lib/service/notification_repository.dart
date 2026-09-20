import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/assistant/models/app_notification.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>?
  _collection() {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications');
  }

  Stream<List<AppNotification>>
  watchNotifications() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(
        const <AppNotification>[],
      );
    }

    late StreamController<
        List<AppNotification>> controller;

    var personal =
    const <AppNotification>[];
    var content =
    const <AppNotification>[];
    var announcements =
    const <AppNotification>[];
    var userData =
    <String, dynamic>{};

    final subscriptions =
    <StreamSubscription<dynamic>>[];

    void emit() {
      final isPlus =
      _isPlusUser(userData);

      final visibleContent = content
          .where(
            (item) => _audienceMatches(
          item.audience,
          isPlus: isPlus,
        ),
      )
          .toList(growable: false);

      final visibleAnnouncements =
      announcements
          .where(
            (item) => _audienceMatches(
          item.audience,
          isPlus: isPlus,
        ),
      )
          .toList(growable: false);

      final merged = <AppNotification>[
        ...personal,
        ...visibleContent,
        ...visibleAnnouncements,
      ];

      merged.sort(
            (a, b) {
          final aDate = a.createdAt;
          final bDate = b.createdAt;

          if (aDate == null &&
              bDate == null) {
            return 0;
          }

          if (aDate == null) {
            return 1;
          }

          if (bDate == null) {
            return -1;
          }

          return bDate.compareTo(aDate);
        },
      );

      if (!controller.isClosed) {
        controller.add(
          List<AppNotification>.unmodifiable(
            merged,
          ),
        );
      }
    }

    controller =
        StreamController<
            List<AppNotification>>(
          onListen: () {
            subscriptions.add(
              _firestore
                  .collection('users')
                  .doc(user.uid)
                  .snapshots()
                  .listen(
                    (snapshot) {
                  userData =
                      snapshot.data() ??
                          <String, dynamic>{};
                  emit();
                },
                onError: controller.addError,
              ),
            );

            subscriptions.add(
              _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy(
                'createdAt',
                descending: true,
              )
                  .snapshots()
                  .listen(
                    (snapshot) {
                  personal = snapshot.docs
                      .map(
                    AppNotification
                        .fromFirestore,
                  )
                      .toList(
                    growable: false,
                  );

                  emit();
                },
                onError: controller.addError,
              ),
            );

            subscriptions.add(
              _firestore
                  .collection('content')
                  .where(
                'published',
                isEqualTo: true,
              )
                  .snapshots()
                  .listen(
                    (snapshot) {
                  content = snapshot.docs.map(
                        (document) {
                      final data = document.data();

                      return AppNotification.fromMap(
                        id:
                        'content_${document.id}',
                        data: {
                          ...data,
                          'type': 'content',
                          'message':
                          data['body'],
                          'isRead': true,
                          'referenceId':
                          document.id,
                          'action':
                          'open_content',
                          'sourceCollection':
                          'content',
                        },
                      );
                    },
                  ).toList(
                    growable: false,
                  );

                  emit();
                },
                onError: controller.addError,
              ),
            );

            subscriptions.add(
              _firestore
                  .collection(
                'announcements',
              )
                  .snapshots()
                  .listen(
                    (snapshot) {
                  announcements =
                      snapshot.docs.map(
                            (document) {
                          final data =
                          document.data();

                          return AppNotification.fromMap(
                            id:
                            'announcement_${document.id}',
                            data: {
                              ...data,
                              'type':
                              'announcement',
                              'isRead': true,
                              'referenceId':
                              document.id,
                              'action':
                              'open_announcement',
                              'sourceCollection':
                              'announcements',
                            },
                          );
                        },
                      ).toList(
                        growable: false,
                      );

                  emit();
                },
                onError: controller.addError,
              ),
            );

            // Watch appointment documents so a doctor/admin status change
            // becomes a user notification while SEVA is open.
            subscriptions.add(
              _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('appointments')
                  .snapshots()
                  .listen(
                    (snapshot) async {
                  try {
                    await _syncAppointmentStatusChanges(
                      snapshot,
                    );
                  } catch (_) {
                    // Notification syncing must not break the main stream.
                  }
                },
              ),
            );
          },
          onCancel: () async {
            for (final subscription
            in subscriptions) {
              await subscription.cancel();
            }
          },
        );

    return controller.stream;
  }

  Stream<int> watchUnreadCount() {
    return watchNotifications().map(
          (items) => items
          .where(
            (item) =>
        !item.isRead &&
            item.type !=
                AppNotificationType
                    .content &&
            item.type !=
                AppNotificationType
                    .announcement,
      )
          .length,
    );
  }

  Future<String> createNotification({
    required String type,
    required String title,
    required String message,
    String? referenceId,
    String? action,
    String? deterministicId,
  }) async {
    final collection = _collection();

    if (collection == null) {
      throw Exception(
        'User is not logged in.',
      );
    }

    final document =
    deterministicId == null
        ? collection.doc()
        : collection.doc(
      deterministicId,
    );

    if (deterministicId != null) {
      final existing =
      await document.get();

      if (existing.exists) {
        return document.id;
      }
    }

    await document.set({
      'type': type,
      'title': title,
      'message': message,
      'isRead': false,
      'createdAt':
      FieldValue.serverTimestamp(),
      'referenceId': referenceId,
      'action': action,
    });

    return document.id;
  }

  Future<void> markRead(
      String id,
      ) async {
    // Content and announcements are read directly
    // from global collections, not from the
    // user's notification subcollection.
    if (id.startsWith('content_') ||
        id.startsWith(
          'announcement_',
        )) {
      return;
    }

    final collection = _collection();

    if (collection == null) {
      return;
    }

    await collection
        .doc(id)
        .update({
      'isRead': true,
    });
  }

  Future<void> markAllRead() async {
    final collection = _collection();

    if (collection == null) {
      return;
    }

    final unread =
    await collection
        .where(
      'isRead',
      isEqualTo: false,
    )
        .get();

    if (unread.docs.isEmpty) {
      return;
    }

    final batch =
    _firestore.batch();

    for (final doc in unread.docs) {
      batch.update(
        doc.reference,
        {
          'isRead': true,
        },
      );
    }

    await batch.commit();
  }

  Future<void>
  createAnalysisReadyNotification({
    required String type,
    required String recordId,
  }) async {
    final normalized =
    type.trim().toLowerCase();

    switch (normalized) {
      case 'medicine':
        await createNotification(
          type: 'medicine',
          title:
          'Medicine analysis ready',
          message:
          'Your medicine analysis is ready to review.',
          referenceId: recordId,
          action: 'open_analysis',
          deterministicId:
          'analysis_medicine_$recordId',
        );
        return;

      case 'report':
        await createNotification(
          type: 'report',
          title:
          'Report analysis ready',
          message:
          'Your report analysis is ready to review.',
          referenceId: recordId,
          action: 'open_analysis',
          deterministicId:
          'analysis_report_$recordId',
        );
        return;

      case 'meal':
        await createNotification(
          type: 'meal',
          title:
          'Meal analysis ready',
          message:
          'Your meal analysis is ready to review.',
          referenceId: recordId,
          action: 'open_analysis',
          deterministicId:
          'analysis_meal_$recordId',
        );
        return;
    }
  }

  Future<void> createAppointmentBookedNotification({
    required String appointmentId,
    required Map<String, dynamic> appointment,
  }) async {
    final doctorName =
        _cleanText(
          appointment['doctorName'],
        ) ??
            'your doctor';

    final consultationType =
    _cleanText(
      appointment['consultationType'],
    )?.toLowerCase();

    final appointmentDate =
    _cleanText(
      appointment['appointmentDate'],
    );

    final appointmentTime =
    _cleanText(
      appointment['appointmentTime'],
    );

    final parts = <String>[
      if (consultationType == 'video')
        'Video consultation',
      if (consultationType == 'clinic')
        'In-clinic consultation',
      'with $doctorName',
      if (appointmentDate != null)
        appointmentDate,
      if (appointmentTime != null)
        appointmentTime,
    ];

    await createNotification(
      type: 'appointment',
      title: 'Appointment booked',
      message: parts.join(' • '),
      referenceId: appointmentId,
      action: 'appointment_update',
      deterministicId:
      'appointment_booked_$appointmentId',
    );
  }

  Future<void> createSubscriptionActivatedNotification({
    required String planTitle,
    required DateTime startedAt,
    DateTime? expiresAt,
  }) async {
    final message = expiresAt == null
        ? '$planTitle is now active.'
        : '$planTitle is now active until ${_shortDate(expiresAt)}.';

    await createNotification(
      type: 'general',
      title: 'SEVA Premium activated',
      message: message,
      action: 'subscription_activated',
      deterministicId:
      'subscription_${startedAt.millisecondsSinceEpoch}',
    );
  }

  Future<void> _syncAppointmentStatusChanges(
      QuerySnapshot<Map<String, dynamic>> snapshot,
      ) async {
    for (final document in snapshot.docs) {
      final data = document.data();

      final currentStatus =
      _cleanText(
        data['status'],
      )?.toLowerCase();

      if (currentStatus == null) {
        continue;
      }

      final lastNotifiedStatus =
      _cleanText(
        data['lastNotifiedStatus'],
      )?.toLowerCase();

      // Existing appointments may pre-date this feature. Establish their
      // current status as the baseline so old records do not spam users.
      if (lastNotifiedStatus == null) {
        await document.reference.set(
          {
            'lastNotifiedStatus':
            currentStatus,
          },
          SetOptions(
            merge: true,
          ),
        );
        continue;
      }

      if (lastNotifiedStatus ==
          currentStatus) {
        continue;
      }

      final doctorName =
      _cleanText(
        data['doctorName'],
      );

      final statusMessage =
      _appointmentStatusMessage(
        status: currentStatus,
        doctorName: doctorName,
      );

      await createNotification(
        type: 'appointment',
        title: statusMessage.$1,
        message: statusMessage.$2,
        referenceId: document.id,
        action: 'appointment_update',
        deterministicId:
        'appointment_status_${document.id}_$currentStatus',
      );

      await document.reference.set(
        {
          'lastNotifiedStatus':
          currentStatus,
        },
        SetOptions(
          merge: true,
        ),
      );
    }
  }

  (String, String) _appointmentStatusMessage({
    required String status,
    String? doctorName,
  }) {
    final doctor =
    doctorName == null
        ? ''
        : ' with $doctorName';

    switch (status) {
      case 'confirmed':
        return (
        'Appointment confirmed',
        'Your appointment$doctor has been confirmed.',
        );

      case 'cancelled':
      case 'canceled':
        return (
        'Appointment cancelled',
        'Your appointment$doctor has been cancelled.',
        );

      case 'completed':
        return (
        'Appointment completed',
        'Your appointment$doctor is marked as completed.',
        );

      case 'rescheduled':
        return (
        'Appointment rescheduled',
        'Your appointment$doctor has been rescheduled.',
        );

      default:
        final label = status
            .replaceAll('_', ' ')
            .trim();

        return (
        'Appointment updated',
        label.isEmpty
            ? 'Your appointment$doctor was updated.'
            : 'Your appointment$doctor is now $label.',
        );
    }
  }

  static String? _cleanText(
      dynamic value,
      ) {
    final text =
    value?.toString().trim();

    if (text == null ||
        text.isEmpty ||
        text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  static String _shortDate(
      DateTime value,
      ) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  Future<void>
  syncTodayAppointments() async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    final snapshot =
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection(
      'appointments',
    )
        .get();

    final now = DateTime.now();
    final todayKey =
    _dateKey(now);

    for (final doc
    in snapshot.docs) {
      final data = doc.data();

      if (data['status']
          ?.toString()
          .toLowerCase() !=
          'confirmed') {
        continue;
      }

      final appointmentDate =
      data['appointmentDate']
          ?.toString()
          .trim();

      if (appointmentDate == null ||
          appointmentDate !=
              todayKey) {
        continue;
      }

      final doctorName =
      data['doctorName']
          ?.toString()
          .trim();

      final appointmentTime =
      data['appointmentTime']
          ?.toString()
          .trim();

      final specialization =
      data['doctorSpecialization']
          ?.toString()
          .trim();

      final consultationType =
      data['consultationType']
          ?.toString()
          .trim()
          .toLowerCase();

      final messageParts =
      <String>[
        if (doctorName != null &&
            doctorName.isNotEmpty)
          doctorName,
        if (specialization != null &&
            specialization.isNotEmpty)
          specialization,
        if (consultationType ==
            'video')
          'Video call',
        if (consultationType ==
            'clinic')
          'In clinic',
        if (appointmentTime != null &&
            appointmentTime.isNotEmpty)
          appointmentTime,
      ];

      await createNotification(
        type: 'appointment',
        title:
        'Appointment today',
        message:
        messageParts.isEmpty
            ? 'You have a confirmed appointment today.'
            : messageParts.join(
          ' • ',
        ),
        referenceId: doc.id,
        action:
        'open_appointment',
        deterministicId:
        'appointment_today_${doc.id}_$todayKey',
      );
    }
  }

  bool _audienceMatches(
      String? audience, {
        required bool isPlus,
      }) {
    final normalized =
    audience
        ?.trim()
        .toLowerCase();

    if (normalized == null ||
        normalized.isEmpty ||
        normalized == 'all') {
      return true;
    }

    if (normalized == 'plus' ||
        normalized == 'premium' ||
        normalized == 'paid') {
      return isPlus;
    }

    if (normalized == 'free') {
      return !isPlus;
    }

    return false;
  }

  bool _isPlusUser(
      Map<String, dynamic> userData,
      ) {
    final now = DateTime.now();

    final isPaid =
        userData['isPaid'] == true;

    final expiresAt =
    _readDate(
      userData[
      'subscriptionExpiresAt'],
    );

    if (isPaid &&
        expiresAt != null &&
        expiresAt.isAfter(now)) {
      return true;
    }

    // Legacy formats kept for compatibility.
    final subscription =
    userData['subscription'];

    if (subscription is Map) {
      final data =
      Map<String, dynamic>.from(
        subscription,
      );

      final plan =
      data['plan']
          ?.toString()
          .trim()
          .toLowerCase();

      final active =
          data['active'] == true;

      if (active &&
          (plan == 'plus' ||
              plan == 'premium' ||
              plan == 'paid')) {
        return true;
      }
    }

    final plan =
    userData['plan']
        ?.toString()
        .trim()
        .toLowerCase();

    return plan == 'plus' ||
        plan == 'premium' ||
        plan == 'paid';
  }

  DateTime? _readDate(
      dynamic value,
      ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static String _dateKey(
      DateTime value,
      ) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}