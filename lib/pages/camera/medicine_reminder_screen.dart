import 'package:flutter/material.dart';

import '../../service/medicine_reminder_service.dart';

class MedicineReminderScreen extends StatefulWidget {
  final Map<String, dynamic> medicine;
  final Map<String, dynamic> instructions;
  final List<Map<String, dynamic>> schedule;

  const MedicineReminderScreen({
    super.key,
    required this.medicine,
    required this.instructions,
    required this.schedule,
  });

  @override
  State<MedicineReminderScreen> createState() =>
      _MedicineReminderScreenState();
}

class _MedicineReminderScreenState
    extends State<MedicineReminderScreen> {
  final List<TimeOfDay> _times = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    for (final item in widget.schedule) {
      final parsed = _parseTime(
        item['time']?.toString(),
      );

      if (parsed != null) {
        _times.add(parsed);
      }
    }
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final parts = value.split(':');

    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    if (hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  String _medicineName() {
    final name =
    widget.medicine['name']?.toString().trim();

    if (name == null || name.isEmpty) {
      return 'Medicine';
    }

    return name;
  }

  String? _strength() {
    final value =
    widget.medicine['strength']?.toString().trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  Future<void> _changeTime(int index) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _times[index],
      helpText: 'Choose reminder time',
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _times[index] = selected;
    });
  }

  Future<void> _addTime() async {
    final now = TimeOfDay.now();

    final selected = await showTimePicker(
      context: context,
      initialTime: now,
      helpText: 'Add reminder time',
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _times.add(selected);
    });
  }

  void _removeTime(int index) {
    setState(() {
      _times.removeAt(index);
    });
  }

  Future<void> _saveReminders() async {
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No reminder times are available.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final allowed =
      await MedicineReminderService.instance
          .requestPermissions();

      if (!allowed) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission is required for medicine reminders.',
            ),
          ),
        );

        return;
      }

      final baseId =
          DateTime.now().millisecondsSinceEpoch %
              1000000;

      for (var i = 0; i < _times.length; i++) {
        final time = _times[i];

        String? label;

        if (i < widget.schedule.length) {
          label =
              widget.schedule[i]['label']?.toString();
        }

        await MedicineReminderService.instance
            .scheduleDailyMedicineReminder(
          id: baseId + i,
          medicineName: _medicineName(),
          strength: _strength(),
          hour: time.hour,
          minute: time.minute,
          label: label,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Medicine reminders saved.',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save reminder: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final frequency =
    widget.instructions['frequency']
        ?.toString()
        .trim();

    final mealRelation =
    widget.instructions['meal_relation']
        ?.toString()
        .trim();

    final duration =
    widget.instructions['duration']
        ?.toString()
        .trim();

    final medicineSubtitle = [
      _strength(),
      widget.medicine['form']?.toString(),
    ]
        .where(
          (value) =>
      value != null &&
          value.toString().trim().isNotEmpty,
    )
        .join(' • ');

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Medicine Reminder',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color:
                  const Color(0xFF06271F),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          15,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .medication_rounded,
                        color:
                        Color(0xFF5EE6B8),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            _medicineName(),
                            style:
                            const TextStyle(
                              color:
                              Colors.white,
                              fontSize: 19,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                          if (medicineSubtitle
                              .isNotEmpty) ...[
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              medicineSubtitle,
                              style:
                              const TextStyle(
                                color: Colors
                                    .white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (frequency != null &&
                  frequency.isNotEmpty) ...[
                const SizedBox(height: 20),
                _infoRow(
                  Icons.repeat_rounded,
                  'Frequency',
                  frequency,
                ),
              ],

              if (mealRelation != null &&
                  mealRelation.isNotEmpty) ...[
                const SizedBox(height: 10),
                _infoRow(
                  Icons.restaurant_rounded,
                  'Food',
                  mealRelation,
                ),
              ],

              if (duration != null &&
                  duration.isNotEmpty) ...[
                const SizedBox(height: 10),
                _infoRow(
                  Icons.calendar_month_rounded,
                  'Duration',
                  duration,
                ),
              ],

              const SizedBox(height: 24),

              const Text(
                'Reminder Times',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  Color(0xFF101828),
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Review any detected times, or add your own reminder time before saving.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color:
                  Color(0xFF667085),
                ),
              ),

              const SizedBox(height: 14),

              ...List.generate(
                _times.length,
                    (index) {
                  String label =
                      'Reminder ${index + 1}';

                  if (index <
                      widget.schedule.length) {
                    final value =
                    widget.schedule[index]
                    ['label']
                        ?.toString();

                    if (value != null &&
                        value.trim().isNotEmpty) {
                      label = value;
                    }
                  }

                  return _timeCard(
                    index,
                    label,
                  );
                },
              ),

              if (_times.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'No reminder time was detected. Add a time you want to be reminded.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF667085),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _addTime,
                  icon: const Icon(Icons.add_alarm_rounded),
                  label: const Text('Add reminder time'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF11786D),
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(
                      color: Color(0xFF11786D),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFFFF7E8),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons
                          .info_outline_rounded,
                      size: 20,
                      color:
                      Color(0xFFD88B00),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reminder times are convenience suggestions. Follow the instructions on the medicine or prescription.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color:
                          Color(0xFF694A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                  _saving
                      ? null
                      : _saveReminders,
                  icon: _saving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons
                        .notifications_active_rounded,
                  ),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : 'Save Reminder',
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                        0xFF11786D),
                    foregroundColor:
                    Colors.white,
                    minimumSize:
                    const Size.fromHeight(
                      54,
                    ),
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
      ),
    );
  }

  Widget _timeCard(
      int index,
      String label,
      ) {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color:
              const Color(0xFFE0F7F2),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.alarm_rounded,
              color:
              Color(0xFF11786D),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                  const TextStyle(
                    fontSize: 13,
                    color:
                    Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _times[index]
                      .format(context),
                  style:
                  const TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF101828),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              TextButton(
                onPressed: () => _changeTime(index),
                child: const Text('Change'),
              ),
              IconButton(
                onPressed: () => _removeTime(index),
                tooltip: 'Remove reminder time',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFF98A2B3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
            const Color(0xFF11786D),
            size: 21,
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style:
            const TextStyle(
              fontSize: 13,
              color:
              Color(0xFF667085),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign:
              TextAlign.right,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF101828),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
