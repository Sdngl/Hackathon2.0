import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../service/health_activity_service.dart';
import '../../service/health_scan_repository.dart';
import '../../service/notification_repository.dart';
import '../camera/analysis_result_screen.dart';
import '../camera/camera.dart';
import '../notifications/notificatation.dart';
import '../theme/apptheme.dart';
import 'doctor_grid_page.dart';
import 'meal_log_page.dart';
import 'medical_reports_page.dart';
import 'movement_page.dart';

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
  final NotificationRepository _notificationRepository = NotificationRepository();

  bool _loading = true;
  String _name = 'User';

  Map<String, dynamic>? _medicineAnalysis;
  Map<String, dynamic>? _medicineReminder;

  int _todayCalories = 0;
  int _todayMealCount = 0;

  Map<String, dynamic>? _latestReportAnalysis;
  DateTime? _latestReportDate;

  int? _steps;
  int? _stepGoal;
  double? _distanceKm;
  int? _activityCalories;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      // Read already-authorized Health Connect data without prompting.
      final activity =
      await HealthActivityService.instance.getTodayActivity();

      // Keep today's appointment notification in sync when Home refreshes.
      try {
        await _notificationRepository.syncTodayAppointments();
      } catch (_) {
        // Notification sync must never block the dashboard itself.
      }

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
      final mealSnapshot = results[2] as QuerySnapshot<Map<String, dynamic>>;
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

      final stepGoal = _asInt(profile['stepGoal']) ??
          _asInt(profile['step_goal']);

      final reminderRaw =
          profile['medicineReminder'] ?? profile['medicine_reminder'];
      final medicineReminder = reminderRaw is Map
          ? Map<String, dynamic>.from(reminderRaw)
          : null;

      final latestMedicine =
      _latestCompletedDocument(medicineSnapshot.docs);

      final medicineAnalysis = latestMedicine?['analysis'] is Map
          ? Map<String, dynamic>.from(latestMedicine!['analysis'] as Map)
          : null;

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

        if (createdAt == null || createdAt.isBefore(todayStart)) continue;

        final analysisRaw = data['analysis'];
        if (analysisRaw is! Map) continue;

        final analysis = Map<String, dynamic>.from(analysisRaw);
        calories += _extractCalories(analysis);
        mealCount++;
      }

      final latestReport = _latestCompletedDocument(reportSnapshot.docs);

      final reportAnalysis = latestReport?['analysis'] is Map
          ? Map<String, dynamic>.from(latestReport!['analysis'] as Map)
          : null;

      if (!mounted) return;

      setState(() {
        _name = name;
        _stepGoal = stepGoal;
        _steps = activity?.steps;
        _distanceKm = activity?.distanceKm;
        _activityCalories = activity?.activeCalories;
        _medicineAnalysis = medicineAnalysis;
        _medicineReminder = medicineReminder;
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

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load dashboard: $e')),
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

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
      ),
    );
  }

  void _openAppointments() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DoctorGridPage()),
    );
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const Camera()),
    );
  }

  void _openMedicineQuickAction() {
    if (_medicineAnalysis != null) {
      _openMedicine();
      return;
    }

    _openScanner();
  }

  Future<void> _openMedicine() async {
    final analysis = _medicineAnalysis;
    if (analysis == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisResultScreen(
          type: 'medicine',
          result: analysis,
        ),
      ),
    );

    if (!mounted) return;
    await _loadDashboard();
  }

  void _openMedicalReports() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MedicalReportsPage()),
    );
  }

  void _openYoga() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MovementPage(initialType: MovementType.yoga),
      ),
    );
  }

  void _openExercise() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MovementPage(initialType: MovementType.exercise),
      ),
    );
  }

  void _openBreathing() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MovementPage(initialType: MovementType.breathing),
      ),
    );
  }

  Future<void> _openActivitySetup() async {
    final result =
    await HealthActivityService.instance.connect();

    if (!mounted) return;

    switch (result) {
      case HealthConnectResult.connected:
        final activity =
        await HealthActivityService.instance.getTodayActivity();

        if (!mounted) return;

        setState(() {
          _steps = activity?.steps;
          _distanceKm = activity?.distanceKm;
          _activityCalories = activity?.activeCalories;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fitness data connected successfully.',
            ),
          ),
        );

        break;

      case HealthConnectResult.permissionDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Health permission was not granted.',
            ),
          ),
        );

        break;

      case HealthConnectResult.unavailable:
        _showHealthConnectDialog();
        break;

      case HealthConnectResult.error:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not connect to fitness data.',
            ),
          ),
        );

        break;
    }
  }

  void _showHealthConnectDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Health Connect required',
          ),
          content: const Text(
            'SEVA uses Health Connect to read your steps, distance, and activity calories.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Not now',
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await HealthActivityService.instance
                    .installHealthConnect();
              },
              child: const Text(
                'Set up',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F6),
        body: SafeArea(
          bottom: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _loadDashboard,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final horizontalPadding = width < 360 ? 12.0 : 16.0;
                final contentWidth = math.min(width, 760.0);

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 92),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          6,
                          horizontalPadding,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StreamBuilder<int>(
                              stream: _notificationRepository.watchUnreadCount(),
                              builder: (context, snapshot) {
                                return _Header(
                                  name: _name,
                                  hasNotifications: (snapshot.data ?? 0) > 0,
                                  onBell: _openNotifications,
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            _DoctorHeroCard(
                              onTap: _openAppointments,
                            ),

                            const SizedBox(height: 16),

                            const _HomeSectionTitle(
                              title: 'Medicine reminder',
                            ),
                            const SizedBox(height: 8),

                            if (_medicineAnalysis != null)
                              _MedicationCard(
                                analysis: _medicineAnalysis!,
                                reminder: _medicineReminder,
                                onTap: _openMedicine,
                              )
                            else
                              _NoMedicineCard(
                                onTap: _openScanner,
                              ),

                            const SizedBox(height: 16),

                            const _HomeSectionTitle(
                              title: 'Today Activity',
                            ),
                            const SizedBox(height: 8),

                            _TodayOverview(
                              steps: _steps,
                              goal: _stepGoal,
                              mealCount: _todayMealCount,
                              calories: _todayCalories,
                              reportAnalysis: _latestReportAnalysis,
                              reportDate: _latestReportDate,
                              onSteps: _openActivitySetup,
                              onMeals: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MealLogPage(),
                                  ),
                                );
                              },
                              onReports: _openMedicalReports,
                            ),

                            const SizedBox(height: 18),

                            const _HomeSectionTitle(
                              title: 'Recent health activity',
                            ),
                            const SizedBox(height: 8),

                            _RecentHealthActivity(
                              medicineAnalysis: _medicineAnalysis,
                              mealCount: _todayMealCount,
                              calories: _todayCalories,
                              reportAnalysis: _latestReportAnalysis,
                              reportDate: _latestReportDate,
                              onMedicine: _openMedicineQuickAction,
                              onMeals: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MealLogPage(),
                                  ),
                                );
                              },
                              onReports: _openMedicalReports,
                            ),

                            const SizedBox(height: 16),
                            _SectionHeader(
                              title: "Today's movement",
                              action: 'See all',
                              onAction: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const MovementPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            _MovementFeatureCard(
                              icon: Icons.self_improvement_rounded,
                              title: 'Morning Yoga Flow',
                              meta: '15 min · Beginner · 6 poses',
                              badge: 'Default plan',
                              tint: _purple,
                              onTap: _openYoga,
                            ),
                            const SizedBox(height: 8),
                            _MovementFeatureCard(
                              icon: Icons.fitness_center_rounded,
                              title: 'Exercise',
                              meta: 'Strength · Mobility · Fitness',
                              tint: _coral,
                              onTap: _openExercise,
                            ),
                            const SizedBox(height: 8),
                            _MovementFeatureCard(
                              icon: Icons.air_rounded,
                              title: 'Breathing',
                              meta: 'Relaxation · Focus · Calm',
                              tint: _blue,
                              onTap: _openBreathing,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration([double radius = 22]) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.035),
      blurRadius: 20,
      offset: const Offset(0, 7),
    ),
  ],
);

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
              fontSize: 18,
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
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
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
                    size: 23,
                    color: AppColors.textDark,
                  ),
                  if (hasNotifications)
                    Positioned(
                      top: 10,
                      right: 11,
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

class _HomeSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _HomeSectionTitle({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.textDark,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DoctorHeroCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DoctorHeroCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final heroHeight = (width * 0.52).clamp(178.0, 210.0);
        final imageWidth = (width * 0.82).clamp(235.0, 330.0);
        final imageHeight = heroHeight + 68;
        final imageRight = -((width * 0.16).clamp(42.0, 66.0));
        final textRightPadding = (width * 0.36).clamp(118.0, 145.0);
        final compact = width < 350;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(26),
            child: Ink(
              height: heroHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF073B31),
                    Color(0xFF0A6A56),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF073B31).withOpacity(0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    right: -30,
                    top: -38,
                    child: Container(
                      width: width * 0.42,
                      height: width * 0.42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: width * 0.03,
                    bottom: -30,
                    child: Container(
                      width: width * 0.34,
                      height: width * 0.34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5EE6B8).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: imageRight,
                    bottom: 0,
                    child: SizedBox(
                      width: imageWidth,
                      height: imageHeight,
                      child: Image.asset(
                        'assets/D1.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 20,
                      compact ? 16 : 19,
                      textRightPadding,
                      compact ? 44 : 48,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 7 : 9,
                            vertical: compact ? 1 : 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'BETTER CARE, BETTER LIFE',
                              style: TextStyle(
                                fontSize: compact ? 8.3 : 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: const Color(0xFFBFF7E3),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 7 : 10),
                        Text(
                          'Book a Doctor\nDigitally',
                          style: TextStyle(
                            fontSize: compact ? 20 : 24,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 6),
                        Text(
                          'Find verified doctors and book a consultation that fits your time.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 10.2 : 11.5,
                            height: 1.25,
                            color: Colors.white.withOpacity(0.82),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: compact ? 16 : 20,
                    bottom: compact ? 13 : 16,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Find a doctor',
                          style: TextStyle(
                            fontSize: compact ? 11 : 12.2,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFBFF7E3),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          width: compact ? 21 : 24,
                          height: compact ? 21 : 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: compact ? 12 : 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodayOverview extends StatelessWidget {
  final int? steps;
  final int? goal;
  final int mealCount;
  final int calories;
  final Map<String, dynamic>? reportAnalysis;
  final DateTime? reportDate;
  final VoidCallback onSteps;
  final VoidCallback onMeals;
  final VoidCallback onReports;

  const _TodayOverview({
    required this.steps,
    required this.goal,
    required this.mealCount,
    required this.calories,
    required this.reportAnalysis,
    required this.reportDate,
    required this.onSteps,
    required this.onMeals,
    required this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGoal = (goal != null && goal! > 0) ? goal! : 10000;
    final reportSubtitle = reportAnalysis == null
        ? 'No report'
        : reportDate == null
        ? 'Latest saved'
        : _shortDate(reportDate!);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gap = width < 360 ? 7.0 : 10.0;

        final cards = [
          _OverviewCard(
            icon: Icons.directions_walk_rounded,
            tint: _green,
            label: 'Steps',
            value: steps == null ? 'Connect' : _thousands(steps!),
            subtitle: steps == null
                ? 'Health data'
                : 'of ${_thousands(effectiveGoal)}',
            onTap: onSteps,
          ),
          _OverviewCard(
            icon: Icons.restaurant_rounded,
            tint: _coral,
            label: 'Meals',
            value: '$mealCount',
            subtitle: calories > 0 ? '$calories kcal' : 'logged today',
            onTap: onMeals,
          ),
          _OverviewCard(
            icon: Icons.description_outlined,
            tint: _blue,
            label: 'Reports',
            value: reportAnalysis == null ? 'None' : 'Latest',
            subtitle: reportSubtitle,
            onTap: onReports,
          ),
        ];

        if (width < 310) {
          final cardWidth = (width - gap) / 2;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final card in cards)
                SizedBox(
                  width: cardWidth,
                  child: card,
                ),
            ],
          );
        }

        final cardWidth = (width - (gap * 2)) / 3;
        final cardHeight = (cardWidth * 1.22).clamp(118.0, 140.0);

        return SizedBox(
          width: double.infinity,
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[0]),
              SizedBox(width: gap),
              Expanded(child: cards[1]),
              SizedBox(width: gap),
              Expanded(child: cards[2]),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final _Tint tint;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.icon,
    required this.tint,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 105;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 8 : 10,
              ),
              decoration: _cardDecoration(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 30 : 34,
                    height: compact ? 30 : 34,
                    decoration: BoxDecoration(
                      color: tint.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: compact ? 16 : 18,
                      color: tint.fg,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 10.3 : 11.3,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: compact ? 16 : 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 9 : 10,
                      color: AppColors.label,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecentHealthActivity extends StatelessWidget {
  final Map<String, dynamic>? medicineAnalysis;
  final int mealCount;
  final int calories;
  final Map<String, dynamic>? reportAnalysis;
  final DateTime? reportDate;
  final VoidCallback onMedicine;
  final VoidCallback onMeals;
  final VoidCallback onReports;

  const _RecentHealthActivity({
    required this.medicineAnalysis,
    required this.mealCount,
    required this.calories,
    required this.reportAnalysis,
    required this.reportDate,
    required this.onMedicine,
    required this.onMeals,
    required this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    final medicineName = _medicineName(medicineAnalysis);
    final reportName = _reportName(reportAnalysis);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration: _cardDecoration(22),
      child: Column(
        children: [
          _RecentActivityRow(
            icon: Icons.medication_outlined,
            tint: _amber,
            title: medicineName ?? 'Medicine',
            subtitle: medicineName == null
                ? 'No medicine analysis yet'
                : 'Latest saved medicine',
            onTap: onMedicine,
          ),
          const Divider(
            height: 1,
            color: Color(0xFFE8ECEA),
          ),
          _RecentActivityRow(
            icon: Icons.restaurant_outlined,
            tint: _coral,
            title: mealCount == 0
                ? 'Meals'
                : '$mealCount meal${mealCount == 1 ? '' : 's'} today',
            subtitle: mealCount == 0
                ? 'No meal analysis today'
                : calories > 0
                ? '$calories kcal analyzed today'
                : 'View today\'s meal log',
            onTap: onMeals,
          ),
          const Divider(
            height: 1,
            color: Color(0xFFE8ECEA),
          ),
          _RecentActivityRow(
            icon: Icons.description_outlined,
            tint: _blue,
            title: reportName ?? 'Medical reports',
            subtitle: reportAnalysis == null
                ? 'No report saved yet'
                : reportDate == null
                ? 'Latest saved report'
                : 'Saved ${_shortDate(reportDate!)}',
            onTap: onReports,
          ),
        ],
      ),
    );
  }

  static String? _medicineName(Map<String, dynamic>? analysis) {
    if (analysis == null) return null;
    final raw = analysis['medicine'];
    if (raw is Map) {
      final name = raw['name']?.toString().trim();
      if (name != null && name.isNotEmpty && name.toLowerCase() != 'null') {
        return name;
      }
    }
    return null;
  }

  static String? _reportName(Map<String, dynamic>? analysis) {
    if (analysis == null) return null;

    final raw = analysis['report'];
    if (raw is Map) {
      for (final key in ['title', 'report_type', 'type']) {
        final value = raw[key]?.toString().trim();
        if (value != null &&
            value.isNotEmpty &&
            value.toLowerCase() != 'null') {
          return value;
        }
      }
    }

    for (final key in ['title', 'report_type']) {
      final value = analysis[key]?.toString().trim();
      if (value != null &&
          value.isNotEmpty &&
          value.toLowerCase() != 'null') {
        return value;
      }
    }

    return null;
  }
}

class _RecentActivityRow extends StatelessWidget {
  final IconData icon;
  final _Tint tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RecentActivityRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tint.bg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 21,
                color: tint.fg,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.label,
            ),
          ],
        ),
      ),
    );
  }
}

String _shortDate(DateTime date) {
  const months = [
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

  return '${months[date.month - 1]} ${date.day}';
}

String _thousands(int value) {
  final s = value.toString();
  final b = StringBuffer();

  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class _MedicationCard extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final Map<String, dynamic>? reminder;
  final VoidCallback onTap;

  const _MedicationCard({
    required this.analysis,
    required this.reminder,
    required this.onTap,
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

  String get _scannedMedicineName {
    final medicineRaw = analysis['medicine'];
    final medicine = medicineRaw is Map
        ? Map<String, dynamic>.from(medicineRaw)
        : <String, dynamic>{};

    return _clean(medicine['name']) ?? 'Medicine';
  }

  bool get _hasReminder {
    final data = reminder;
    if (data == null || data['enabled'] != true) return false;

    final times = data['times'];
    return times is List && times.isNotEmpty;
  }

  String get _medicineName {
    if (_hasReminder) {
      final savedName = _clean(reminder?['medicineName']) ??
          _clean(reminder?['medicine_name']);

      if (savedName != null) return savedName;
    }

    return _scannedMedicineName;
  }

  List<TimeOfDay> get _reminderTimes {
    final raw = reminder?['times'];
    if (raw is! List) return const [];

    final result = <TimeOfDay>[];

    for (final item in raw) {
      if (item is Map) {
        final hourRaw = item['hour'];
        final minuteRaw = item['minute'];

        final hour = hourRaw is num
            ? hourRaw.toInt()
            : int.tryParse(hourRaw?.toString() ?? '');
        final minute = minuteRaw is num
            ? minuteRaw.toInt()
            : int.tryParse(minuteRaw?.toString() ?? '');

        if (hour != null &&
            minute != null &&
            hour >= 0 &&
            hour <= 23 &&
            minute >= 0 &&
            minute <= 59) {
          result.add(
            TimeOfDay(
              hour: hour,
              minute: minute,
            ),
          );
        }
      } else if (item is String) {
        final parts = item.split(':');

        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);

          if (hour != null &&
              minute != null &&
              hour >= 0 &&
              hour <= 23 &&
              minute >= 0 &&
              minute <= 59) {
            result.add(
              TimeOfDay(
                hour: hour,
                minute: minute,
              ),
            );
          }
        }
      }
    }

    return result;
  }

  TimeOfDay? _nextReminderTime() {
    final times = _reminderTimes;
    if (times.isEmpty) return null;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;

    final sorted = [...times]
      ..sort(
            (a, b) => (a.hour * 60 + a.minute)
            .compareTo(b.hour * 60 + b.minute),
      );

    for (final time in sorted) {
      if (time.hour * 60 + time.minute >= nowMinutes) {
        return time;
      }
    }

    return sorted.first;
  }

  @override
  Widget build(BuildContext context) {
    final hasReminder = _hasReminder;
    final nextTime = _nextReminderTime();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 350;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 12 : 14),
              decoration: _cardDecoration(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: compact ? 44 : 48,
                    height: compact ? 44 : 48,
                    decoration: BoxDecoration(
                      color: _amber.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      hasReminder
                          ? Icons.notifications_active_rounded
                          : Icons.medication_rounded,
                      color: _amber.fg,
                      size: compact ? 22 : 24,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _medicineName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 15.5 : 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            if (hasReminder && nextTime != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _amber.bg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  nextTime.format(context),
                                  style: TextStyle(
                                    fontSize: compact ? 10.5 : 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: _amber.fg,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hasReminder
                              ? 'Reminder scheduled'
                              : 'No reminder scheduled',
                          style: TextStyle(
                            fontSize: compact ? 11.5 : 12.5,
                            color: hasReminder
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontWeight: hasReminder
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasReminder
                                  ? 'View reminder'
                                  : 'Set a reminder',
                              style: TextStyle(
                                fontSize: compact ? 11.5 : 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoMedicineCard extends StatelessWidget {
  final VoidCallback onTap;

  const _NoMedicineCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(22),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _amber.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.medication_outlined,
                  color: _amber.fg,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medicine reminders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Scan a medicine to review it and create reminders.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'See all',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MovementFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String meta;
  final String? badge;
  final _Tint tint;
  final VoidCallback onTap;

  const _MovementFeatureCard({
    required this.icon,
    required this.title,
    required this.meta,
    required this.tint,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: _cardDecoration(20),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: tint.bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: tint.fg, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.3,
                        height: 1.25,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: AppColors.label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
