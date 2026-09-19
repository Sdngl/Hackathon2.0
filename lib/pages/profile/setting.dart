import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/login.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  bool _medicineAlarms = true;
  bool _appointmentNotifications = true;
  bool _generalNotifications = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      if (!mounted) return;

      setState(() {
        _medicineAlarms =
            (data['medicineAlarms'] ?? data['medicine_alarms']) == true;
        _appointmentNotifications =
            (data['appointmentNotifications'] ??
                data['appointment_notifications']) !=
                false;
        _generalNotifications =
            (data['generalNotifications'] ??
                data['general_notifications']) !=
                false;
        _darkMode = (data['darkMode'] ?? data['dark_mode']) == true;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Could not load settings.');
    }
  }

  Future<void> _saveBool(String field, bool value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set(
      {field: value},
      SetOptions(merge: true),
    );
  }

  Future<void> _editProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!mounted) return;

    final data = doc.data() ?? {};
    final name = TextEditingController(
      text: (data['displayName'] ?? data['name'] ?? user.displayName ?? '')
          .toString(),
    );
    final age = TextEditingController(text: data['age']?.toString() ?? '');
    final city = TextEditingController(
      text: (data['city'] ?? data['location'] ?? '').toString(),
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Edit Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: city,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final nameText = name.text.trim();
                  final ageText = age.text.trim();
                  final cityText = city.text.trim();

                  await _firestore.collection('users').doc(user.uid).set({
                    if (nameText.isNotEmpty) 'displayName': nameText,
                    if (ageText.isNotEmpty) 'age': ageText,
                    if (cityText.isNotEmpty) 'city': cityText,
                  }, SetOptions(merge: true));

                  if (nameText.isNotEmpty) {
                    await user.updateDisplayName(nameText);
                  }

                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext, true);
                  }
                },
                child: const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    age.dispose();
    city.dispose();

    if (saved == true && mounted) _snack('Profile updated.');
  }

  Future<void> _manageEmergencyContact() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!mounted) return;

    final data = doc.data() ?? {};
    final controller = TextEditingController(
      text: (data['emergencyContact'] ??
          data['emergency_contact'] ??
          data['emergencyPhone'] ??
          data['emergency_phone'] ??
          '')
          .toString(),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Emergency contact'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'Phone number'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _firestore.collection('users').doc(user.uid).set({
                'emergencyContact': controller.text.trim(),
              }, SetOptions(merge: true));

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (saved == true && mounted) _snack('Emergency contact updated.');
  }

  Future<void> _sendPasswordReset() async {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      _snack('No email address is available for this account.');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) _snack('Password reset email sent to $email.');
    } catch (_) {
      if (mounted) _snack('Could not send password reset email.');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to access your SEVA account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD92D20),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  void _showInfo(String title, String message) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  height: 1.5,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7F6),
          surfaceTintColor: const Color(0xFFF5F7F6),
          elevation: 0,
          title: const Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17211E),
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            const _SettingsIntro(),
            const SizedBox(height: 24),

            const _Title('Notifications'),
            const SizedBox(height: 10),
            _Card(
              children: [
                _Tile(
                  title: 'Medicine alarms',
                  subtitle: 'Reminder controls for your medicines',
                  trailing: Switch(
                    value: _medicineAlarms,
                    onChanged: (value) {
                      setState(() => _medicineAlarms = value);
                      _saveBool('medicineAlarms', value);
                    },
                  ),
                ),
                _Tile(
                  title: 'Appointment notifications',
                  subtitle: 'Booking and appointment updates',
                  trailing: Switch(
                    value: _appointmentNotifications,
                    onChanged: (value) {
                      setState(() => _appointmentNotifications = value);
                      _saveBool('appointmentNotifications', value);
                    },
                  ),
                ),
                _Tile(
                  title: 'General notifications',
                  subtitle: 'Important SEVA updates',
                  trailing: Switch(
                    value: _generalNotifications,
                    onChanged: (value) {
                      setState(() => _generalNotifications = value);
                      _saveBool('generalNotifications', value);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const _Title('Privacy & Data'),
            const SizedBox(height: 10),
            _Card(
              children: [
                _Tile(
                  title: 'Health data information',
                  subtitle: 'How your saved health information is used',
                  onTap: () => _showInfo(
                    'Health data information',
                    'SEVA stores health information that you choose to save under your signed-in account. Analysis is informational and is not a medical diagnosis.',
                  ),
                ),
                _Tile(
                  title: 'Saved scans / records',
                  subtitle: 'Your saved medicines and medical reports',
                  onTap: () => _showInfo(
                    'Saved scans / records',
                    'Your saved scan results remain linked to your account until they are removed.',
                  ),
                ),
                _Tile(
                  title: 'Account data controls',
                  subtitle: 'More data controls can be added here',
                  onTap: () => _showInfo(
                    'Account data controls',
                    'This section is ready for future export, deletion, and account-data controls.',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const _Title('Account'),
            const SizedBox(height: 10),
            _Card(
              children: [
                _Tile(
                  title: 'Edit profile',
                  subtitle: 'Update your name, age and city',
                  onTap: _editProfile,
                ),
                _Tile(
                  title: 'Emergency contact',
                  subtitle: 'Add or update your emergency phone number',
                  onTap: _manageEmergencyContact,
                ),
                _Tile(
                  title: 'Change password',
                  subtitle: 'Send a password reset email',
                  onTap: _sendPasswordReset,
                ),
              ],
            ),

            const SizedBox(height: 24),
            const _Title('Support'),
            const SizedBox(height: 10),
            _Card(
              children: [
                _Tile(
                  title: 'Help & Support',
                  subtitle: 'FAQs and support information',
                  onTap: () => _showInfo(
                    'Help & Support',
                    'Connect your FAQ and support contact here.',
                  ),
                ),
                _Tile(
                  title: 'Send Feedback',
                  subtitle: 'Help us improve SEVA',
                  onTap: () => _showInfo(
                    'Send Feedback',
                    'You can later connect feedback to Firestore, email, or your Django backend.',
                  ),
                ),
                _Tile(
                  title: 'About SEVA',
                  subtitle: 'Learn more about the app',
                  onTap: () => _showInfo(
                    'About SEVA',
                    'SEVA helps organize saved health information, analyze reports and medicine scans, manage reminders, and connect users with care services.',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const _Title('App Preferences'),
            const SizedBox(height: 10),
            _Card(
              children: [
                _Tile(
                  title: 'Dark theme',
                  subtitle: 'Preference is saved; global theme can be wired later',
                  trailing: Switch(
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() => _darkMode = value);
                      _saveBool('darkMode', value);
                    },
                  ),
                ),
                _Tile(
                  title: 'Other preferences',
                  subtitle: 'More app controls can be added later',
                  onTap: () => _showInfo(
                    'Other preferences',
                    'This space is ready for future app preferences.',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD92D20),
                  backgroundColor: const Color(0xFFFFF7F6),
                  side: const BorderSide(color: Color(0xFFFDA29B)),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsIntro extends StatelessWidget {
  const _SettingsIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F7F2), Color(0xFFF5FBF9)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR PREFERENCES',
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.05,
              fontWeight: FontWeight.w800,
              color: Color(0xFF11786D),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Make SEVA work for you',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17211E),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Manage notifications, privacy, account controls and app preferences.',
            style: TextStyle(
              fontSize: 12.3,
              height: 1.4,
              color: Color(0xFF66736F),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: Color(0xFF17211E),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EAE7)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: Color(0xFFE9EEEC)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17211E),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: Color(0xFF7A8581),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF98A2B3),
                ),
          ],
        ),
      ),
    );
  }
}
