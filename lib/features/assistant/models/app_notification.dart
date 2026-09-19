import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  appointment,
  medicine,
  report,
  meal,
  content,
  announcement,
  general,
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final String? referenceId;
  final String? action;

  // Optional fields used by global Content / Announcement items.
  final String? category;
  final String? imageUrl;
  final String? audience;
  final String? sourceCollection;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.referenceId,
    required this.action,
    this.category,
    this.imageUrl,
    this.audience,
    this.sourceCollection,
  });

  factory AppNotification.fromFirestore(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data();

    return AppNotification.fromMap(
      id: document.id,
      data: data,
    );
  }

  factory AppNotification.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return AppNotification(
      id: id,
      type: _typeFromString(data['type']?.toString()),
      title: _clean(data['title']) ?? 'Notification',
      message:
      _clean(data['message']) ??
          _clean(data['body']) ??
          '',
      isRead: data['isRead'] == true,
      createdAt: _readDate(data['createdAt']),
      referenceId: _clean(data['referenceId']),
      action: _clean(data['action']),
      category: _clean(data['category']),
      imageUrl: _clean(data['imageUrl']),
      audience: _clean(data['audience']),
      sourceCollection: _clean(data['sourceCollection']),
    );
  }

  static AppNotificationType _typeFromString(
      String? raw,
      ) {
    switch (raw?.trim().toLowerCase()) {
      case 'appointment':
        return AppNotificationType.appointment;
      case 'medicine':
        return AppNotificationType.medicine;
      case 'report':
        return AppNotificationType.report;
      case 'meal':
        return AppNotificationType.meal;
      case 'content':
      case 'tip':
        return AppNotificationType.content;
      case 'announcement':
      case 'announcements':
        return AppNotificationType.announcement;
      default:
        return AppNotificationType.general;
    }
  }

  static DateTime? _readDate(
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

  static String? _clean(
      dynamic value,
      ) {
    final text = value?.toString().trim();

    if (text == null ||
        text.isEmpty ||
        text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }
}
