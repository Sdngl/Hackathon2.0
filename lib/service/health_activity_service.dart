import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthActivityService {
  HealthActivityService._();

  static final instance = HealthActivityService._();

  final Health _health = Health();

  Future<void> initialize() async {
    await _health.configure();
  }

  Future<int?> getTodaySteps() async {
    await Permission.activityRecognition.request();

    const types = [
      HealthDataType.STEPS,
    ];

    final authorized = await _health.requestAuthorization(types);

    if (!authorized) {
      return null;
    }

    final now = DateTime.now();

    final midnight = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return await _health.getTotalStepsInInterval(
      midnight,
      now,
    );
  }
}