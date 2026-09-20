import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthActivityData {
  final int steps;
  final double distanceKm;
  final int activeCalories;

  const HealthActivityData({
    required this.steps,
    required this.distanceKm,
    required this.activeCalories,
  });
}

enum HealthConnectResult {
  connected,
  permissionDenied,
  unavailable,
  error,
}

class HealthActivityService {
  HealthActivityService._();

  static final HealthActivityService instance =
  HealthActivityService._();

  final Health _health = Health();

  bool _configured = false;

  final List<HealthDataType> _types = const [
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  final List<HealthDataAccess> _permissions = const [
    HealthDataAccess.READ,
    HealthDataAccess.READ,
    HealthDataAccess.READ,
  ];

  // =========================================================
  // CONFIGURE
  // =========================================================

  Future<void> _configure() async {
    if (_configured) return;

    await _health.configure();

    _configured = true;
  }

  // =========================================================
  // CONNECT
  // Called only when user taps Connect.
  // =========================================================

  Future<HealthConnectResult> connect() async {
    try {
      await _configure();

      if (Platform.isAndroid) {
        final available =
        await _health.isHealthConnectAvailable();

        if (!available) {
          return HealthConnectResult.unavailable;
        }

        // Android runtime permission used for fitness/step access.
        final activityPermission =
        await Permission.activityRecognition.request();

        if (!activityPermission.isGranted) {
          return HealthConnectResult.permissionDenied;
        }
      }

      // THIS should now open the Health Connect permission screen.
      final granted =
      await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );

      if (!granted) {
        return HealthConnectResult.permissionDenied;
      }

      return HealthConnectResult.connected;
    } on UnsupportedError {
      return HealthConnectResult.unavailable;
    } catch (e) {

      return HealthConnectResult.error;
    }
  }
  Future<void> debugTodaySteps() async {
    await _configure();

    final now = DateTime.now();

    final start = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final points =
    await _health.getHealthDataFromTypes(
      types: const [
        HealthDataType.STEPS,
      ],
      startTime: start,
      endTime: now,
    );

    debugPrint(
      'HEALTH CONNECT STEP POINTS: ${points.length}',
    );

    for (final point in points) {
      debugPrint(
        'STEP => '
            'value=${point.value}, '
            'from=${point.dateFrom}, '
            'to=${point.dateTo}, '
            'source=${point.sourceName}',
      );
    }

    final total =
    await _health.getTotalStepsInInterval(
      start,
      now,
    );

    debugPrint(
      'HEALTH CONNECT TOTAL STEPS: $total',
    );
  }

  // =========================================================
  // OPEN / INSTALL HEALTH CONNECT
  // =========================================================

  Future<void> installHealthConnect() async {
    try {
      await _configure();

      await _health.installHealthConnect();
    } catch (_) {
      // Home handles the UI message.
    }
  }

  // =========================================================
  // CHECK PERMISSION
  // Does NOT automatically show permission dialog.
  // =========================================================

  Future<bool> hasPermission() async {
    try {
      await _configure();

      if (Platform.isAndroid) {
        final available =
        await _health.isHealthConnectAvailable();

        if (!available) {
          return false;
        }
      }

      final granted =
      await _health.hasPermissions(
        _types,
        permissions: _permissions,
      );

      return granted == true;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // TODAY ACTIVITY
  // =========================================================

  Future<HealthActivityData?> getTodayActivity() async {
    try {
      await _configure();

      final allowed = await hasPermission();

      if (!allowed) {
        return null;
      }

      final now = DateTime.now();

      final start = DateTime(
        now.year,
        now.month,
        now.day,
      );

      // -------------------------------------------------------
      // STEPS
      // -------------------------------------------------------

      final steps =
      await _health.getTotalStepsInInterval(
        start,
        now,
      );

      // -------------------------------------------------------
      // DISTANCE + ACTIVE CALORIES
      // -------------------------------------------------------

      final points =
      await _health.getHealthDataFromTypes(
        types: const [
          HealthDataType.DISTANCE_DELTA,
          HealthDataType.ACTIVE_ENERGY_BURNED,
        ],
        startTime: start,
        endTime: now,
      );

      final cleanPoints =
      _health.removeDuplicates(points);

      double distanceMeters = 0;
      double calories = 0;

      for (final point in cleanPoints) {
        final value =
        _numericValue(point);

        if (value == null) continue;

        switch (point.type) {
          case HealthDataType.DISTANCE_DELTA:
            distanceMeters += value;
            break;

          case HealthDataType.ACTIVE_ENERGY_BURNED:
            calories += value;
            break;

          default:
            break;
        }
      }

      return HealthActivityData(
        steps: steps ?? 0,
        distanceKm: distanceMeters / 1000,
        activeCalories: calories.round(),
      );
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // BACKWARD COMPATIBILITY
  // =========================================================

  Future<int?> getTodaySteps() async {
    final activity =
    await getTodayActivity();

    return activity?.steps;
  }

  // =========================================================
  // NUMERIC HEALTH VALUE
  // =========================================================

  double? _numericValue(
      HealthDataPoint point,
      ) {
    final value = point.value;

    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }

    return null;
  }
}