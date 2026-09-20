import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'appoinment_detail_page.dart';

class AppointmentListPage extends StatelessWidget {
  final List<Map<String, dynamic>> appointments;

  const AppointmentListPage({
    super.key,
    required this.appointments,
  });

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date not specified';

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

  String _read(
      Map<String, dynamic> appointment,
      String key, {
        String fallback = '',
      }) {
    final value = appointment[key];
    if (value == null) return fallback;

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _statusLabel(Map<String, dynamic> appointment) {
    final raw = _read(
      appointment,
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Appointments',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF17211E),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        itemCount: appointments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appointment = appointments[index];

          final doctorName = _read(
            appointment,
            'doctorName',
            fallback: 'Doctor',
          );
          final specialization = _read(
            appointment,
            'doctorSpecialization',
            fallback: 'Specialist',
          );
          final status = _statusLabel(appointment);
          final date = _date(appointment['appointmentDate']);
          final time = _read(appointment, 'appointmentTime');
          final consultationType = _read(
            appointment,
            'consultationType',
            fallback: 'clinic',
          ).toLowerCase();

          final isVideo = consultationType == 'video';

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AppointmentDetailPage(
                      appointment: appointment,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F6F1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        isVideo
                            ? Icons.videocam_outlined
                            : Icons.medical_services_outlined,
                        color: const Color(0xFF11786D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF17211E),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            specialization,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A8581),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 15,
                                color: Color(0xFF66736F),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  _formatDate(date),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF66736F),
                                  ),
                                ),
                              ),
                              if (time.isNotEmpty) ...[
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                  color: Color(0xFF66736F),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF66736F),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _statusBackground(status),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _statusColor(status),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF98A2B3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
