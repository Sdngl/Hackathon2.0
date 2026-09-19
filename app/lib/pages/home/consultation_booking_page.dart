import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../service/health_scan_repository.dart';
import '../../service/notification_repository.dart';
import '../theme/apptheme.dart';
import 'doctor_detail_page.dart';

class ConsultationBookingPage extends StatefulWidget {
  final Doctor doctor;

  const ConsultationBookingPage({
    super.key,
    required this.doctor,
  });

  @override
  State<ConsultationBookingPage> createState() =>
      _ConsultationBookingPageState();
}

class _ConsultationBookingPageState
    extends State<ConsultationBookingPage> {
  final NotificationRepository _notificationRepository = NotificationRepository();
  bool _loading = true;
  bool _booking = false;

  String _consultationType = 'clinic';

  String _userPlan = 'free';
  bool _subscriptionActive = false;

  List<String> _videoSlots = [];

  String? _selectedDateKey;
  String? _selectedTime;

  List<UserMedicalReport> _reports = [];

  bool _shareReport = false;
  String? _selectedReportId;

  bool get _canUseVideoCall {
    final plan = _userPlan.trim().toLowerCase();

    return _subscriptionActive &&
        (plan == 'plus' ||
            plan == 'paid' ||
            plan == 'premium');
  }

  bool get _isVideo => _consultationType == 'video';

  bool get _canConfirmBooking {
    if (_booking) {
      return false;
    }

    if (_isVideo) {
      if (!_canUseVideoCall) {
        return false;
      }

      if (_videoSlots.isEmpty) {
        return false;
      }

      if (_selectedDateKey == null) {
        return false;
      }

      if (_selectedTime == null) {
        return false;
      }
    }

    if (_shareReport &&
        _selectedReportId == null) {
      return false;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadBookingData();
  }

  Future<void> _loadBookingData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _toast('Please sign in to book a consultation.');

      if (mounted) {
        Navigator.pop(context);
      }

      return;
    }

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(),
        FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctor.id)
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reports')
            .where(
          'status',
          isEqualTo: 'completed',
        )
            .get(),
      ]);

      final userDocument =
      results[0]
      as DocumentSnapshot<Map<String, dynamic>>;

      final doctorDocument =
      results[1]
      as DocumentSnapshot<Map<String, dynamic>>;

      final reportsSnapshot =
      results[2]
      as QuerySnapshot<Map<String, dynamic>>;

      final userData =
          userDocument.data() ?? <String, dynamic>{};

      final doctorData =
          doctorDocument.data() ?? <String, dynamic>{};

      _loadSubscription(userData);

      final videoSlots = _parseAvailableSlots(
        doctorData['availableSlots'],
      );

      final reports = reportsSnapshot.docs.map(
            (document) {
          return UserMedicalReport.fromFirestore(
            id: document.id,
            data: document.data(),
          );
        },
      ).toList();

      reports.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      if (!mounted) return;

      setState(() {
        _videoSlots = videoSlots;
        _reports = reports;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _toast('Could not load consultation details.');
    }
  }

  DateTime? _readSubscriptionDate(
      dynamic value,
      ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  void _loadSubscription(
      Map<String, dynamic> userData,
      ) {
    final isPaid =
        userData['isPaid'] == true;

    final expiresAt =
    _readSubscriptionDate(
      userData['subscriptionExpiresAt'],
    );

    // New SEVA Premium subscription format.
    //
    // Premium access is valid only while:
    // 1. isPaid == true
    // 2. subscriptionExpiresAt exists
    // 3. the expiry date is still in the future
    if (isPaid &&
        expiresAt != null &&
        expiresAt.isAfter(DateTime.now())) {
      _userPlan = 'premium';
      _subscriptionActive = true;
      return;
    }

    // If the user has the new subscription fields but the subscription
    // is expired/invalid, do not fall back to an older paid flag.
    final hasNewSubscriptionData =
        userData.containsKey(
          'subscriptionPlan',
        ) ||
            userData.containsKey(
              'subscriptionExpiresAt',
            ) ||
            userData.containsKey(
              'subscriptionStartedAt',
            ) ||
            userData.containsKey(
              'subscriptionMonths',
            ) ||
            isPaid;

    if (hasNewSubscriptionData) {
      _userPlan = 'free';
      _subscriptionActive = false;
      return;
    }

    // Legacy subscription format support.
    final subscription =
    userData['subscription'];

    if (subscription is Map) {
      final data =
      Map<String, dynamic>.from(
        subscription,
      );

      _userPlan =
          data['plan']
              ?.toString()
              .trim()
              .toLowerCase() ??
              'free';

      _subscriptionActive =
          data['active'] == true;

      return;
    }

    // Legacy top-level plan support.
    final plan =
    userData['plan']
        ?.toString()
        .trim()
        .toLowerCase();

    if (plan == 'plus' ||
        plan == 'paid' ||
        plan == 'premium') {
      _userPlan = plan!;
      _subscriptionActive = true;
      return;
    }

    _userPlan = 'free';
    _subscriptionActive = false;
  }

  List<String> _parseAvailableSlots(
      dynamic value,
      ) {
    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item?.toString().trim())
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<DateTime> _videoDateOptions() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(
      7,
          (index) => today.add(Duration(days: index)),
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  void _selectClinic() {
    setState(() {
      _consultationType = 'clinic';
      _selectedDateKey = null;
      _selectedTime = null;
    });
  }

  void _selectVideo() {
    if (!_canUseVideoCall) {
      _toast(
        'Video consultation is available with SEVA Premium.',
      );
      return;
    }

    setState(() {
      _consultationType = 'video';
      _selectedDateKey = null;
      _selectedTime = null;
    });

    if (_videoSlots.isEmpty) {
      _toast(
        'No video consultation slots are available right now.',
      );
    }
  }

  void _toggleReportSharing(
      bool value,
      ) {
    setState(() {
      _shareReport = value;

      if (!value) {
        _selectedReportId = null;
      } else if (_reports.length == 1) {
        _selectedReportId = _reports.first.id;
      }
    });
  }

  Future<void> _confirmBooking() async {
    if (_booking) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _toast('Please sign in to continue.');
      return;
    }

    if (_isVideo) {
      if (!_canUseVideoCall) {
        _toast(
          'Video consultation requires SEVA Premium.',
        );
        return;
      }

      if (_videoSlots.isEmpty) {
        _toast(
          'No video consultation slots are available right now.',
        );
        return;
      }

      if (_selectedDateKey == null) {
        _toast(
          'Please select a consultation date.',
        );
        return;
      }

      if (_selectedTime == null) {
        _toast(
          'Please select an available time.',
        );
        return;
      }
    }

    if (_shareReport &&
        _selectedReportId == null) {
      _toast(
        'Please select which report you want to share.',
      );
      return;
    }

    setState(() {
      _booking = true;
    });

    try {
      final appointment = <String, dynamic>{
        'doctorId': widget.doctor.id,
        'doctorName': widget.doctor.name,
        'doctorSpecialization':
        widget.doctor.specialization,
        'doctorImageUrl':
        widget.doctor.imageUrl,
        'consultationType':
        _consultationType,
        'status': 'confirmed',
        'lastNotifiedStatus': 'confirmed',
        'reportShared':
        _shareReport &&
            _selectedReportId != null,
        'reportId':
        _shareReport
            ? _selectedReportId
            : null,
        'createdAt':
        FieldValue.serverTimestamp(),
      };

      if (_isVideo) {
        appointment['appointmentDate'] =
            _selectedDateKey;

        appointment['appointmentTime'] =
            _selectedTime;
      } else {
        appointment['appointmentDate'] = null;
        appointment['appointmentTime'] = null;

        appointment['clinicName'] =
            widget.doctor.clinicName ??
                widget.doctor.hospital;

        appointment['clinicAddress'] =
            widget.doctor.clinicAddress;
      }

      final appointmentDocument =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .add(appointment);

      // Booking remains successful even if notification creation fails.
      try {
        await _notificationRepository
            .createAppointmentBookedNotification(
          appointmentId: appointmentDocument.id,
          appointment: appointment,
        );
      } catch (_) {
        // Notification failure must not roll back a successful booking.
      }

      if (!mounted) return;

      _toast(
        'Consultation booked successfully.',
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (_) {
      _toast(
        'Could not confirm the booking. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _booking = false;
        });
      }
    }
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
        titleSpacing: 0,
        title: const Text(
          'Book Consultation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            138,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DoctorBookingCard(
                doctor: widget.doctor,
              ),

              const SizedBox(height: 22),

              const _BookingSectionTitle(
                title: 'Consultation Type',
                subtitle: 'Choose how you want to meet the doctor.',
              ),
              const SizedBox(height: 12),

              LayoutBuilder(
                builder: (
                    context,
                    constraints,
                    ) {
                  final compact =
                      constraints.maxWidth < 350;

                  if (compact) {
                    return Column(
                      children: [
                        _ConsultationTypeCard(
                          selected: !_isVideo,
                          disabled: false,
                          icon:
                          Icons.local_hospital_outlined,
                          title: 'Clinic Visit',
                          subtitle:
                          'Visit the doctor in person',
                          onTap: _selectClinic,
                        ),
                        const SizedBox(height: 10),
                        _ConsultationTypeCard(
                          selected: _isVideo,
                          disabled: !_canUseVideoCall,
                          icon: _canUseVideoCall
                              ? Icons.videocam_outlined
                              : Icons.lock_outline_rounded,
                          title: 'Video Consultation',
                          subtitle: _canUseVideoCall
                              ? 'Consult from home'
                              : 'SEVA Premium only',
                          onTap: _selectVideo,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _ConsultationTypeCard(
                          selected: !_isVideo,
                          disabled: false,
                          icon:
                          Icons.local_hospital_outlined,
                          title: 'Clinic Visit',
                          subtitle:
                          'In-person consultation',
                          onTap: _selectClinic,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ConsultationTypeCard(
                          selected: _isVideo,
                          disabled: !_canUseVideoCall,
                          icon: _canUseVideoCall
                              ? Icons.videocam_outlined
                              : Icons.lock_outline_rounded,
                          title: 'Video Consultation',
                          subtitle: _canUseVideoCall
                              ? 'Consult from home'
                              : 'Premium only',
                          onTap: _selectVideo,
                        ),
                      ),
                    ],
                  );
                },
              ),

              if (!_isVideo) ...[
                const SizedBox(height: 24),
                const _BookingSectionTitle(
                  title: 'Clinic Information',
                  subtitle:
                  'Where your in-person consultation will take place.',
                ),
                const SizedBox(height: 12),
                _ClinicInformationCard(
                  doctor: widget.doctor,
                ),
              ],

              if (_isVideo) ...[
                const SizedBox(height: 24),
                const _BookingSectionTitle(
                  title: 'Select Date',
                  subtitle:
                  'Choose a date for your video consultation.',
                ),
                const SizedBox(height: 12),
                _buildVideoDates(),

                if (_videoSlots.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const _BookingSectionTitle(
                    title: 'Available Time',
                    subtitle:
                    'Select one of the available consultation times.',
                  ),
                  const SizedBox(height: 12),
                  _buildTimeSlots(),
                ],
              ],

              const SizedBox(height: 24),

              const _BookingSectionTitle(
                title: 'Medical Report',
                subtitle:
                'Optional — share one saved report with the doctor.',
              ),
              const SizedBox(height: 12),
              _buildReportSharing(),

              const SizedBox(height: 24),

              const _BookingSectionTitle(
                title: 'Booking Summary',
              ),
              const SizedBox(height: 12),
              _BookingSummaryCard(
                doctor: widget.doctor,
                consultationType: _consultationType,
                selectedDateKey: _selectedDateKey,
                selectedTime: _selectedTime,
                shareReport: _shareReport,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
      _loading ? null : _buildBottomBar(),
    );
  }

  Widget _buildVideoDates() {
    if (_videoSlots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.event_busy_outlined,
              color: AppColors.textMuted,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No video consultation slots are available right now.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final dates = _videoDateOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final date = dates[index];
              final dateKey = _dateKey(date);
              final selected = _selectedDateKey == dateKey;

              return _DateCard(
                date: date,
                rawDate: dateKey,
                selected: selected,
                onTap: () {
                  setState(() {
                    _selectedDateKey = dateKey;
                    _selectedTime = null;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
    if (_selectedDateKey == null) {
      return const Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Available times',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w800,
              color:
              AppColors.textDark,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'Select a date to view available times.',
            style: TextStyle(
              fontSize: 13,
              color:
              AppColors.textMuted,
            ),
          ),
        ],
      );
    }

    final slots = _videoSlots;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          itemCount: slots.length,
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.35,
          ),
          itemBuilder:
              (
              context,
              index,
              ) {
            final time =
            slots[index];

            final selected =
                _selectedTime ==
                    time;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedTime =
                      time;
                });
              },
              borderRadius:
              BorderRadius.circular(
                14,
              ),
              child: Container(
                alignment:
                Alignment.center,
                decoration:
                BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                  border:
                  Border.all(
                    color: selected
                        ? AppColors.primary
                        : const Color(
                      0xFFE3E9E7,
                    ),
                  ),
                ),
                child: Text(
                  time,
                  style:
                  TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                    color: selected
                        ? Colors.white
                        : AppColors
                        .textDark,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReportSharing() {
    if (_reports.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            20,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons
                  .description_outlined,
              color:
              AppColors.textMuted,
            ),
            SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text(
                'No analyzed reports available to share.',
                style: TextStyle(
                  fontSize: 13,
                  color:
                  AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFE7F0FF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons
                      .description_outlined,
                  color:
                  Color(
                    0xFF4889E8,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Share report with doctor',
                      style:
                      TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight
                            .w800,
                        color:
                        AppColors
                            .textDark,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Only the report you choose will be shared.',
                      style:
                      TextStyle(
                        fontSize:
                        11.5,
                        color:
                        AppColors
                            .textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value:
                _shareReport,
                activeThumbColor:
                AppColors.primary,
                onChanged:
                _toggleReportSharing,
              ),
            ],
          ),
          if (_shareReport) ...[
            const SizedBox(
              height: 16,
            ),
            if (_reports.length ==
                1)
              _SingleReportCard(
                report:
                _reports.first,
                selected:
                _selectedReportId ==
                    _reports.first.id,
                onTap: () {
                  setState(() {
                    _selectedReportId =
                        _reports.first.id;
                  });
                },
              )
            else
              DropdownButtonFormField<
                  String>(
                value:
                _selectedReportId,
                isExpanded: true,
                decoration:
                InputDecoration(
                  labelText:
                  'Choose report',
                  filled: true,
                  fillColor:
                  AppColors.background,
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                    BorderSide.none,
                  ),
                ),
                hint:
                const Text(
                  'Select which report to share',
                ),
                items:
                _reports.map(
                      (report) {
                    return DropdownMenuItem<
                        String>(
                      value:
                      report.id,
                      child: Text(
                        report.displayName,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                      ),
                    );
                  },
                ).toList(),
                onChanged:
                    (
                    value,
                    ) {
                  setState(() {
                    _selectedReportId =
                        value;
                  });
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          14,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(
                0x16000000,
              ),
              blurRadius: 22,
              offset: Offset(
                0,
                -5,
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
            Text(
              _bookingSummary(),
              style:
              const TextStyle(
                fontSize: 12.5,
                fontWeight:
                FontWeight.w600,
                color:
                AppColors.textMuted,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width:
              double.infinity,
              height: 54,
              child:
              FilledButton.icon(
                onPressed:
                _canConfirmBooking
                    ? _confirmBooking
                    : null,
                icon: _booking
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Icon(
                  Icons
                      .check_rounded,
                ),
                label:
                Text(
                  _isVideo && _videoSlots.isEmpty
                      ? 'No video slots available'
                      : 'Confirm booking',
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight
                        .w800,
                  ),
                ),
                style:
                FilledButton
                    .styleFrom(
                  backgroundColor:
                  AppColors.primary,
                  foregroundColor:
                  Colors.white,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bookingSummary() {
    if (!_isVideo) {
      return 'In clinic • ${widget.doctor.name}';
    }

    final date =
        _selectedDateKey ??
            'Select date';

    final time =
        _selectedTime ??
            'Select time';

    return '$date • $time • Video call';
  }
}


class _BookingSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _BookingSectionTitle({
    required this.title,
    this.subtitle,
  });

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
            color: AppColors.textDark,
          ),
        ),
        if (subtitle != null &&
            subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 12.2,
              height: 1.35,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  final Doctor doctor;
  final String consultationType;
  final String? selectedDateKey;
  final String? selectedTime;
  final bool shareReport;

  const _BookingSummaryCard({
    required this.doctor,
    required this.consultationType,
    required this.selectedDateKey,
    required this.selectedTime,
    required this.shareReport,
  });

  String _feeText() {
    final fee = doctor.consultationFee;

    if (fee == null) {
      return 'Not listed';
    }

    if (fee is double &&
        fee == fee.roundToDouble()) {
      return 'Rs. ${fee.toInt()}';
    }

    return 'Rs. $fee';
  }

  @override
  Widget build(BuildContext context) {
    final isVideo =
        consultationType == 'video';

    final clinicName =
        doctor.clinicName ??
            (doctor.hospital.trim().isNotEmpty
                ? doctor.hospital
                : 'Clinic');

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
          _SummaryRow(
            label: 'Doctor',
            value: doctor.name,
          ),
          const _SummaryDivider(),
          _SummaryRow(
            label: 'Type',
            value: isVideo
                ? 'Video Consultation'
                : 'Clinic Visit',
          ),
          const _SummaryDivider(),
          _SummaryRow(
            label: 'Date',
            value: isVideo
                ? (selectedDateKey ?? 'Select date')
                : 'Clinic schedule',
          ),
          const _SummaryDivider(),
          _SummaryRow(
            label: 'Time',
            value: isVideo
                ? (selectedTime ?? 'Select time')
                : (doctor.clinicHours?.trim().isNotEmpty ==
                true
                ? doctor.clinicHours!
                : 'See clinic hours'),
          ),
          const _SummaryDivider(),
          _SummaryRow(
            label: isVideo
                ? 'Location'
                : 'Clinic',
            value: isVideo
                ? 'Online'
                : clinicName,
          ),
          const _SummaryDivider(),
          _SummaryRow(
            label: 'Fee',
            value: _feeText(),
            emphasize: true,
          ),
          if (shareReport) ...[
            const _SummaryDivider(),
            const _SummaryRow(
              label: 'Medical report',
              value: 'Selected for sharing',
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              height: 1.3,
              fontWeight: emphasize
                  ? FontWeight.w900
                  : FontWeight.w700,
              color: emphasize
                  ? AppColors.primary
                  : AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Divider(
        height: 1,
        color: Color(0xFFE9EEEC),
      ),
    );
  }
}

class UserMedicalReport {
  final String id;
  final String title;
  final DateTime createdAt;

  const UserMedicalReport({
    required this.id,
    required this.title,
    required this.createdAt,
  });

  factory UserMedicalReport.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final analysisRaw =
    data['analysis'];

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

    final title =
    _firstText(
      [
        report['title'],
        report['report_type'],
        data['fileName'],
      ],
    );

    final created =
    data['createdAt'];

    return UserMedicalReport(
      id: id,
      title:
      title ??
          'Medical report',
      createdAt:
      created is Timestamp
          ? created.toDate()
          : DateTime
          .fromMillisecondsSinceEpoch(
        0,
      ),
    );
  }

  String get displayName {
    if (createdAt
        .millisecondsSinceEpoch ==
        0) {
      return title;
    }

    return '$title • ${createdAt.day} ${_month(createdAt.month)}';
  }

  static String? _firstText(
      List<dynamic> values,
      ) {
    for (final value
    in values) {
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

  static String _month(
      int month,
      ) {
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

    return months[
    month - 1
    ];
  }
}

class _DoctorBookingCard
    extends StatelessWidget {
  final Doctor doctor;

  const _DoctorBookingCard({
    required this.doctor,
  });

  String _primarySpecialty() {
    if (doctor.specialties.isNotEmpty) {
      return doctor.specialties.first;
    }

    final values = doctor.specialization
        .split('·')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return values.isNotEmpty
        ? values.first
        : 'Specialist';
  }

  String _feeText() {
    final fee = doctor.consultationFee;

    if (fee == null) {
      return 'Fee not listed';
    }

    if (fee is double &&
        fee == fee.roundToDouble()) {
      return 'Rs. ${fee.toInt()}';
    }

    return 'Rs. $fee';
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final compact =
            constraints.maxWidth < 350;
        final imageSize =
        compact ? 68.0 : 76.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            compact ? 13 : 15,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color:
              const Color(0xFFE4EAE7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.03),
                blurRadius: 16,
                offset:
                const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                BorderRadius.circular(18),
                child: SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child:
                  _BookingDoctorImage(
                    imageUrl:
                    doctor.imageUrl,
                  ),
                ),
              ),
              SizedBox(
                width:
                compact ? 11 : 13,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            doctor.name,
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight
                                  .w900,
                              color: AppColors
                                  .textDark,
                            ),
                          ),
                        ),
                        if (doctor.verified) ...[
                          const SizedBox(
                              width: 6),
                          const Icon(
                            Icons
                                .verified_rounded,
                            size: 18,
                            color: Color(
                              0xFF119483,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _primarySpecialty(),
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _feeText(),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                        FontWeight.w900,
                        color:
                        AppColors.primary,
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

class _BookingDoctorImage
    extends StatelessWidget {
  final String imageUrl;

  const _BookingDoctorImage({
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
          size: 40,
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
            size: 40,
            color: AppColors.primary,
          ),
        );
      },
    );
  }
}

class _ConsultationTypeCard
    extends StatelessWidget {
  final bool selected;
  final bool disabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ConsultationTypeCard({
    required this.selected,
    required this.disabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color: Colors.transparent,
      borderRadius:
      BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(18),
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 180,
          ),
          width: double.infinity,
          constraints:
          const BoxConstraints(
            minHeight: 92,
          ),
          padding:
          const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: disabled
                ? const Color(
              0xFFF3F4F4,
            )
                : selected
                ? const Color(
              0xFFE7F5F1,
            )
                : Colors.white,
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : const Color(
                0xFFE1E7E5,
              ),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: disabled
                          ? const Color(
                        0xFFE7E9E8,
                      )
                          : selected
                          ? Colors.white
                          : AppColors
                          .accentLight,
                      borderRadius:
                      BorderRadius.circular(
                        11,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 19,
                      color: disabled
                          ? AppColors
                          .textMuted
                          : AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (selected &&
                      !disabled)
                    const Icon(
                      Icons
                          .check_circle_rounded,
                      size: 19,
                      color:
                      AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                title,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w800,
                  color: disabled
                      ? AppColors.textMuted
                      : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  color:
                  AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicInformationCard
    extends StatelessWidget {
  final Doctor doctor;

  const _ClinicInformationCard({
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    final clinicName =
        doctor.clinicName ??
            doctor.hospital;

    final items = <_ClinicInfoItem>[
      if (clinicName.trim().isNotEmpty)
        _ClinicInfoItem(
          icon:
          Icons.local_hospital_outlined,
          label: 'Clinic',
          value: clinicName,
        ),
      if (doctor.clinicAddress != null &&
          doctor.clinicAddress!
              .trim()
              .isNotEmpty)
        _ClinicInfoItem(
          icon:
          Icons.location_on_outlined,
          label: 'Address',
          value:
          doctor.clinicAddress!,
        ),
      if (doctor.clinicHours != null &&
          doctor.clinicHours!
              .trim()
              .isNotEmpty)
        _ClinicInfoItem(
          icon:
          Icons.schedule_outlined,
          label: 'Clinic Hours',
          value:
          doctor.clinicHours!,
        ),
    ];

    if (items.isEmpty) {
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
              0xFFE4EAE7,
            ),
          ),
        ),
        child: const Text(
          'Clinic information is not available yet.',
          style: TextStyle(
            fontSize: 12.5,
            color:
            AppColors.textMuted,
          ),
        ),
      );
    }

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
            0xFFE4EAE7,
          ),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0;
          i < items.length;
          i++) ...[
            _ClinicInfoRow(
              item: items[i],
            ),
            if (i !=
                items.length - 1)
              const Padding(
                padding:
                EdgeInsets.symmetric(
                  vertical: 10,
                ),
                child: Divider(
                  height: 1,
                  color: Color(
                    0xFFE9EEEC,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ClinicInfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _ClinicInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _ClinicInfoRow
    extends StatelessWidget {
  final _ClinicInfoItem item;

  const _ClinicInfoRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color:
            AppColors.accentLight,
            borderRadius:
            BorderRadius.circular(12),
          ),
          child: Icon(
            item.icon,
            size: 19,
            color:
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style:
                const TextStyle(
                  fontSize: 11,
                  color:
                  AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                style:
                const TextStyle(
                  fontSize: 13.5,
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
    );
  }
}

class _DateCard
    extends StatelessWidget {
  final DateTime? date;
  final String rawDate;
  final bool selected;
  final VoidCallback onTap;

  const _DateCard({
    required this.date,
    required this.rawDate,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final day = date == null
        ? ''
        : _weekday(
      date!.weekday,
    );

    final number = date == null
        ? rawDate
        : '${date!.day}';

    final month = date == null
        ? ''
        : _month(
      date!.month,
    );

    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(16),
      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 160,
        ),
        width: 68,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : Colors.white,
          borderRadius:
          BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : const Color(
              0xFFE3E9E7,
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              if (day.isNotEmpty)
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight:
                    FontWeight.w600,
                    color: selected
                        ? Colors.white70
                        : AppColors
                        .textMuted,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                number,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w900,
                  color: selected
                      ? Colors.white
                      : AppColors
                      .textDark,
                ),
              ),
              if (month.isNotEmpty)
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: selected
                        ? Colors.white70
                        : AppColors
                        .textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _weekday(
      int value,
      ) {
    const days = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return days[value - 1];
  }

  static String _month(
      int value,
      ) {
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

    return months[value - 1];
  }
}

class _SingleReportCard
    extends StatelessWidget {
  final UserMedicalReport report;
  final bool selected;
  final VoidCallback onTap;

  const _SingleReportCard({
    required this.report,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(
        14,
      ),
      child: Container(
        padding: const EdgeInsets.all(
          12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(
            0xFFE8F5F1,
          )
              : AppColors.background,
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : const Color(
              0xFFE3E9E7,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons
                  .description_outlined,
              color:
              AppColors.primary,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                report.displayName,
                style:
                const TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  AppColors.textDark,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons
                    .check_circle_rounded,
                color:
                AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
