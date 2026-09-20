import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppointmentDetailPage extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailPage({
    super.key,
    required this.appointment,
  });

  String _read(
      String key, {
        String fallback = 'Not available',
      }) {
    final value = appointment[key];
    if (value == null) return fallback;

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not specified';

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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _statusLabel() {
    final raw = _read(
      'status',
      fallback: 'confirmed',
    ).toLowerCase();

    switch (raw) {
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      default:
        if (raw.isEmpty) return 'Confirmed';
        return '${raw[0].toUpperCase()}${raw.substring(1)}';
    }
  }

  Color _statusColor() {
    switch (_statusLabel().toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF11786D);
      case 'completed':
        return const Color(0xFF3B74E0);
      case 'cancelled':
        return const Color(0xFFD92D20);
      default:
        return const Color(0xFF8A6500);
    }
  }

  Color _statusBackground() {
    switch (_statusLabel().toLowerCase()) {
      case 'confirmed':
        return const Color(0xFFE5F7F1);
      case 'completed':
        return const Color(0xFFEAF1FF);
      case 'cancelled':
        return const Color(0xFFFFECEA);
      default:
        return const Color(0xFFFFF5D6);
    }
  }

  String _consultationLabel() {
    final type = _read(
      'consultationType',
      fallback: 'clinic',
    ).toLowerCase();

    if (type == 'video') return 'Video Consultation';

    if (type == 'clinic' ||
        type == 'in_person' ||
        type == 'in-person') {
      return 'Clinic Consultation';
    }

    return _read(
      'consultationType',
      fallback: 'Consultation',
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = _read(
      'doctorName',
      fallback: 'Doctor',
    );
    final specialization = _read(
      'doctorSpecialization',
      fallback: 'Specialist',
    );
    final appointmentDate = _date(
      appointment['appointmentDate'],
    );
    final time = _read(
      'appointmentTime',
      fallback: 'Not specified',
    );
    final clinicName = _read(
      'clinicName',
      fallback: '',
    );
    final clinicAddress = _read(
      'clinicAddress',
      fallback: '',
    );
    final fee = _read(
      'consultationFee',
      fallback: '',
    );
    final notes = _read(
      'notes',
      fallback: '',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Appointment Details',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF17211E),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE8F7F2),
                    Color(0xFFF5FBF9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      size: 34,
                      color: Color(0xFF11786D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doctorName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF17211E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialization,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF66736F),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusBackground(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _statusColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Appointment'),
            const SizedBox(height: 10),
            _InfoCard(
              children: [
                _DetailRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Date',
                  value: _formatDate(appointmentDate),
                ),
                _DetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Time',
                  value: time,
                ),
                _DetailRow(
                  icon: Icons.video_call_outlined,
                  label: 'Consultation',
                  value: _consultationLabel(),
                ),
              ],
            ),
            if (clinicName.isNotEmpty ||
                clinicAddress.isNotEmpty) ...[
              const SizedBox(height: 22),
              const _SectionTitle('Clinic'),
              const SizedBox(height: 10),
              _InfoCard(
                children: [
                  if (clinicName.isNotEmpty)
                    _DetailRow(
                      icon: Icons.local_hospital_outlined,
                      label: 'Clinic',
                      value: clinicName,
                    ),
                  if (clinicAddress.isNotEmpty)
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: clinicAddress,
                    ),
                ],
              ),
            ],
            if (fee.isNotEmpty) ...[
              const SizedBox(height: 22),
              const _SectionTitle('Payment'),
              const SizedBox(height: 10),
              _InfoCard(
                children: [
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Consultation Fee',
                    value: fee.startsWith('Rs.')
                        ? fee
                        : 'Rs. $fee',
                  ),
                ],
              ),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 22),
              const _SectionTitle('Notes'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE4EAE7),
                  ),
                ),
                child: Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF3F4A46),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

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

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE4EAE7),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: Color(0xFFE9EEEC),
                ),
              ),
          ],
        ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F6F1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 19,
            color: const Color(0xFF11786D),
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
                  fontSize: 11,
                  color: Color(0xFF7A8581),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17211E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
