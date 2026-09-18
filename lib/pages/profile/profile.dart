import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/apptheme.dart';
import '../widgets/subscription_card.dart';

class _Tint {
  final Color bg;
  final Color fg;

  const _Tint(
      this.bg,
      this.fg,
      );
}

const _green = _Tint(
  Color(0xFFE3F5EF),
  Color(0xFF0F7B64),
);

const _amber = _Tint(
  Color(0xFFFFF3D6),
  Color(0xFFD98E04),
);

const _blue = _Tint(
  Color(0xFFE5EEFD),
  Color(0xFF3B74E0),
);

const _red = _Tint(
  Color(0xFFFDE8E8),
  Color(0xFFE0474C),
);

const _purple = _Tint(
  Color(0xFFEDE9FE),
  Color(0xFF7C5CE0),
);

const _orange = _Tint(
  Color(0xFFFDEBE4),
  Color(0xFFE0663B),
);

const _slate = _Tint(
  Color(0xFFEAEFF3),
  Color(0xFF52606D),
);

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _loading = true;

  Map<String, dynamic> _profile = {};

  int _medicineCount = 0;
  int _reportCount = 0;

  bool _medicineAlarms = true;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      return;
    }

    try {
      final userRef =
      _firestore
          .collection('users')
          .doc(user.uid);

      final userSnapshot =
      await userRef.get();

      final medicineSnapshot =
      await userRef
          .collection('medicines')
          .get();

      final reportSnapshot =
      await userRef
          .collection('reports')
          .get();

      if (!mounted) return;

      setState(() {
        _profile =
            userSnapshot.data() ?? {};

        _medicineCount =
            medicineSnapshot.docs.length;

        _reportCount =
            reportSnapshot.docs.length;

        _medicineAlarms =
            _readBool(
              _profile,
              [
                'medicineAlarms',
                'medicine_alarms',
              ],
            ) ??
                true;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not load profile: $e',
          ),
        ),
      );
    }
  }

  dynamic _readValue(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];

        if (value != null &&
            value.toString().trim().isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  String? _readString(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    final value =
    _readValue(
      data,
      keys,
    );

    if (value == null) {
      return null;
    }

    return value
        .toString()
        .trim();
  }

  double? _readDouble(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    final value =
    _readValue(
      data,
      keys,
    );

    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  bool? _readBool(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    final value =
    _readValue(
      data,
      keys,
    );

    if (value is bool) {
      return value;
    }

    return null;
  }

  String get _name {
    final firestoreName =
    _readString(
      _profile,
      [
        'displayName',
        'display_name',
        'name',
        'fullName',
        'full_name',
      ],
    );

    if (firestoreName != null) {
      return firestoreName;
    }

    final authName =
    _auth.currentUser
        ?.displayName
        ?.trim();

    if (authName != null &&
        authName.isNotEmpty) {
      return authName;
    }

    return 'User';
  }

  String? get _email {
    final firestoreEmail =
    _readString(
      _profile,
      [
        'email',
      ],
    );

    return firestoreEmail ??
        _auth.currentUser?.email;
  }

  String get _initials {
    final parts = _name
        .trim()
        .split(
      RegExp(r'\s+'),
    )
        .where(
          (part) =>
      part.isNotEmpty,
    )
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
  }

  String? get _city {
    return _readString(
      _profile,
      [
        'city',
        'location',
      ],
    );
  }

  String? get _age {
    final age = _readValue(
      _profile,
      [
        'age',
      ],
    );

    if (age == null) {
      return null;
    }

    return age.toString();
  }

  double? get _height {
    return _readDouble(
      _profile,
      [
        'heightCm',
        'height_cm',
        'height',
      ],
    );
  }

  double? get _weight {
    return _readDouble(
      _profile,
      [
        'weightKg',
        'weight_kg',
        'weight',
      ],
    );
  }

  String? get _bloodGroup {
    return _readString(
      _profile,
      [
        'bloodGroup',
        'blood_group',
      ],
    );
  }

  String? get _bmi {
    final height = _height;
    final weight = _weight;

    if (height == null ||
        weight == null ||
        height <= 0) {
      return null;
    }

    final meters =
        height / 100;

    final bmi =
        weight /
            (meters * meters);

    return bmi
        .toStringAsFixed(1);
  }

  List<String> get _healthContext {
    final value =
        _profile['healthContext'] ??
            _profile[
            'health_context'];

    if (value is! List) {
      return [];
    }

    return value
        .where(
          (item) =>
      item != null &&
          item
              .toString()
              .trim()
              .isNotEmpty,
    )
        .map(
          (item) =>
          item
              .toString()
              .trim(),
    )
        .toList();
  }

  Future<void>
  _updateMedicineAlarms(
      bool value,
      ) async {
    final user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _medicineAlarms =
          value;
    });

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'medicineAlarms':
          value,
        },
        SetOptions(
          merge: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _medicineAlarms =
        !value;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not update medicine alarms.',
          ),
        ),
      );
    }
  }

  void _snack(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return AnnotatedRegion<
        SystemUiOverlayStyle>(
      value:
      SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: _loading
              ? const Center(
            child:
            CircularProgressIndicator(),
          )
              : RefreshIndicator(
            onRefresh:
            _loadProfile,
            child:
            SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding:
              const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                120,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  _Header(
                    name: _name,
                    initials:
                    _initials,
                    age:
                    _age,
                    city:
                    _city,
                    email:
                    _email,
                    onSettings:
                        () {
                      _snack(
                        'Settings coming soon',
                      );
                    },
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  _StatsCard(
                    height:
                    _height,
                    weight:
                    _weight,
                    bloodGroup:
                    _bloodGroup,
                    bmi:
                    _bmi,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  SubscriptionCard(
                    recommendedId:
                    'half_year',
                    onSubscribe:
                        (plan) {
                      _snack(
                        'Selected ${plan.title} plan',
                      );
                    },
                  ),

                  if (_healthContext
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 22,
                    ),

                    const Text(
                      'Health context',
                      style:
                      TextStyle(
                        fontSize:
                        15,
                        fontWeight:
                        FontWeight
                            .w700,
                        color:
                        AppColors
                            .textDark,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                      _healthContext
                          .map(
                            (
                            item,
                            ) {
                          return _TagChip(
                            text:
                            item,
                            tint:
                            _green,
                          );
                        },
                      ).toList(),
                    ),
                  ],

                  const SizedBox(
                    height: 18,
                  ),

                  _MenuCard(
                    children: [
                      _MenuTile(
                        icon: Icons
                            .medication_outlined,
                        tint:
                        _amber,
                        title:
                        'My medications',
                        subtitle:
                        _medicineCount ==
                            0
                            ? 'No saved medicines'
                            : '$_medicineCount saved medicine${_medicineCount == 1 ? '' : 's'}',
                        onTap:
                            () {},
                      ),

                      _MenuTile(
                        icon: Icons
                            .description_outlined,
                        tint:
                        _blue,
                        title:
                        'Medical records',
                        subtitle:
                        _reportCount ==
                            0
                            ? 'No reports stored'
                            : '$_reportCount report${_reportCount == 1 ? '' : 's'} stored',
                        onTap:
                            () {},
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _MenuCard(
                    children: [
                      _MenuTile(
                        icon: Icons
                            .notifications_none_rounded,
                        tint:
                        _purple,
                        title:
                        'Medicine alarms',
                        trailing:
                        _Toggle(
                          value:
                          _medicineAlarms,
                          onChanged:
                          _updateMedicineAlarms,
                        ),
                      ),

                      _MenuTile(
                        icon: Icons
                            .phone_outlined,
                        tint:
                        _orange,
                        title:
                        'Emergency contact',
                        subtitle:
                        _readString(
                          _profile,
                          [
                            'emergencyContact',
                            'emergency_contact',
                            'emergencyPhone',
                            'emergency_phone',
                          ],
                        ),
                        onTap:
                            () {},
                      ),

                      _MenuTile(
                        icon: Icons
                            .shield_outlined,
                        tint:
                        _slate,
                        title:
                        'Privacy & data',
                        subtitle:
                        'Your saved health data is protected by your account',
                        onTap:
                            () {},
                      ),
                    ],
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

class _Header
    extends StatelessWidget {
  final String name;
  final String initials;
  final String? age;
  final String? city;
  final String? email;
  final VoidCallback onSettings;

  const _Header({
    required this.name,
    required this.initials,
    required this.age,
    required this.city,
    required this.email,
    required this.onSettings,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final details =
    <String>[];

    if (age != null &&
        age!.isNotEmpty) {
      details.add(
        '$age yrs',
      );
    }

    if (city != null &&
        city!.isNotEmpty) {
      details.add(city!);
    }

    return Stack(
      children: [
        Align(
          alignment:
          Alignment.topRight,
          child: Material(
            color: Colors.white,
            shape:
            const CircleBorder(),
            child: InkWell(
              customBorder:
              const CircleBorder(),
              onTap:
              onSettings,
              child:
              const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons
                      .settings_outlined,
                  size: 22,
                  color: AppColors
                      .textDark,
                ),
              ),
            ),
          ),
        ),

        Center(
          child: Column(
            children: [
              const SizedBox(
                height: 18,
              ),

              Container(
                width: 92,
                height: 92,
                decoration:
                BoxDecoration(
                  color: AppColors
                      .accentLight,
                  shape:
                  BoxShape.circle,
                  border:
                  Border.all(
                    color:
                    Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors
                          .black
                          .withValues(
                        alpha: 0.06,
                      ),
                      blurRadius:
                      16,
                      offset:
                      const Offset(
                        0,
                        6,
                      ),
                    ),
                  ],
                ),
                alignment:
                Alignment.center,
                child: Text(
                  initials,
                  style:
                  const TextStyle(
                    fontSize: 30,
                    fontWeight:
                    FontWeight
                        .w800,
                    color: AppColors
                        .primary,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                name,
                style:
                const TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight
                      .w800,
                  letterSpacing:
                  -0.3,
                  color: AppColors
                      .textDark,
                ),
              ),

              if (details
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 4,
                ),
                Text(
                  details.join(
                    ' · ',
                  ),
                  style:
                  const TextStyle(
                    fontSize: 13.5,
                    color: AppColors
                        .textMuted,
                  ),
                ),
              ] else if (email !=
                  null) ...[
                const SizedBox(
                  height: 4,
                ),
                Text(
                  email!,
                  style:
                  const TextStyle(
                    fontSize: 13,
                    color: AppColors
                        .textMuted,
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

class _StatsCard
    extends StatelessWidget {
  final double? height;
  final double? weight;
  final String? bloodGroup;
  final String? bmi;

  const _StatsCard({
    required this.height,
    required this.weight,
    required this.bloodGroup,
    required this.bmi,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final stats =
    <({String value, String label})>[];

    if (height != null) {
      stats.add(
        (
        value:
        height!
            .toStringAsFixed(
          height! %
              1 ==
              0
              ? 0
              : 1,
        ),
        label: 'cm',
        ),
      );
    }

    if (weight != null) {
      stats.add(
        (
        value:
        weight!
            .toStringAsFixed(
          weight! %
              1 ==
              0
              ? 0
              : 1,
        ),
        label: 'kg',
        ),
      );
    }

    if (bloodGroup != null) {
      stats.add(
        (
        value:
        bloodGroup!,
        label: 'blood',
        ),
      );
    }

    if (bmi != null) {
      stats.add(
        (
        value: bmi!,
        label: 'BMI',
        ),
      );
    }

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 16,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        children: [
          for (final stat
          in stats)
            Expanded(
              child: Column(
                children: [
                  Text(
                    stat.value,
                    style:
                    const TextStyle(
                      fontSize:
                      18,
                      fontWeight:
                      FontWeight
                          .w800,
                      color:
                      AppColors
                          .textDark,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    stat.label,
                    style:
                    const TextStyle(
                      fontSize:
                      12,
                      color:
                      AppColors
                          .textMuted,
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

class _TagChip
    extends StatelessWidget {
  final String text;
  final _Tint tint;

  const _TagChip({
    required this.text,
    required this.tint,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color: tint.bg,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight:
          FontWeight.w600,
          color: tint.fg,
        ),
      ),
    );
  }
}

class _MenuCard
    extends StatelessWidget {
  final List<Widget> children;

  const _MenuCard({
    required this.children,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          24,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0;
          i <
              children.length;
          i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                color:
                Color(
                  0xFFE8ECEA,
                ),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuTile
    extends StatelessWidget {
  final IconData icon;
  final _Tint tint;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.tint,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration:
              BoxDecoration(
                color: tint.bg,
                borderRadius:
                BorderRadius.circular(
                  11,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: tint.fg,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    title,
                    style:
                    const TextStyle(
                      fontSize:
                      15.5,
                      fontWeight:
                      FontWeight
                          .w500,
                      color:
                      AppColors
                          .textDark,
                    ),
                  ),

                  if (subtitle !=
                      null &&
                      subtitle!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      subtitle!,
                      style:
                      const TextStyle(
                        fontSize:
                        12.5,
                        color:
                        AppColors
                            .textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            trailing ??
                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                  AppColors
                      .label,
                  size: 24,
                ),
          ],
        ),
      ),
    );
  }
}

class _Toggle
    extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>
  onChanged;

  const _Toggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor:
      Colors.white,
      activeTrackColor:
      AppColors.primary,
      inactiveThumbColor:
      Colors.white,
      inactiveTrackColor:
      const Color(
        0xFFD5DBD9,
      ),
      trackOutlineColor:
      WidgetStateProperty.all(
        Colors.transparent,
      ),
    );
  }
}