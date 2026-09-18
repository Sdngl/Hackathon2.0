import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../service/health_activity_service.dart';
import '../theme/apptheme.dart';
import 'doctor_grid_page.dart';

class _Tint {
  final Color bg;
  final Color fg;

  const _Tint(this.bg, this.fg);
}

const _green = _Tint(Color(0xFFE3F5EF), Color(0xFF0F7B64));
const _amber = _Tint(Color(0xFFFFF3D6), Color(0xFFD98E04));
const _grey = _Tint(Color(0xFFF0F2F1), Color(0xFF6B7572));
const _coral = _Tint(Color(0xFFFDE8E2), Color(0xFFF26B4E));
const _blue = _Tint(Color(0xFFE5EEFD), Color(0xFF3B74E0));
const _purple = _Tint(Color(0xFFEDE9FE), Color(0xFF7C5CE0));

enum _DoseStatus { taken, next, earlier, later }

class _Dose {
  final String time;
  _DoseStatus status;

  _Dose(this.time, this.status);
}

/// Keep this wrapper so code that already uses `Home()` continues to work.
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) => const HomeScreen();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;

  String _name = 'User';

  Map<String, dynamic>? _medicineAnalysis;
  List<_Dose> _doses = [];

  int _todayCalories = 0;
  int _todayMealCount = 0;

  Map<String, dynamic>? _latestReportAnalysis;
  DateTime? _latestReportDate;

  // Health Connect is intentionally not faked.
  // These stay null until we wire the real phone health-data source.
  int? _steps;
  int? _stepGoal;
  int? _activeMinutes;
  double? _distanceKm;
  int? _activityCalories;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final user = _auth.currentUser;
    final steps =
    await HealthActivityService.instance.getTodaySteps();

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      final results = await Future.wait([
        userRef.get(),
        userRef.collection('medicines').get(),
        userRef.collection('meals').get(),
        userRef.collection('reports').get(),
      ]);

      final userSnapshot =
      results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final medicineSnapshot =
      results[1] as QuerySnapshot<Map<String, dynamic>>;
      final mealSnapshot =
      results[2] as QuerySnapshot<Map<String, dynamic>>;
      final reportSnapshot =
      results[3] as QuerySnapshot<Map<String, dynamic>>;

      final profile = userSnapshot.data() ?? <String, dynamic>{};

      final name = _firstString([
        profile['displayName'],
        profile['display_name'],
        profile['name'],
        profile['fullName'],
        profile['full_name'],
        user.displayName,
        user.email?.split('@').first,
      ]) ??
          'User';

      final stepGoal = _asInt(
        profile['stepGoal'],
      ) ??
          _asInt(
            profile['step_goal'],
          );

      final latestMedicine =
      _latestCompletedDocument(medicineSnapshot.docs);

      final medicineAnalysis = latestMedicine?['analysis'] is Map
          ? Map<String, dynamic>.from(latestMedicine!['analysis'] as Map)
          : null;

      final doses = medicineAnalysis == null
          ? <_Dose>[]
          : _buildDoses(medicineAnalysis['suggested_schedule']);

      final todayStart = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );

      var calories = 0.0;
      var mealCount = 0;

      for (final doc in mealSnapshot.docs) {
        final data = doc.data();
        final createdAt = _toDateTime(data['createdAt']);

        if (createdAt == null || createdAt.isBefore(todayStart)) {
          continue;
        }

        final analysisRaw = data['analysis'];

        if (analysisRaw is! Map) {
          continue;
        }

        final analysis = Map<String, dynamic>.from(analysisRaw);
        calories += _extractCalories(analysis);
        mealCount++;
      }

      final latestReport =
      _latestCompletedDocument(reportSnapshot.docs);

      final reportAnalysis = latestReport?['analysis'] is Map
          ? Map<String, dynamic>.from(latestReport!['analysis'] as Map)
          : null;

      if (!mounted) return;

      setState(() {
        _name = name;
        _stepGoal = stepGoal;

        _steps = steps;

        _medicineAnalysis = medicineAnalysis;
        _doses = doses;

        _todayCalories = calories.round();
        _todayMealCount = mealCount;

        _latestReportAnalysis = reportAnalysis;
        _latestReportDate = latestReport == null
            ? null
            : _toDateTime(latestReport['createdAt']);

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load dashboard: $e'),
        ),
      );
    }
  }

  Map<String, dynamic>? _latestCompletedDocument(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    final completed = docs.where((doc) {
      final data = doc.data();
      final status = data['status']?.toString().toLowerCase();

      return status == 'completed' && data['analysis'] is Map;
    }).toList();

    if (completed.isEmpty) return null;

    completed.sort((a, b) {
      final aDate = _toDateTime(a.data()['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final bDate = _toDateTime(b.data()['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return completed.first.data();
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();

      if (text != null &&
          text.isNotEmpty &&
          text.toLowerCase() != 'null') {
        return text;
      }
    }

    return null;
  }

  double _extractCalories(Map<String, dynamic> analysis) {
    final nutritionRaw = analysis['nutrition'];

    if (nutritionRaw is Map) {
      final nutrition = Map<String, dynamic>.from(nutritionRaw);

      for (final key in [
        'estimated_calories_kcal',
        'calories_kcal',
        'calories',
        'estimatedCalories',
      ]) {
        final value = nutrition[key];

        if (value is num) return value.toDouble();

        if (value != null) {
          final parsed = double.tryParse(value.toString());
          if (parsed != null) return parsed;
        }
      }
    }

    for (final key in [
      'estimated_calories_kcal',
      'calories_kcal',
      'calories',
      'estimatedCalories',
    ]) {
      final value = analysis[key];

      if (value is num) return value.toDouble();

      if (value != null) {
        final parsed = double.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }

    return 0;
  }

  List<_Dose> _buildDoses(dynamic scheduleData) {
    if (scheduleData is! List) return [];

    final parsed = <({int minutes, String display})>[];

    for (final item in scheduleData) {
      if (item is! Map) continue;

      final rawTime = item['time']?.toString().trim();
      if (rawTime == null || rawTime.isEmpty) continue;

      final parts = rawTime.split(':');
      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null ||
          minute == null ||
          hour < 0 ||
          hour > 23 ||
          minute < 0 ||
          minute > 59) {
        continue;
      }

      parsed.add(
        (
        minutes: hour * 60 + minute,
        display: _formatTime(hour, minute),
        ),
      );
    }

    parsed.sort((a, b) => a.minutes.compareTo(b.minutes));

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    var nextIndex =
    parsed.indexWhere((item) => item.minutes >= currentMinutes);

    if (nextIndex == -1 && parsed.isNotEmpty) {
      // The next reminder after all of today's times is tomorrow's first one.
      nextIndex = 0;
    }

    final result = <_Dose>[];

    for (var i = 0; i < parsed.length; i++) {
      _DoseStatus status;

      if (i == nextIndex) {
        status = _DoseStatus.next;
      } else if (parsed[i].minutes < currentMinutes) {
        status = _DoseStatus.earlier;
      } else {
        status = _DoseStatus.later;
      }

      result.add(_Dose(parsed[i].display, status));
    }

    return result;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    var displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  void _markTaken() {
    final index =
    _doses.indexWhere((dose) => dose.status == _DoseStatus.next);

    if (index == -1) return;

    setState(() {
      _doses[index].status = _DoseStatus.taken;

      for (var i = index + 1; i < _doses.length; i++) {
        if (_doses[i].status == _DoseStatus.later) {
          _doses[i].status = _DoseStatus.next;
          return;
        }
      }
    });

    // This is UI-only for now. We are not pretending it is persisted
    // until medicine adherence storage is added.
  }
  void _openAppointments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DoctorGridPage(),
      ),
    );
  }

  void _openActivitySetup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Health Connect will provide real steps and movement data.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: _loading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : RefreshIndicator(
            onRefresh: _loadDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    name: _name,
                    hasNotifications: false,
                    onBell: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No new notifications'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  _ActivityHeroCard(
                    steps: _steps,
                    goal: _stepGoal,
                    kcal: _activityCalories,
                    km: _distanceKm,
                    onConnect: _openActivitySetup,
                  ),

                  const SizedBox(height: 16),

                  if (_medicineAnalysis != null)
                    _MedicationCard(
                      analysis: _medicineAnalysis!,
                      doses: _doses,
                      onTaken: _markTaken,
                    )
                  else
                    const _NoMedicineCard(),

                  const SizedBox(height: 16),

                  _AppointmentCard(
                    onTap: _openAppointments,
                  ),

                  const SizedBox(height: 16),

                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _MealsCard(
                            kcal: _todayCalories,
                            mealCount: _todayMealCount,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ReportCard(
                            analysis: _latestReportAnalysis,
                            createdAt: _latestReportDate,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  const Text(
                    "Today's movement",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _MovementCard(
                    activeMinutes: _activeMinutes,
                    distanceKm: _distanceKm,
                    steps: _steps,
                    onTap: _openActivitySetup,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration([double radius = 24]) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ],
);

class _IconTile extends StatelessWidget {
  final IconData icon;
  final _Tint tint;
  final double size;

  const _IconTile({
    required this.icon,
    required this.tint,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        icon,
        color: tint.fg,
        size: size * 0.5,
      ),
    );
  }
}

String _thousands(int value) {
  final s = value.toString();
  final b = StringBuffer();

  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      b.write(',');
    }
    b.write(s[i]);
  }

  return b.toString();
}

class _Header extends StatelessWidget {
  final String name;
  final bool hasNotifications;
  final VoidCallback onBell;

  const _Header({
    required this.name,
    required this.hasNotifications,
    required this.onBell,
  });

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstLetter =
    name.trim().isEmpty ? 'U' : name.trim().characters.first.toUpperCase();

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accentLight,
            shape: BoxShape.circle,
          ),
          child: Text(
            firstLetter,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBell,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 24,
                    color: AppColors.textDark,
                  ),
                  if (hasNotifications)
                    Positioned(
                      top: 11,
                      right: 12,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF26B4E),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityHeroCard extends StatelessWidget {
  final int? steps;
  final int? goal;
  final int? kcal;
  final double? km;
  final VoidCallback onConnect;

  const _ActivityHeroCard({
    required this.steps,
    required this.goal,
    required this.kcal,
    required this.km,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = steps != null;
    final effectiveGoal = (goal != null && goal! > 0) ? goal! : 10000;
    final progress =
    hasData ? (steps! / effectiveGoal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.splashTop,
            AppColors.splashBottom,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) {
              return CustomPaint(
                size: const Size(118, 118),
                painter: _WhiteRingPainter(progress: value),
                child: SizedBox(
                  width: 118,
                  height: 118,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.directions_walk_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasData ? '${(value * 100).round()}%' : '—',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 18),
          Expanded(
            child: hasData
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's steps",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _thousands(steps!),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  'of ${_thousands(effectiveGoal)} goal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (kcal != null)
                      _GlassPill(
                        icon: Icons.local_fire_department_outlined,
                        text: '$kcal kcal',
                      ),
                    if (km != null)
                      _GlassPill(
                        icon: Icons.location_on_outlined,
                        text: '${km!.toStringAsFixed(1)} km',
                      ),
                  ],
                ),
              ],
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activity data',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Connect your phone health data to show real steps and movement.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onConnect,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Connect'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteRingPainter extends CustomPainter {
  final double progress;

  _WhiteRingPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withOpacity(0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_WhiteRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _GlassPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GlassPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final List<_Dose> doses;
  final VoidCallback onTaken;

  const _MedicationCard({
    required this.analysis,
    required this.doses,
    required this.onTaken,
  });

  String? _clean(dynamic value) {
    final text = value?.toString().trim();

    if (text == null ||
        text.isEmpty ||
        text.toLowerCase() == 'null' ||
        text.toLowerCase() == 'unknown' ||
        text.toLowerCase() == 'not available') {
      return null;
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final medicineRaw = analysis['medicine'];
    final instructionsRaw = analysis['instructions'];

    final medicine = medicineRaw is Map
        ? Map<String, dynamic>.from(medicineRaw)
        : <String, dynamic>{};

    final instructions = instructionsRaw is Map
        ? Map<String, dynamic>.from(instructionsRaw)
        : <String, dynamic>{};

    final name = _clean(medicine['name']) ?? 'Medicine';
    final strength = _clean(medicine['strength']);
    final dose = _clean(instructions['dose']);
    final mealRelation = _clean(instructions['meal_relation']);

    _Dose? next;

    for (final doseItem in doses) {
      if (doseItem.status == _DoseStatus.next) {
        next = doseItem;
        break;
      }
    }

    final details = [
      if (dose != null) dose,
      if (mealRelation != null) mealRelation,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              const _IconTile(
                icon: Icons.medication_outlined,
                tint: _amber,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next == null
                          ? 'MEDICINE'
                          : 'NEXT REMINDER · ${next.time}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: next == null
                            ? AppColors.textMuted
                            : _amber.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        name,
                        if (strength != null) strength,
                      ].join(' '),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (next != null) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onTaken,
                  icon: const Icon(
                    Icons.check_rounded,
                    size: 18,
                  ),
                  label: const Text('Taken'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (doses.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < doses.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _DoseSlot(
                      dose: doses[i],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NoMedicineCard extends StatelessWidget {
  const _NoMedicineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          _IconTile(
            icon: Icons.medication_outlined,
            tint: _amber,
            size: 48,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medicine reminders',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Scan a medicine to create a reminder schedule.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseSlot extends StatelessWidget {
  final _Dose dose;

  const _DoseSlot({
    required this.dose,
  });

  @override
  Widget build(BuildContext context) {
    final (_Tint tint, String label) = switch (dose.status) {
      _DoseStatus.taken => (_green, 'Taken'),
      _DoseStatus.next => (_amber, 'Next'),
      _DoseStatus.earlier => (_grey, 'Earlier'),
      _DoseStatus.later => (_grey, 'Later'),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: tint.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              dose.time,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tint.fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const _IconTile(
                icon: Icons.medical_services_outlined,
                tint: _green,
                size: 48,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doctor appointment',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Find a doctor and choose an available appointment.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _green.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: _green.fg,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealsCard extends StatelessWidget {
  final int kcal;
  final int mealCount;

  const _MealsCard({
    required this.kcal,
    required this.mealCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IconTile(
            icon: Icons.restaurant_rounded,
            tint: _coral,
            size: 38,
          ),
          const SizedBox(height: 18),
          const Text(
            'Meals today',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$_todayLabel',
            ),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          Text(
            mealCount == 0
                ? 'No meals analyzed today'
                : '$mealCount meal${mealCount == 1 ? '' : 's'} analyzed today',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.label,
            ),
          ),
        ],
      ),
    );
  }

  String get _todayLabel => '$kcal kcal';
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic>? analysis;
  final DateTime? createdAt;

  const _ReportCard({
    required this.analysis,
    required this.createdAt,
  });

  String _title() {
    final data = analysis;
    if (data == null) return 'No report yet';

    final reportRaw = data['report'];

    if (reportRaw is Map) {
      final report = Map<String, dynamic>.from(reportRaw);

      for (final key in ['title', 'summary', 'report_type', 'type']) {
        final value = report[key]?.toString().trim();

        if (value != null &&
            value.isNotEmpty &&
            value.toLowerCase() != 'null') {
          return value;
        }
      }
    }

    for (final key in ['title', 'summary', 'report_type']) {
      final value = data[key]?.toString().trim();

      if (value != null &&
          value.isNotEmpty &&
          value.toLowerCase() != 'null') {
        return value;
      }
    }

    return 'Medical report';
  }

  String? _relativeDate() {
    final date = createdAt;
    if (date == null) return null;

    final difference = DateTime.now().difference(date);

    if (difference.inDays <= 0) return 'Uploaded today';
    if (difference.inDays == 1) return 'Uploaded yesterday';

    return 'Uploaded ${difference.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    final hasReport = analysis != null;
    final dateText = _relativeDate();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IconTile(
            icon: Icons.description_outlined,
            tint: _blue,
            size: 38,
          ),
          const SizedBox(height: 18),
          const Text(
            'Latest report',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _title(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          if (hasReport) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: _purple.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 13,
                    color: _purple.fg,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'AI analysis ready',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _purple.fg,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (dateText != null) ...[
            const SizedBox(height: 10),
            Text(
              dateText,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.label,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              'Scan a report to see it here',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.label,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MovementCard extends StatelessWidget {
  final int? activeMinutes;
  final double? distanceKm;
  final int? steps;
  final VoidCallback onTap;

  const _MovementCard({
    required this.activeMinutes,
    required this.distanceKm,
    required this.steps,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData =
        activeMinutes != null || distanceKm != null || steps != null;

    final parts = <String>[
      if (activeMinutes != null) '$activeMinutes active min',
      if (distanceKm != null) '${distanceKm!.toStringAsFixed(1)} km',
      if (steps != null) '${_thousands(steps!)} steps',
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const _IconTile(
                icon: Icons.monitor_heart_outlined,
                tint: _purple,
                size: 64,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _grey.bg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hasData ? 'Today' : 'Health data',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.label,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasData ? 'Movement summary' : 'Connect activity data',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasData
                          ? parts.join(' · ')
                          : 'Show real steps, distance and active minutes from your phone.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.label,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
