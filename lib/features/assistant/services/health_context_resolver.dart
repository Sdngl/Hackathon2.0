import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/context_resolution.dart';

class HealthContextResolver {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HealthContextResolver({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<ContextResolution> resolve({
    required String message,
  }) async {
    final normalized = message.toLowerCase().trim();

    final contextType = _detectContextType(normalized);

    if (contextType == null) {
      return ContextResolution.general();
    }

    if (!_looksPersonal(normalized)) {
      return ContextResolution.general();
    }

    final user = _auth.currentUser;

    if (user == null) {
      return ContextResolution.missing(
        type: contextType,
        message: 'You need to sign in before I can check your saved health data.',
      );
    }

    final collectionName = _collectionForType(contextType);

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection(collectionName)
        .get();

    if (snapshot.docs.isEmpty) {
      return ContextResolution.missing(
        type: contextType,
        message: _missingMessage(contextType),
      );
    }

    final candidates = snapshot.docs.map((doc) {
      final cleanedData = _removeImageData(
        Map<String, dynamic>.from(doc.data()),
      );

      return ContextCandidate(
        id: doc.id,
        type: contextType,
        title: _buildTitle(
          contextType,
          cleanedData,
        ),
        subtitle: _buildSubtitle(
          contextType,
          cleanedData,
        ),
        data: {
          'id': doc.id,
          ...cleanedData,
        },
      );
    }).toList();

    if (_asksForLatest(normalized)) {
      final latest = _findLatest(candidates);

      return ContextResolution.ready(
        type: contextType,
        candidate: latest,
      );
    }

    if (candidates.length == 1) {
      return ContextResolution.ready(
        type: contextType,
        candidate: candidates.first,
      );
    }

    return ContextResolution.needsSelection(
      type: contextType,
      candidates: candidates,
    );
  }

  HealthContextType? _detectContextType(
      String message,
      ) {
    final reportWords = [
      'report',
      'blood test',
      'lab result',
      'lab report',
      'test result',
      'medical report',
    ];

    final medicineWords = [
      'medicine',
      'medication',
      'tablet',
      'prescription',
      'drug',
    ];

    final mealWords = [
      'meal',
      'my food',
      'what i ate',
      'calorie',
      'calories',
      'protein',
      'carbs',
      'carbohydrate',
      'fat',
    ];

    if (_containsAny(message, reportWords)) {
      return HealthContextType.report;
    }

    if (_containsAny(message, medicineWords)) {
      return HealthContextType.medicine;
    }

    if (_containsAny(message, mealWords)) {
      return HealthContextType.meal;
    }

    return null;
  }

  bool _looksPersonal(
      String message,
      ) {
    final personalWords = [
      'my ',
      'mine',
      'i ate',
      'i had',
      'saved',
      'previous',
      'last ',
      'latest',
      'recent',
    ];

    return _containsAny(
      message,
      personalWords,
    );
  }

  bool _asksForLatest(
      String message,
      ) {
    return message.contains('latest') ||
        message.contains('recent') ||
        message.contains('last report') ||
        message.contains('last meal') ||
        message.contains('last medicine');
  }

  bool _containsAny(
      String message,
      List<String> words,
      ) {
    for (final word in words) {
      if (message.contains(word)) {
        return true;
      }
    }

    return false;
  }

  String _collectionForType(
      HealthContextType type,
      ) {
    switch (type) {
      case HealthContextType.report:
        return 'reports';

      case HealthContextType.medicine:
        return 'medicines';

      case HealthContextType.meal:
        return 'meals';
    }
  }

  String _missingMessage(
      HealthContextType type,
      ) {
    switch (type) {
      case HealthContextType.report:
        return 'I could not find any saved reports in your Health Vault. Scan or save a report first, then I can explain it.';

      case HealthContextType.medicine:
        return 'I could not find any saved medicines. Scan or save a medicine first, then I can explain it.';

      case HealthContextType.meal:
        return 'I could not find any saved meals. Analyze or save a meal first, then I can help you with it.';
    }
  }

  String _buildTitle(
      HealthContextType type,
      Map<String, dynamic> data,
      ) {
    switch (type) {
      case HealthContextType.report:
        final nestedReport = data['report'];

        if (data['title'] != null) {
          return data['title'].toString();
        }

        if (nestedReport is Map &&
            nestedReport['title'] != null) {
          return nestedReport['title'].toString();
        }

        return 'Medical Report';

      case HealthContextType.medicine:
        final nestedMedicine = data['medicine'];

        if (data['name'] != null) {
          return data['name'].toString();
        }

        if (nestedMedicine is Map &&
            nestedMedicine['name'] != null) {
          return nestedMedicine['name'].toString();
        }

        return 'Medicine';

      case HealthContextType.meal:
        final foods = data['foods'];

        if (foods is List &&
            foods.isNotEmpty) {
          final firstFood = foods.first;

          if (firstFood is Map &&
              firstFood['name'] != null) {
            return firstFood['name'].toString();
          }
        }

        return 'Meal';
    }
  }

  String _buildSubtitle(
      HealthContextType type,
      Map<String, dynamic> data,
      ) {
    switch (type) {
      case HealthContextType.report:
        final nestedReport = data['report'];

        dynamic date =
            data['reportDate'] ??
                data['report_date'] ??
                data['createdAt'];

        if (date == null &&
            nestedReport is Map) {
          date =
              nestedReport['report_date'] ??
                  nestedReport['reportDate'];
        }

        return _formatValue(date) ??
            'Saved report';

      case HealthContextType.medicine:
        final nestedMedicine = data['medicine'];

        final name =
            data['generic_name'] ??
                (nestedMedicine is Map
                    ? nestedMedicine['generic_name']
                    : null);

        final strength =
            data['strength'] ??
                (nestedMedicine is Map
                    ? nestedMedicine['strength']
                    : null);

        final values = [
          name?.toString(),
          strength?.toString(),
        ].whereType<String>().where(
              (value) => value.trim().isNotEmpty,
        ).toList();

        return values.isEmpty
            ? 'Saved medicine'
            : values.join(' • ');

      case HealthContextType.meal:
        final nutrition = data['nutrition'];

        if (nutrition is Map) {
          final calories =
          nutrition['estimated_calories_kcal'];

          if (calories != null) {
            return '$calories kcal';
          }
        }

        return 'Saved meal';
    }
  }

  String? _formatValue(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day}/${date.month}/${date.year}';
    }

    if (value is DateTime) {
      return '${value.day}/${value.month}/${value.year}';
    }

    return value.toString();
  }

  ContextCandidate _findLatest(
      List<ContextCandidate> candidates,
      ) {
    final sorted = [...candidates];

    sorted.sort(
          (a, b) {
        final aDate =
        _extractTimestamp(a.data);

        final bDate =
        _extractTimestamp(b.data);

        return bDate.compareTo(aDate);
      },
    );

    return sorted.first;
  }

  DateTime _extractTimestamp(
      Map<String, dynamic> data,
      ) {
    final nestedReport = data['report'];

    final possibleValues = [
      data['createdAt'],
      data['updatedAt'],
      data['reportDate'],
      data['report_date'],
      data['scannedAt'],
      data['analyzedAt'],
      if (nestedReport is Map)
        nestedReport['report_date'],
    ];

    for (final value in possibleValues) {
      final parsed = _parseDate(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }

  DateTime? _parseDate(
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

  Map<String, dynamic> _removeImageData(
      Map<String, dynamic> data,
      ) {
    final result = <String, dynamic>{};

    for (final entry in data.entries) {
      final key =
      entry.key.toLowerCase();

      if (key == 'imagebase64' ||
          key == 'base64' ||
          key == 'image_data' ||
          key == 'imagedata') {
        continue;
      }

      final value = entry.value;

      if (value is Map) {
        result[entry.key] =
            _removeImageData(
              Map<String, dynamic>.from(
                value,
              ),
            );

        continue;
      }

      if (value is List) {
        result[entry.key] =
            value.map(
                  (item) {
                if (item is Map) {
                  return _removeImageData(
                    Map<String, dynamic>.from(
                      item,
                    ),
                  );
                }

                return item;
              },
            ).toList();

        continue;
      }

      result[entry.key] = value;
    }

    return result;
  }
}