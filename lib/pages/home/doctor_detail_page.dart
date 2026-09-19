import 'package:flutter/material.dart';

import '../theme/apptheme.dart';
import 'consultation_booking_page.dart';

class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String hospital;
  final String imageUrl;

  final String? qualification;
  final String? about;

  final double? rating;
  final int? reviewCount;
  final int? experienceYears;
  final int? patientCount;

  final num? consultationFee;

  final bool available;
  final bool isActive;
  final bool verified;

  final List<String> specialties;
  final List<String> languages;
  final List<String> availableSlots;

  final String? clinicName;
  final String? clinicAddress;
  final String? clinicHours;

  final String? phone;
  final String? email;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.hospital,
    required this.imageUrl,
    required this.qualification,
    required this.about,
    required this.rating,
    required this.reviewCount,
    required this.experienceYears,
    required this.patientCount,
    required this.consultationFee,
    required this.available,
    required this.isActive,
    required this.verified,
    required this.specialties,
    required this.languages,
    required this.availableSlots,
    required this.clinicName,
    required this.clinicAddress,
    required this.clinicHours,
    required this.phone,
    required this.email,
  });

  factory Doctor.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final specializationList = _stringList(
      data['specialization'],
    );

    final legacySpecialization = _stringValue(
      data['specialization'],
    );

    final specialtyList = <String>{
      ...specializationList,
      ..._stringList(
        data['specialties'],
      ),
    }.toList();

    final specializationText = specializationList.isNotEmpty
        ? specializationList.join(' · ')
        : legacySpecialization ?? 'Specialist';

    return Doctor(
      id: id,
      name: _stringValue(
        data['name'],
      ) ??
          'Doctor',
      specialization: specializationText,
      hospital: _stringValue(
        data['hospital'],
      ) ??
          '',
      imageUrl: _stringValue(
        data['imageUrl'],
      ) ??
          '',
      qualification: _stringValue(
        data['qualification'],
      ),
      about: _stringValue(
        data['about'],
      ),
      rating: _doubleValue(
        data['rating'],
      ),
      reviewCount: _intValue(
        data['reviewCount'],
      ),
      experienceYears: _intValue(
        data['experienceYears'],
      ),
      patientCount: _intValue(
        data['patientCount'],
      ),
      consultationFee: _numberValue(
        data['consultationFee'],
      ),
      available: data['available'] is bool
          ? data['available'] as bool
          : false,
      isActive: data['isActive'] is bool
          ? data['isActive'] as bool
          : true,
      verified: data['verified'] is bool
          ? data['verified'] as bool
          : false,
      specialties: specialtyList,
      languages: _stringList(
        data['languages'],
      ),
      availableSlots: _stringList(
        data['availableSlots'],
      ),
      clinicName: _stringValue(
        data['clinicName'],
      ),
      clinicAddress: _stringValue(
        data['clinicAddress'],
      ),
      clinicHours: _stringValue(
        data['clinicHours'],
      ),
      phone: _stringValue(
        data['phone'],
      ),
      email: _stringValue(
        data['email'],
      ),
    );
  }

  static String? _stringValue(
      dynamic value,
      ) {
    final text = value
        ?.toString()
        .trim();

    if (text == null ||
        text.isEmpty ||
        text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  static double? _doubleValue(
      dynamic value,
      ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value == null) {
      return null;
    }

    return double.tryParse(
      value.toString(),
    );
  }

  static int? _intValue(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    if (value == null) {
      return null;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static num? _numberValue(
      dynamic value,
      ) {
    if (value is num) {
      return value;
    }

    if (value == null) {
      return null;
    }

    return num.tryParse(
      value.toString(),
    );
  }

  static List<String> _stringList(
      dynamic value,
      ) {
    if (value is! List) {
      return [];
    }

    return value
        .map(
          (item) => item
          ?.toString()
          .trim(),
    )
        .whereType<String>()
        .where(
          (item) =>
      item.isNotEmpty &&
          item.toLowerCase() !=
              'null',
    )
        .toList();
  }
}

class DoctorRecommendationContext {
  final String reason;
  final String sourceLabel;
  final DateTime? sourceDate;

  const DoctorRecommendationContext({
    required this.reason,
    required this.sourceLabel,
    this.sourceDate,
  });
}

class DoctorDetailsPage extends StatelessWidget {
  final Doctor doctor;
  final DoctorRecommendationContext? recommendation;

  const DoctorDetailsPage({
    super.key,
    required this.doctor,
    this.recommendation,
  });

  String _primarySpecialty() {
    if (doctor.specialties.isNotEmpty) {
      final first = doctor.specialties.first.trim();
      if (first.isNotEmpty) {
        return first;
      }
    }

    final parts = doctor.specialization
        .split('·')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (parts.isNotEmpty) {
      return parts.first;
    }

    return 'Specialist';
  }

  List<String> _otherSpecialties() {
    final primary = _primarySpecialty().toLowerCase();

    final values = <String>{
      ...doctor.specialties,
      ...doctor.specialization
          .split('·')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
    };

    return values
        .where(
          (item) => item.trim().toLowerCase() != primary,
    )
        .toList();
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _feeText() {
    final fee = doctor.consultationFee;

    if (fee == null) {
      return 'Not listed';
    }

    if (fee is double && fee == fee.roundToDouble()) {
      return 'Rs. ${fee.toInt()}';
    }

    return 'Rs. $fee';
  }

  @override
  Widget build(BuildContext context) {
    final otherSpecialties = _otherSpecialties();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _DoctorHero(
                doctor: doctor,
                primarySpecialty: _primarySpecialty(),
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                16,
                46,
                16,
                112,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    if (recommendation != null) ...[
                      const SizedBox(height: 2),
                      _RecommendationCard(
                        doctor: doctor,
                        recommendation: recommendation!,
                      ),
                      const SizedBox(height: 22),
                    ] else
                      const SizedBox(height: 2),

                    if (_hasText(doctor.about)) ...[
                      const _SectionTitle(
                        title: 'About Doctor',
                      ),
                      const SizedBox(height: 10),
                      _TextCard(
                        text: doctor.about!,
                      ),
                      const SizedBox(height: 22),
                    ],

                    const _SectionTitle(
                      title: 'At a Glance',
                    ),
                    const SizedBox(height: 10),
                    _AtAGlanceCard(
                      doctor: doctor,
                      feeText: _feeText(),
                    ),

                    if (otherSpecialties.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const _SectionTitle(
                        title: 'Specialties',
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: otherSpecialties
                            .map(
                              (specialty) => _SimpleChip(
                            text: specialty,
                          ),
                        )
                            .toList(),
                      ),
                    ],

                    if (_hasText(doctor.qualification)) ...[
                      const SizedBox(height: 22),
                      const _SectionTitle(
                        title: 'Qualification',
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        icon: Icons.school_outlined,
                        title: 'Education & Qualification',
                        value: doctor.qualification!,
                      ),
                    ],

                    const SizedBox(height: 22),
                    const _SectionTitle(
                      title: 'Availability',
                    ),
                    const SizedBox(height: 10),
                    _AvailabilitySection(
                      doctor: doctor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            14,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: doctor.available
                  ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ConsultationBookingPage(
                          doctor: doctor,
                        ),
                  ),
                );
              }
                  : null,
              icon: const Icon(
                Icons.calendar_month_outlined,
                size: 20,
              ),
              label: Text(
                doctor.available
                    ? 'Book Consultation'
                    : 'Currently Unavailable',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor:
                const Color(0xFF11786D),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                const Color(0xFFB8C1BE),
                disabledForegroundColor:
                Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorHero extends StatelessWidget {
  final Doctor doctor;
  final String primarySpecialty;
  final VoidCallback onBack;

  const _DoctorHero({
    required this.doctor,
    required this.primarySpecialty,
    required this.onBack,
  });

  String _feeText() {
    final fee = doctor.consultationFee;

    if (fee == null) {
      return 'Fee not listed';
    }

    if (fee is double && fee == fee.roundToDouble()) {
      return 'Rs. ${fee.toInt()} / consultation';
    }

    return 'Rs. $fee / consultation';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final width = constraints.maxWidth;
        final compact = width < 360;

        final heroHeight =
        (width * 0.86).clamp(305.0, 365.0).toDouble();

        final imageWidth =
        (width * 0.66).clamp(230.0, 320.0).toDouble();

        return Container(
          width: double.infinity,
          height: heroHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8F7F2),
                Color(0xFFD8F1EA),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(34),
              bottomRight: Radius.circular(34),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -42,
                top: -58,
                child: Container(
                  width: width * 0.62,
                  height: width * 0.62,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.38),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Large doctor image behind the stats cards.
              Positioned(
                right: -20,
                bottom: 4,
                width: imageWidth,
                height: heroHeight * 0.86,
                child: _DoctorImage(
                  imageUrl: doctor.imageUrl,
                ),
              ),

              // Doctor information.
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 20,
                  compact ? 76 : 84,
                  width * 0.46,
                  52,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primarySpecialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF11786D),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      doctor.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 25 : 29,
                        height: 1.03,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      _feeText(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 13.5 : 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF11786D),
                      ),
                    ),
                    if (doctor.verified) ...[
                      const SizedBox(height: 12),
                      const _VerifiedPill(),
                    ],
                  ],
                ),
              ),

              // Back button.
              Positioned(
                left: compact ? 14 : 16,
                top: compact ? 12 : 14,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onBack,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: compact ? 42 : 46,
                      height: compact ? 42 : 46,
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),

              // Floating stats row between the hero and the content below.
              Positioned(
                left: compact ? 10 : 14,
                right: compact ? 10 : 14,
                bottom: -34,
                child: _StatsRow(
                  doctor: doctor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Doctor doctor;

  const _StatsRow({
    required this.doctor,
  });

  String _patientsText() {
    final count = doctor.patientCount;

    if (count == null) {
      return '—';
    }

    if (count >= 1000) {
      final value = count / 1000;

      if (value == value.round()) {
        return '${value.round()}K+';
      }

      return '${value.toStringAsFixed(1)}K+';
    }

    return '$count+';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final compact =
            constraints.maxWidth < 350;
        final gap = compact ? 7.0 : 9.0;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon:
                Icons.work_outline_rounded,
                label: 'Experience',
                value:
                doctor.experienceYears ==
                    null
                    ? '—'
                    : '${doctor.experienceYears} yrs',
                compact: compact,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _StatCard(
                icon: Icons.star_rounded,
                label: 'Rating',
                value: doctor.rating == null
                    ? '—'
                    : doctor.rating!
                    .toStringAsFixed(1),
                compact: compact,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _StatCard(
                icon:
                Icons.people_outline_rounded,
                label: 'Patients',
                value: _patientsText(),
                compact: compact,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 11 : 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: const Color(
            0xFFE8ECEA,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 28 : 31,
                height: compact ? 28 : 31,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFE5F5F0,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    9,
                  ),
                ),
                child: Icon(
                  icon,
                  size:
                  compact ? 15 : 17,
                  color:
                  const Color(
                    0xFF11786D,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize:
                    compact ? 9.5 : 10.5,
                    color:
                    AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
            Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize:
                compact ? 14.5 : 16,
                fontWeight:
                FontWeight.w900,
                color:
                AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight:
        FontWeight.w900,
        color: AppColors.textDark,
      ),
    );
  }
}

class _AtAGlanceCard extends StatelessWidget {
  final Doctor doctor;
  final String feeText;

  const _AtAGlanceCard({
    required this.doctor,
    required this.feeText,
  });

  bool _hasText(String? value) {
    return value != null &&
        value.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final rows = <_GlanceData>[
      if (doctor.hospital.trim().isNotEmpty)
        _GlanceData(
          icon:
          Icons.local_hospital_outlined,
          label: 'Hospital',
          value: doctor.hospital,
        ),
      if (_hasText(doctor.clinicName))
        _GlanceData(
          icon:
          Icons.medical_services_outlined,
          label: 'Clinic',
          value: doctor.clinicName!,
        ),
      if (_hasText(doctor.clinicAddress))
        _GlanceData(
          icon:
          Icons.location_on_outlined,
          label: 'Address',
          value: doctor.clinicAddress!,
        ),
      if (doctor.languages.isNotEmpty)
        _GlanceData(
          icon:
          Icons.language_rounded,
          label: 'Languages',
          value:
          doctor.languages.join(', '),
        ),
      if (_hasText(doctor.clinicHours))
        _GlanceData(
          icon: Icons.schedule_outlined,
          label: 'Clinic Hours',
          value: doctor.clinicHours!,
        ),
      _GlanceData(
        icon:
        Icons.payments_outlined,
        label: 'Consultation Fee',
        value: feeText,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF5F0FA,
        ),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0;
          i < rows.length;
          i++) ...[
            _GlanceRow(
              data: rows[i],
            ),
            if (i != rows.length - 1)
              const Padding(
                padding:
                EdgeInsets.symmetric(
                  vertical: 10,
                ),
                child: Divider(
                  height: 1,
                  color: Color(
                    0xFFE6DFED,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _GlanceData {
  final IconData icon;
  final String label;
  final String value;

  const _GlanceData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _GlanceRow extends StatelessWidget {
  final _GlanceData data;

  const _GlanceRow({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(11),
          ),
          child: Icon(
            data.icon,
            size: 18,
            color:
            const Color(
              0xFF11786D,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style:
                const TextStyle(
                  fontSize: 11,
                  color:
                  AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.value,
                style:
                const TextStyle(
                  fontSize: 13.5,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvailabilitySection
    extends StatelessWidget {
  final Doctor doctor;

  const _AvailabilitySection({
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color:
          const Color(
            0xFFE8ECEA,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: doctor.available
                      ? const Color(
                    0xFFE5F7F1,
                  )
                      : const Color(
                    0xFFF0F2F1,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  doctor.available
                      ? Icons
                      .check_circle_outline_rounded
                      : Icons
                      .event_busy_outlined,
                  size: 20,
                  color: doctor.available
                      ? const Color(
                    0xFF11786D,
                  )
                      : const Color(
                    0xFF6B7572,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  doctor.available
                      ? 'Available for consultation'
                      : 'Currently unavailable',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w800,
                    color: doctor.available
                        ? const Color(
                      0xFF11786D,
                    )
                        : AppColors
                        .textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (doctor.availableSlots
              .isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: doctor
                  .availableSlots
                  .map(
                    (slot) => _SlotChip(
                  text: slot,
                ),
              )
                  .toList(),
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              'No appointment times are listed right now.',
              style: TextStyle(
                fontSize: 12.5,
                color:
                AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String text;

  const _SlotChip({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color:
        const Color(
          0xFFE7F6F1,
        ),
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
          color:
          Color(0xFF11786D),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(
            0xFFE8ECEA,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
              const Color(
                0xFFE7F6F1,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color:
              const Color(
                0xFF11786D,
              ),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 11.5,
                    color:
                    AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    AppColors.textDark,
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

class _TextCard extends StatelessWidget {
  final String text;

  const _TextCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(
            0xFFE8ECEA,
          ),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.5,
          color:
          AppColors.textDark,
        ),
      ),
    );
  }
}

class _RecommendationCard
    extends StatelessWidget {
  final Doctor doctor;
  final DoctorRecommendationContext
  recommendation;

  const _RecommendationCard({
    required this.doctor,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xFFF2EEFF),
            Color(0xFFEAF8F4),
          ],
        ),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color:
                Color(0xFF7258D8),
              ),
              SizedBox(width: 8),
              Text(
                'Recommended from analyzed report',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            recommendation.reason,
            style: const TextStyle(
              fontSize: 12.8,
              height: 1.45,
              color:
              AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _sourceText(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF5279D9),
            ),
          ),
        ],
      ),
    );
  }

  String _sourceText() {
    if (recommendation.sourceDate ==
        null) {
      return recommendation.sourceLabel;
    }

    final date =
    recommendation.sourceDate!;

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

    return '${recommendation.sourceLabel} • '
        '${date.day} '
        '${months[date.month - 1]}';
  }
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white
            .withOpacity(0.78),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: 14,
            color:
            Color(0xFF11786D),
          ),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF11786D),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleChip extends StatelessWidget {
  final String text;

  const _SimpleChip({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color:
        const Color(
          0xFFE7F6F1,
        ),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight:
          FontWeight.w700,
          color:
          Color(0xFF11786D),
        ),
      ),
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
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: Colors.transparent,
        alignment:
        Alignment.bottomCenter,
        child: const Icon(
          Icons.person_rounded,
          size: 96,
          color:
          AppColors.primary,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      alignment:
      Alignment.bottomCenter,
      errorBuilder: (
          context,
          error,
          stackTrace,
          ) {
        return Container(
          color: Colors.transparent,
          alignment:
          Alignment.bottomCenter,
          child: const Icon(
            Icons.person_rounded,
            size: 96,
            color:
            AppColors.primary,
          ),
        );
      },
      loadingBuilder: (
          context,
          child,
          loadingProgress,
          ) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
      },
    );
  }
}
