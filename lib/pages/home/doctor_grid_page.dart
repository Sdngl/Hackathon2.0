import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/apptheme.dart';

class DoctorGridPage extends StatelessWidget {
  const DoctorGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Find a Doctor',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
            );
          }

          final doctors = snapshot.data?.docs ?? [];

          if (doctors.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await FirebaseFirestore.instance
                  .collection('doctors')
                  .where('isActive', isEqualTo: true)
                  .get();
            },
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                28,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final document = doctors[index];

                final doctor = Doctor.fromFirestore(
                  id: document.id,
                  data: document.data(),
                );

                return DoctorCard(
                  doctor: doctor,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DoctorDetailsPage(
                          doctor: doctor,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String hospital;
  final String imageUrl;
  final double? rating;
  final int? experienceYears;
  final num? consultationFee;
  final bool available;
  final bool isActive;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.hospital,
    required this.imageUrl,
    required this.rating,
    required this.experienceYears,
    required this.consultationFee,
    required this.available,
    required this.isActive,
  });

  factory Doctor.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return Doctor(
      id: id,
      name: _stringValue(
        data['name'],
      ) ??
          'Doctor',
      specialization: _stringValue(
        data['specialization'],
      ) ??
          'Specialist',
      hospital: _stringValue(
        data['hospital'],
      ) ??
          '',
      imageUrl: _stringValue(
        data['imageUrl'],
      ) ??
          '',
      rating: _doubleValue(
        data['rating'],
      ),
      experienceYears: _intValue(
        data['experienceYears'],
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
    );
  }

  static String? _stringValue(
      dynamic value,
      ) {
    final text = value?.toString().trim();

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
}

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: _DoctorImage(
                      imageUrl: doctor.imageUrl,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                doctor.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                doctor.specialization,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              if (doctor.hospital.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.local_hospital_outlined,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctor.hospital,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (doctor.rating != null)
                    _SmallChip(
                      icon: Icons.star_rounded,
                      text: doctor.rating!.toStringAsFixed(1),
                    ),
                  if (doctor.experienceYears != null)
                    _SmallChip(
                      icon: Icons.work_outline_rounded,
                      text:
                      '${doctor.experienceYears} yr${doctor.experienceYears == 1 ? '' : 's'}',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      doctor.consultationFee == null
                          ? 'Fee not listed'
                          : 'Rs. ${doctor.consultationFee}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  _AvailabilityDot(
                    available: doctor.available,
                  ),
                ],
              ),
            ],
          ),
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
        color: AppColors.accentLight,
        alignment: Alignment.center,
        child: const Icon(
          Icons.person_rounded,
          size: 64,
          color: AppColors.primary,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (
          context,
          error,
          stackTrace,
          ) {
        return Container(
          color: AppColors.accentLight,
          alignment: Alignment.center,
          child: const Icon(
            Icons.person_rounded,
            size: 64,
            color: AppColors.primary,
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
}

class _SmallChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SmallChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityDot extends StatelessWidget {
  final bool available;

  const _AvailabilityDot({
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: available
            ? const Color(0xFFE3F5EF)
            : const Color(0xFFF0F2F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available ? 'Available' : 'Unavailable',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: available
              ? const Color(0xFF0F7B64)
              : const Color(0xFF6B7572),
        ),
      ),
    );
  }
}

class DoctorDetailsPage extends StatelessWidget {
  final Doctor doctor;

  const DoctorDetailsPage({
    super.key,
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Doctor Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: _DoctorImage(
                    imageUrl: doctor.imageUrl,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              doctor.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              doctor.specialization,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            if (doctor.hospital.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.local_hospital_outlined,
                label: 'Hospital',
                value: doctor.hospital,
              ),
            ],
            if (doctor.experienceYears != null) ...[
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.work_outline_rounded,
                label: 'Experience',
                value:
                '${doctor.experienceYears} year${doctor.experienceYears == 1 ? '' : 's'}',
              ),
            ],
            if (doctor.rating != null) ...[
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.star_rounded,
                label: 'Rating',
                value: doctor.rating!.toStringAsFixed(1),
              ),
            ],
            if (doctor.consultationFee != null) ...[
              const SizedBox(height: 10),
              _DetailRow(
                icon: Icons.payments_outlined,
                label: 'Consultation fee',
                value: 'Rs. ${doctor.consultationFee}',
              ),
            ],
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: 'Status',
              value: doctor.available
                  ? 'Available'
                  : 'Currently unavailable',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: doctor.available
                    ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Appointment booking is the next step.',
                      ),
                    ),
                  );
                }
                    : null,
                icon: const Icon(
                  Icons.calendar_month_outlined,
                ),
                label: Text(
                  doctor.available
                      ? 'Book Appointment'
                      : 'Unavailable',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medical_services_outlined,
              size: 58,
              color: AppColors.primary,
            ),
            SizedBox(height: 14),
            Text(
              'No doctors available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Doctors added by the admin will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load doctors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
