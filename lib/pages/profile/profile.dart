import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../payment/esewa_payment_page.dart';
import '../../service/notification_repository.dart';
import '../theme/apptheme.dart';
import '../widgets/subscription_card.dart';
import 'health_history_page.dart';
import 'setting.dart';
import 'premium_page.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _notificationRepository = NotificationRepository();

  bool _loading = true;
  Map<String, dynamic> _profile = {};
  int _medicineCount = 0;
  int _reportCount = 0;

  late final AnimationController _wellnessController;

  @override
  void initState() {
    super.initState();
    _wellnessController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    _loadProfile();
  }

  @override
  void dispose() {
    _wellnessController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final ref = _firestore.collection('users').doc(user.uid);
      final values = await Future.wait([
        ref.get(),
        ref.collection('medicines').get(),
        ref.collection('reports').get(),
      ]);

      if (!mounted) return;

      final userDoc = values[0] as DocumentSnapshot<Map<String, dynamic>>;
      final medicines = values[1] as QuerySnapshot<Map<String, dynamic>>;
      final reports = values[2] as QuerySnapshot<Map<String, dynamic>>;

      setState(() {
        _profile = userDoc.data() ?? {};
        _medicineCount = medicines.docs.length;
        _reportCount = reports.docs.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Could not load profile.');
      debugPrint('Profile load error: $e');
    }
  }

  String? _readString(List<String> keys) {
    for (final key in keys) {
      final value = _profile[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  bool _readBool(String key) => _profile[key] == true;

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String get _name =>
      _readString(['displayName', 'display_name', 'name', 'fullName', 'full_name']) ??
          _auth.currentUser?.displayName?.trim() ??
          'User';

  String? get _email =>
      _readString(['email']) ?? _auth.currentUser?.email;

  String? get _age => _readString(['age']);
  String? get _city => _readString(['city', 'location']);

  String get _initials {
    final parts = _name.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String? get _emergencyContact => _readString([
    'emergencyContact',
    'emergency_contact',
    'emergencyPhone',
    'emergency_phone',
  ]);

  DateTime? get _subscriptionStartedAt =>
      _date(_profile['subscriptionStartedAt']);

  DateTime? get _subscriptionExpiresAt =>
      _date(_profile['subscriptionExpiresAt']);

  bool get _subscriptionCancelAtPeriodEnd =>
      _readBool('subscriptionCancelAtPeriodEnd');

  bool get _hasActiveSubscription {
    final expires = _subscriptionExpiresAt;
    return _readBool('isPaid') &&
        expires != null &&
        expires.isAfter(DateTime.now());
  }

  String get _subscriptionTitle =>
      _readString(['subscriptionTitle']) ?? 'SEVA Premium';

  int? get _subscriptionPrice {
    final value = _profile['subscriptionPrice'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get _subscriptionSubtitle {
    final expires = _subscriptionExpiresAt;
    if (expires == null) return _subscriptionTitle;
    return _subscriptionCancelAtPeriodEnd
        ? 'Cancels on ${_formatDate(expires)}'
        : 'Active until ${_formatDate(expires)}';
  }

  DateTime _addMonthsClamped(DateTime date, int months) {
    final year = date.year + ((date.month - 1 + months) ~/ 12);
    final month = ((date.month - 1 + months) % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;

    return DateTime(
      year,
      month,
      day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EsewaPaymentPage(
          amount: plan.price,
          planTitle: plan.title,
        ),
      ),
    );

    if (!mounted || paid != true) return;

    try {
      final now = DateTime.now();
      final expires = _addMonthsClamped(now, plan.months);

      await _firestore.collection('users').doc(user.uid).set({
        'isPaid': true,
        'subscriptionPlan': plan.id,
        'subscriptionTitle': plan.title,
        'subscriptionMonths': plan.months,
        'subscriptionPrice': plan.price,
        'subscriptionStartedAt': Timestamp.fromDate(now),
        'subscriptionExpiresAt': Timestamp.fromDate(expires),
        'paymentProvider': 'esewa',
        'paymentMode': 'test',
        'subscriptionCancelAtPeriodEnd': false,
        'subscriptionCancelledAt': FieldValue.delete(),
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      try {
        await _notificationRepository.createSubscriptionActivatedNotification(
          planTitle: plan.title,
          startedAt: now,
          expiresAt: expires,
        );
      } catch (_) {}

      await _loadProfile();
      if (mounted) _snack('${plan.title} Premium activated successfully.');
    } catch (e) {
      if (mounted) _snack('Payment succeeded, but subscription could not be saved.');
      debugPrint('Subscription error: $e');
    }
  }

  Future<void> _cancelSubscriptionAtPeriodEnd() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: Text(
          'Premium will stay active until ${_formatDate(_subscriptionExpiresAt)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Premium'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel at expiry'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _firestore.collection('users').doc(user.uid).set({
      'subscriptionCancelAtPeriodEnd': true,
      'subscriptionCancelledAt': FieldValue.serverTimestamp(),
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.of(context).pop();
    await _loadProfile();
  }

  void _showSubscriptionDetails() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SEVA Premium',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Plan', value: _subscriptionTitle),
              _DetailRow(
                label: 'Price',
                value: _subscriptionPrice == null
                    ? 'Not available'
                    : 'Rs. ${formatRs(_subscriptionPrice!)}',
              ),
              _DetailRow(
                label: 'Started',
                value: _formatDate(_subscriptionStartedAt),
              ),
              _DetailRow(
                label: _subscriptionCancelAtPeriodEnd ? 'Access ends' : 'Expires',
                value: _formatDate(_subscriptionExpiresAt),
              ),
              const SizedBox(height: 16),
              if (!_subscriptionCancelAtPeriodEnd)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelSubscriptionAtPeriodEnd,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD92D20),
                    ),
                    child: const Text('Cancel subscription'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMedicineHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HealthHistoryPage(
          type: HealthHistoryType.medicine,
        ),
      ),
    );
  }

  void _openReportHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HealthHistoryPage(
          type: HealthHistoryType.report,
        ),
      ),
    );
  }

  Future<void> _openPremiumPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PremiumPage(
          onSubscribe: _subscribe,
        ),
      ),
    );

    if (mounted) {
      _loadProfile();
    }
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
    if (mounted) _loadProfile();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F6),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _loadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Color(0xFF17211E),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProfileHero(
                    initials: _initials,
                    name: _name,
                    age: _age,
                    city: _city,
                    email: _email,
                    onEdit: _openSettings,
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Premium'),
                  const SizedBox(height: 10),
                  _PremiumTeaserCard(
                    active: _hasActiveSubscription,
                    title: _hasActiveSubscription
                        ? _subscriptionTitle
                        : 'SEVA Premium',
                    subtitle: _hasActiveSubscription
                        ? _subscriptionSubtitle
                        : 'Unlock more for a healthier you',
                    description: _hasActiveSubscription
                        ? 'Your Premium access is active. Manage your plan and subscription details.'
                        : 'Get advanced insights, personalized care and more.',
                    actionLabel: _hasActiveSubscription
                        ? 'Manage Premium'
                        : 'Upgrade to Premium',
                    onTap: _hasActiveSubscription
                        ? _showSubscriptionDetails
                        : _openPremiumPage,
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    'Your Health',
                    subtitle: 'Your saved health activity',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _HealthCountCard(
                          count: _medicineCount,
                          label: 'Medications',
                          subtitle: 'Saved medicines',
                          color: const Color(0xFF11786D),
                          onTap: _openMedicineHistory,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HealthCountCard(
                          count: _reportCount,
                          label: 'Medical Records',
                          subtitle: 'Saved reports',
                          color: const Color(0xFF3B74E0),
                          onTap: _openReportHistory,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(
                    'Emergency Contact',
                    subtitle: 'Quick access to your saved contact',
                  ),
                  const SizedBox(height: 10),
                  _EmergencyContactCard(
                    contact: _emergencyContact,
                    onTap: _openSettings,
                  ),
                  const SizedBox(height: 24),
                  _AnimatedWellnessCard(
                    animation: _wellnessController,
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

class _ProfileHero extends StatelessWidget {
  final String initials;
  final String name;
  final String? age;
  final String? city;
  final String? email;
  final VoidCallback onEdit;

  const _ProfileHero({
    required this.initials,
    required this.name,
    required this.age,
    required this.city,
    required this.email,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (age != null && age!.isNotEmpty) '$age yrs',
      if (city != null && city!.isNotEmpty) city!,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F7F2), Color(0xFFF5FBF9)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCFE7DF)),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF11786D),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF17211E),
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    details.join(' · '),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF66736F),
                    ),
                  ),
                ],
                if (email != null && email!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF66736F),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF11786D),
                    side: const BorderSide(color: Color(0xFFBBD9D0)),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle(this.title, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF17211E),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 11.8,
              color: Color(0xFF7A8581),
            ),
          ),
        ],
      ],
    );
  }
}

class _PremiumTeaserCard extends StatelessWidget {
  final bool active;
  final String title;
  final String subtitle;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;

  const _PremiumTeaserCard({
    required this.active,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF075E4C),
                Color(0xFF0A7D65),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A6F5B).withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFFD76A),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.8,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white70,
                    size: 17,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.4,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF086652),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthCountCard extends StatelessWidget {
  final int count;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HealthCountCard({
    required this.count,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4EAE7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17211E),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.8,
                  color: Color(0xFF7A8581),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final String? contact;
  final VoidCallback onTap;

  const _EmergencyContactCard({
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasContact = contact != null && contact!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4EAE7)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasContact ? contact! : 'No emergency contact added',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17211E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasContact
                          ? 'Tap to manage your emergency contact'
                          : 'Add one from Settings',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF7A8581),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedWellnessCard extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedWellnessCard({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value * math.pi * 2;

        return Container(
          width: double.infinity,
          height: 128,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F7F2), Color(0xFFDDF3EB)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -18 + math.sin(t) * 8,
                top: 10 + math.cos(t) * 5,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 18 + math.cos(t) * 5,
                bottom: 13 + math.sin(t) * 4,
                child: Transform.rotate(
                  angle: -0.45 + math.sin(t) * 0.08,
                  child: Container(
                    width: 46,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF78C9B2).withOpacity(0.58),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(78, 24, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'A healthier you,',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF164C40),
                      ),
                    ),
                    Text(
                      'one small step at a time.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF3D6C61),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
