import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../theme/apptheme.dart';
import '../profile/premium_page.dart';
import '../widgets/subscription_card.dart';
import 'doctor_detail_page.dart';

class DoctorGridPage extends StatefulWidget {
  const DoctorGridPage({
    super.key,
  });

  @override
  State<DoctorGridPage> createState() =>
      _DoctorGridPageState();
}

class _DoctorGridPageState extends State<DoctorGridPage> {
  bool _loadingAnalyzed = false;
  bool _analyzedMode = false;
  bool _loadingPremium = true;
  bool _isPremium = false;

  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';
  String _selectedSpecialty = 'All';

  String? _recommendedSpecialty;
  String? _recommendationReason;
  String? _recommendationSource;
  DateTime? _recommendationDate;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPremiumStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isPremium = false;
          _loadingPremium = false;
        });
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snapshot.data() ?? <String, dynamic>{};

      final isPaid = data['isPaid'] == true;
      final expiresRaw = data['subscriptionExpiresAt'];

      DateTime? expiresAt;
      if (expiresRaw is Timestamp) {
        expiresAt = expiresRaw.toDate();
      } else if (expiresRaw is DateTime) {
        expiresAt = expiresRaw;
      } else if (expiresRaw is String) {
        expiresAt = DateTime.tryParse(expiresRaw);
      }

      final activePremium =
          isPaid &&
              expiresAt != null &&
              expiresAt.isAfter(DateTime.now());

      if (!mounted) return;

      setState(() {
        _isPremium = activePremium;
        _loadingPremium = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isPremium = false;
        _loadingPremium = false;
      });
    }
  }

  Future<void> _showPremiumDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              22,
              24,
              22,
              18,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3DD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 34,
                    color: Color(0xFFE69B19),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Premium Feature',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Analyze Doctor Match is available with an active SEVA Premium subscription.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 18),
                const _PremiumBenefit(
                  icon: Icons.auto_awesome_rounded,
                  text: 'Match doctors with your saved analyzed report',
                  tint: Color(0xFFE7F7F1),
                  iconColor: Color(0xFF11786D),
                ),
                const SizedBox(height: 10),
                const _PremiumBenefit(
                  icon: Icons.description_outlined,
                  text: 'Use the specialist recommendation already stored in your report',
                  tint: Color(0xFFE9F1FF),
                  iconColor: Color(0xFF3977E3),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PremiumPage(
                            onSubscribe: (SubscriptionPlan plan) async {
                              // Navigation from Doctor Grid is connected.
                              // The Premium page opens correctly from this popup.
                            },
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF11786D),
                      foregroundColor: Colors.white,
                      minimumSize:
                      const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'View Premium',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toast(
      String message,
      ) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<void> _handleAnalyzed() async {
    if (_loadingAnalyzed || _loadingPremium) {
      return;
    }

    if (_analyzedMode) {
      setState(() {
        _analyzedMode = false;
        _recommendedSpecialty = null;
        _recommendationReason = null;
        _recommendationSource = null;
        _recommendationDate = null;
      });

      _toast(
        'Showing all doctors.',
      );

      return;
    }

    if (!_isPremium) {
      await _showPremiumDialog();
      return;
    }

    await _loadLatestDoctorRecommendation();
  }

  Future<void> _loadLatestDoctorRecommendation() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _toast(
        'Please sign in to use analyzed recommendations.',
      );

      return;
    }

    setState(() {
      _loadingAnalyzed = true;
    });

    try {
      final snapshot =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .where(
        'status',
        isEqualTo: 'completed',
      )
          .get();

      if (!mounted) {
        return;
      }

      if (snapshot.docs.isEmpty) {
        _toast(
          'Analyze a medical report first to get doctor recommendations.',
        );

        return;
      }

      final reports =
      snapshot.docs.toList();

      reports.sort(
            (
            a,
            b,
            ) {
          final aDate =
          _reportDate(
            a.data(),
          );

          final bDate =
          _reportDate(
            b.data(),
          );

          return bDate.compareTo(
            aDate,
          );
        },
      );

      Map<String, dynamic>?
      selectedRecommendation;

      Map<String, dynamic>?
      selectedReport;

      for (final document in reports) {
        final raw =
        document.data();

        final analysisRaw =
        raw['analysis'];

        if (analysisRaw is! Map) {
          continue;
        }

        final analysis =
        Map<String, dynamic>.from(
          analysisRaw,
        );

        final recommendation =
        _extractRecommendation(
          analysis,
        );

        if (recommendation == null) {
          continue;
        }

        final needed =
        recommendation['needed'];

        if (needed is bool &&
            !needed) {
          continue;
        }

        final specialty =
        _firstText(
          [
            recommendation[
            'speciality'],
            recommendation[
            'specialty'],
          ],
        );

        if (specialty == null) {
          continue;
        }

        selectedRecommendation =
            recommendation;

        selectedReport =
            raw;

        break;
      }

      if (!mounted) {
        return;
      }

      if (selectedRecommendation ==
          null ||
          selectedReport == null) {
        _toast(
          'No specialist recommendation was found in your analyzed reports.',
        );

        return;
      }

      final specialty =
      _firstText(
        [
          selectedRecommendation[
          'speciality'],
          selectedRecommendation[
          'specialty'],
        ],
      );

      if (specialty == null) {
        _toast(
          'The analyzed report did not contain a specialist recommendation.',
        );

        return;
      }

      final reason =
      _firstText(
        [
          selectedRecommendation[
          'reason'],
        ],
      );

      final analysisRaw =
      selectedReport['analysis'];

      final analysis =
      analysisRaw is Map
          ? Map<String, dynamic>.from(
        analysisRaw,
      )
          : <String, dynamic>{};

      final reportRaw =
      analysis['report'];

      final report =
      reportRaw is Map
          ? Map<String, dynamic>.from(
        reportRaw,
      )
          : <String, dynamic>{};

      final reportTitle =
      _firstText(
        [
          report['title'],
          report['report_type'],
          selectedReport[
          'fileName'],
        ],
      );

      setState(() {
        _analyzedMode = true;

        _recommendedSpecialty =
            specialty;

        _recommendationReason =
            reason;

        _recommendationSource =
            reportTitle ??
                'Analyzed report';

        _recommendationDate =
            _reportDate(
              selectedReport!,
            );
      });

      _toast(
        'Showing doctors recommended from your analyzed report.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _toast(
        'Could not load analyzed doctor recommendations.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingAnalyzed = false;
        });
      }
    }
  }

  Map<String, dynamic>?
  _extractRecommendation(
      Map<String, dynamic> analysis,
      ) {
    final value =
    analysis[
    'doctor_recommendation'];

    if (value is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(
      value,
    );
  }

  bool _doctorMatchesRecommendation(
      Doctor doctor,
      ) {
    if (!_analyzedMode ||
        _recommendedSpecialty ==
            null) {
      return true;
    }

    final doctorSpecialties =
    <String>[
      doctor.specialization,
      ...doctor.specialties,
    ];

    for (final specialty
    in doctorSpecialties) {
      if (_specialtyMatches(
        specialty,
        _recommendedSpecialty!,
      )) {
        return true;
      }
    }

    return false;
  }

  bool _specialtyMatches(
      String doctorSpecialty,
      String recommendedSpecialty,
      ) {
    final doctor =
    _normalizeSpecialty(
      doctorSpecialty,
    );

    final recommended =
    _normalizeSpecialty(
      recommendedSpecialty,
    );

    if (doctor ==
        recommended ||
        doctor.contains(
          recommended,
        ) ||
        recommended.contains(
          doctor,
        )) {
      return true;
    }

    const aliases =
    <String, String>{
      'general medicine':
      'general',
      'general physician':
      'general',
      'internal medicine':
      'general',

      'cardiologist':
      'cardiology',

      'dermatologist':
      'dermatology',

      'endocrinologist':
      'endocrinology',

      'gastroenterologist':
      'gastroenterology',

      'orthopedic':
      'orthopedics',
      'orthopaedic':
      'orthopedics',

      'pediatrician':
      'pediatrics',
      'paediatrician':
      'pediatrics',

      'gynecologist':
      'gynecology',
      'gynaecologist':
      'gynecology',

      'ophthalmologist':
      'ophthalmology',

      'ent specialist':
      'ent',
    };

    final doctorAlias =
        aliases[doctor] ??
            doctor;

    final recommendedAlias =
        aliases[recommended] ??
            recommended;

    return doctorAlias ==
        recommendedAlias;
  }

  String _normalizeSpecialty(
      String value,
      ) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    );
  }

  DateTime _reportDate(
      Map<String, dynamic> data,
      ) {
    final createdAt =
    data['createdAt'];

    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
  }

  String? _firstText(
      List<dynamic> values,
      ) {
    for (final value in values) {
      final text =
      value
          ?.toString()
          .trim();

      if (text != null &&
          text.isNotEmpty &&
          text.toLowerCase() !=
              'null') {
        return text;
      }
    }

    return null;
  }

  DoctorRecommendationContext?
  _recommendationContext() {
    if (!_analyzedMode ||
        _recommendedSpecialty ==
            null) {
      return null;
    }

    final reason =
        _recommendationReason;

    return DoctorRecommendationContext(
      reason: reason != null &&
          reason.trim().isNotEmpty
          ? reason
          : 'Your analyzed report recommended $_recommendedSpecialty for professional review.',
      sourceLabel:
      _recommendationSource ??
          'Analyzed report',
      sourceDate:
      _recommendationDate,
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          _analyzedMode
              ? 'Recommended Doctors'
              : 'Find a Doctor',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
        (_loadingAnalyzed || _loadingPremium)
            ? null
            : _handleAnalyzed,
        tooltip: _analyzedMode
            ? 'Show all doctors'
            : 'Analyze doctor match',
        backgroundColor: _analyzedMode
            ? const Color(0xFF11786D)
            : const Color(0xFF7357D6),
        foregroundColor: Colors.white,
        child: _loadingAnalyzed || _loadingPremium
            ? const SizedBox(
          width: 21,
          height: 21,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Colors.white,
          ),
        )
            : Icon(
          _analyzedMode
              ? Icons.close_rounded
              : Icons.auto_awesome_rounded,
          size: 25,
        ),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.endFloat,
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .where(
          'isActive',
          isEqualTo: true,
        )
            .snapshots(),
        builder: (
            context,
            snapshot,
            ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
            );
          }

          final allDocuments =
              snapshot.data?.docs ?? [];

          final allDoctors = allDocuments
              .map(
                (document) => Doctor.fromFirestore(
              id: document.id,
              data: document.data(),
            ),
          )
              .toList();

          final specialtySet = <String>{};

          for (final doctor in allDoctors) {
            final primary =
            doctor.specialization.trim();

            if (primary.isNotEmpty &&
                primary.toLowerCase() !=
                    'specialist') {
              specialtySet.add(primary);
            }

            for (final specialty
            in doctor.specialties) {
              final value = specialty.trim();

              if (value.isNotEmpty) {
                specialtySet.add(value);
              }
            }
          }

          final specialties =
          specialtySet.toList()
            ..sort(
                  (a, b) => a
                  .toLowerCase()
                  .compareTo(
                b.toLowerCase(),
              ),
            );

          final doctors = allDoctors.where(
                (doctor) {
              if (!_doctorMatchesRecommendation(
                doctor,
              )) {
                return false;
              }

              final normalizedQuery =
              _searchQuery
                  .trim()
                  .toLowerCase();

              if (normalizedQuery.isNotEmpty) {
                final searchable = <String>[
                  doctor.name,
                  doctor.specialization,
                  doctor.hospital,
                  ...doctor.specialties,
                ].join(' ').toLowerCase();

                if (!searchable.contains(
                  normalizedQuery,
                )) {
                  return false;
                }
              }

              if (_selectedSpecialty != 'All') {
                final candidateSpecialties =
                <String>[
                  doctor.specialization,
                  ...doctor.specialties,
                ];

                final matches = candidateSpecialties
                    .any(
                      (value) =>
                      _specialtyMatches(
                        value,
                        _selectedSpecialty,
                      ),
                );

                if (!matches) {
                  return false;
                }
              }

              return true;
            },
          ).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                FirebaseFirestore.instance
                    .collection('doctors')
                    .where(
                  'isActive',
                  isEqualTo: true,
                )
                    .get(),
                _loadPremiumStatus(),
              ]);
            },
            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                104,
              ),
              children: [
                const Text(
                  'Find the right care for you',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  textInputAction:
                  TextInputAction.search,
                  decoration: InputDecoration(
                    hintText:
                    'Search doctors, specialties...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                    ),
                    suffixIcon:
                    _searchQuery.isEmpty
                        ? null
                        : IconButton(
                      onPressed: () {
                        _searchController
                            .clear();

                        setState(() {
                          _searchQuery =
                          '';
                        });
                      },
                      icon: const Icon(
                        Icons
                            .close_rounded,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                      BorderSide.none,
                    ),
                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                      const BorderSide(
                        color: Color(
                          0xFFE6ECE9,
                        ),
                      ),
                    ),
                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                      const BorderSide(
                        color:
                        AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection:
                    Axis.horizontal,
                    itemCount:
                    specialties.length + 1,
                    separatorBuilder:
                        (_, __) =>
                    const SizedBox(
                      width: 8,
                    ),
                    itemBuilder:
                        (context, index) {
                      final specialty =
                      index == 0
                          ? 'All'
                          : specialties[
                      index - 1];

                      final selected =
                          _selectedSpecialty ==
                              specialty;

                      return ChoiceChip(
                        label: Text(
                          specialty,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                        ),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedSpecialty =
                                specialty;
                          });
                        },
                        showCheckmark: false,
                        backgroundColor:
                        Colors.white,
                        selectedColor:
                        AppColors.primary,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : const Color(
                            0xFFE6ECE9,
                          ),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12.2,
                          fontWeight:
                          FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : AppColors
                              .textDark,
                        ),
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 10,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_analyzedMode &&
                    _recommendedSpecialty !=
                        null) ...[
                  const SizedBox(height: 14),
                  _RecommendationBanner(
                    specialty:
                    _recommendedSpecialty!,
                    source:
                    _recommendationSource,
                    onClose: _handleAnalyzed,
                  ),
                ],
                const SizedBox(height: 14),
                if (doctors.isEmpty)
                  Padding(
                    padding:
                    const EdgeInsets.only(
                      top: 54,
                    ),
                    child: _analyzedMode &&
                        _recommendedSpecialty !=
                            null
                        ? _NoRecommendedDoctorState(
                      specialty:
                      _recommendedSpecialty!,
                    )
                        : const _EmptyState(),
                  )
                else
                  ...List.generate(
                    doctors.length,
                        (index) {
                      final doctor =
                      doctors[index];

                      return Padding(
                        padding:
                        EdgeInsets.only(
                          bottom:
                          index ==
                              doctors.length -
                                  1
                              ? 0
                              : 12,
                        ),
                        child: DoctorCard(
                          doctor: doctor,
                          onTap: () {
                            Navigator.of(
                              context,
                            ).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DoctorDetailsPage(
                                      doctor: doctor,
                                      recommendation:
                                      _recommendationContext(),
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
  });

  String? _availabilityText() {
    if (doctor.availableSlots.isEmpty) {
      return null;
    }

    if (doctor.availableSlots.length == 1) {
      return doctor.availableSlots.first;
    }

    return '${doctor.availableSlots.first} - ${doctor.availableSlots.last}';
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final timeText = _availabilityText();

    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final width = constraints.maxWidth;
        final compact = width < 350;
        final imageWidth =
        (width * 0.34)
            .clamp(
          112.0,
          148.0,
        )
            .toDouble();

        return Material(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(22),
          child: InkWell(
            onTap: onTap,
            borderRadius:
            BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight:
                compact ? 188 : 202,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(
                    0xFFE8ECEA,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.035),
                    blurRadius: 18,
                    offset:
                    const Offset(0, 7),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: imageWidth,
                    child: _DoctorImage(
                      imageUrl:
                      doctor.imageUrl,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 14 : 16,
                      compact ? 14 : 16,
                      imageWidth - 10,
                      compact ? 13 : 15,
                    ),
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          doctor.name,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style: TextStyle(
                            fontSize:
                            compact
                                ? 17
                                : 18.5,
                            fontWeight:
                            FontWeight
                                .w900,
                            color: AppColors
                                .textDark,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          doctor
                              .specialization,
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style: TextStyle(
                            fontSize:
                            compact
                                ? 12
                                : 12.8,
                            color: AppColors
                                .textMuted,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),
                        SizedBox(
                          height:
                          compact
                              ? 12
                              : 14,
                        ),
                        if (doctor.rating !=
                            null)
                          _DoctorMetaRow(
                            icon: Icons
                                .star_rounded,
                            text: doctor
                                .reviewCount !=
                                null
                                ? '${doctor.rating!.toStringAsFixed(1)} (${doctor.reviewCount} reviews)'
                                : doctor.rating!
                                .toStringAsFixed(
                              1,
                            ),
                          ),
                        if (doctor.rating !=
                            null &&
                            doctor
                                .experienceYears !=
                                null)
                          const SizedBox(
                            height: 6,
                          ),
                        if (doctor
                            .experienceYears !=
                            null)
                          _DoctorMetaRow(
                            icon: Icons
                                .person_outline_rounded,
                            text:
                            '${doctor.experienceYears} year${doctor.experienceYears == 1 ? '' : 's'} experience',
                          ),
                        if (timeText != null) ...[
                          const SizedBox(
                            height: 6,
                          ),
                          _DoctorMetaRow(
                            icon: Icons
                                .schedule_rounded,
                            text: timeText,
                          ),
                        ],
                        SizedBox(
                          height:
                          compact
                              ? 13
                              : 15,
                        ),
                        SizedBox(
                          width:
                          compact
                              ? 170
                              : 190,
                          height:
                          compact
                              ? 40
                              : 42,
                          child: FilledButton(
                            onPressed: onTap,
                            style:
                            FilledButton
                                .styleFrom(
                              backgroundColor:
                              doctor.available
                                  ? const Color(
                                0xFF119483,
                              )
                                  : const Color(
                                0xFF9AA6A2,
                              ),
                              foregroundColor:
                              Colors.white,
                              disabledBackgroundColor:
                              const Color(
                                0xFFB8C1BE,
                              ),
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  22,
                                ),
                              ),
                              elevation: 0,
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 14,
                              ),
                            ),
                            child: Text(
                              doctor.available
                                  ? 'Book Now'
                                  : 'View Doctor',
                              style:
                              const TextStyle(
                                fontSize: 13.5,
                                fontWeight:
                                FontWeight
                                    .w800,
                              ),
                            ),
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

class _DoctorMetaRow
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DoctorMetaRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color:
          const Color(0xFF4C9CB7),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              color:
              AppColors.textMuted,
              fontWeight:
              FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationBanner
    extends StatelessWidget {
  final String specialty;
  final String? source;
  final VoidCallback onClose;

  const _RecommendationBanner({
    required this.specialty,
    required this.source,
    required this.onClose,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        14,
        13,
        10,
        13,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFE4F8F4),
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Padding(
            padding:
            EdgeInsets.only(
              top: 2,
            ),
            child: Icon(
              Icons
                  .auto_awesome_rounded,
              size: 23,
              color:
              Color(0xFF11786D),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Showing recommended doctors',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF11786D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  source == null
                      ? 'Based on your latest analyzed report'
                      : 'Based on $source',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color:
                    AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Specialist: $specialty',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF0C786A),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            visualDensity:
            VisualDensity.compact,
            tooltip:
            'Show all doctors',
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color:
              AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBenefit
    extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color tint;
  final Color iconColor;

  const _PremiumBenefit({
    required this.icon,
    required this.text,
    required this.tint,
    required this.iconColor,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint,
            borderRadius:
            BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            size: 21,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color:
              AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _DoctorImage extends StatelessWidget {
  final String imageUrl;

  const _DoctorImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final value = imageUrl.trim();

    if (value.isEmpty) {
      return _fallback();
    }

    // Base64 data URI, e.g. data:image/jpeg;base64,/9j/4AAQ...
    if (_isBase64DataUri(value)) {
      return _buildBase64Image(value);
    }

    // Normal network URL.
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _fallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          return Container(
            color: AppColors.accentLight,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        },
      );
    }

    // Raw Base64 string stored directly in Firestore.
    if (_looksLikeRawBase64(value)) {
      return _buildBase64Image(value);
    }

    return _fallback();
  }

  Widget _buildBase64Image(String value) {
    try {
      final cleaned = _extractAndNormalizeBase64(value);
      final bytes = base64Decode(cleaned);

      if (bytes.isEmpty) {
        return _fallback();
      }

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    } catch (_) {
      return _fallback();
    }
  }

  bool _isBase64DataUri(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('data:image/') && lower.contains(';base64,');
  }

  bool _looksLikeRawBase64(String value) {
    var cleaned = value.replaceAll(RegExp(r'\s'), '');

    if (cleaned.length < 100) {
      return false;
    }

    // Support URL-safe Base64 as well.
    cleaned = cleaned.replaceAll('-', '+').replaceAll('_', '/');

    if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(cleaned)) {
      return false;
    }

    try {
      final normalized = _addBase64Padding(cleaned);
      return base64Decode(normalized).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _extractAndNormalizeBase64(String value) {
    var raw = value.trim();

    if (_isBase64DataUri(raw)) {
      final commaIndex = raw.indexOf(',');
      if (commaIndex == -1 || commaIndex == raw.length - 1) {
        throw const FormatException('Invalid Base64 image data URI');
      }
      raw = raw.substring(commaIndex + 1);
    }

    raw = raw
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll('-', '+')
        .replaceAll('_', '/');

    return _addBase64Padding(raw);
  }

  String _addBase64Padding(String value) {
    final remainder = value.length % 4;
    if (remainder == 0) return value;
    return value.padRight(value.length + (4 - remainder), '=');
  }

  Widget _fallback() {
    return Container(
      color: AppColors.accentLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_rounded,
        size: 64,
        color: AppColors.primary,
      ),
    );
  }
}

class _NoRecommendedDoctorState
    extends StatelessWidget {
  final String specialty;

  const _NoRecommendedDoctorState({
    required this.specialty,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .medical_services_outlined,
              size: 58,
              color:
              AppColors.primary,
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              'No $specialty doctors available',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight
                    .w800,
                color:
                AppColors
                    .textDark,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'There are currently no active doctors matching this report recommendation.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize: 13,
                color:
                AppColors
                    .textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState
    extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(
      BuildContext context,
      ) {
    return const Center(
      child: Padding(
        padding:
        EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .medical_services_outlined,
              size: 58,
              color:
              AppColors.primary,
            ),
            SizedBox(
              height: 14,
            ),
            Text(
              'No doctors available',
              style:
              TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight
                    .w800,
                color:
                AppColors
                    .textDark,
              ),
            ),
            SizedBox(
              height: 6,
            ),
            Text(
              'Doctors added by the admin will appear here.',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize: 13,
                color:
                AppColors
                    .textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              size: 54,
              color:
              Colors.redAccent,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Could not load doctors',
              style:
              TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight
                    .w800,
                color:
                AppColors
                    .textDark,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              message,
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 12.5,
                color:
                AppColors
                    .textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
