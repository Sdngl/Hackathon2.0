import 'package:flutter/material.dart';

import 'medicine_reminder_screen.dart';

class AnalysisResultScreen extends StatelessWidget {
  final String type;
  final Map<String, dynamic> result;

  const AnalysisResultScreen({
    super.key,
    required this.type,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          _screenTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),

              const SizedBox(height: 18),

              if (type == 'report')
                _buildReportResult(),

              if (type == 'medicine')
                _buildMedicineResult(context),

              if (type == 'meal')
                _buildMealResult(),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF06271F),
                    foregroundColor: Colors.white,
                    minimumSize:
                    const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
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

  String get _screenTitle {
    switch (type) {
      case 'meal':
        return 'Meal Analysis';

      case 'medicine':
        return 'Medicine Analysis';

      case 'report':
        return 'Report Analysis';

      default:
        return 'Analysis Result';
    }
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF06271F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.12,
              ),
              borderRadius:
              BorderRadius.circular(15),
            ),
            child: Icon(
              _headerIcon,
              color: const Color(0xFF5EE6B8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _screenTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'AI-assisted analysis',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF5EE6B8),
          ),
        ],
      ),
    );
  }

  IconData get _headerIcon {
    switch (type) {
      case 'meal':
        return Icons.restaurant_rounded;

      case 'medicine':
        return Icons.medication_rounded;

      case 'report':
        return Icons.description_rounded;

      default:
        return Icons.auto_awesome_rounded;
    }
  }


  Widget _buildReportResult() {
    final reportData = result['report'];

    if (reportData is! Map) {
      return _emptyState(
        'No report information was returned.',
      );
    }

    final report =
    Map<String, dynamic>.from(reportData);

    final results = report['results'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Report Information',
        ),

        _infoCard(
          children: [
            _infoRow(
              'Title',
              report['title'],
            ),
            _infoRow(
              'Lab',
              report['lab_name'],
            ),
            _infoRow(
              'Report Date',
              report['report_date'],
            ),
          ],
        ),

        const SizedBox(height: 18),

        if (results is List &&
            results.isNotEmpty) ...[
          _sectionTitle(
            'Test Results',
          ),

          ...results.map(
                (item) {
              if (item is! Map) {
                return const SizedBox.shrink();
              }

              return _reportResultCard(
                Map<String, dynamic>.from(
                  item,
                ),
              );
            },
          ),
        ],

        const SizedBox(height: 18),

        _sectionTitle(
          'Summary',
        ),

        _textCard(
          report['summary']?.toString() ??
              'No summary available.',
        ),

        if (report['uncertain_fields']
        is List &&
            (report['uncertain_fields'] as List)
                .isNotEmpty) ...[
          const SizedBox(height: 18),

          _sectionTitle(
            'Needs Review',
          ),

          _listCard(
            report['uncertain_fields']
            as List,
          ),
        ],

        const SizedBox(height: 14),

        _disclaimerCard(
          'This explanation is informational and does not diagnose a medical condition.',
        ),
      ],
    );
  }

  Widget _reportResultCard(
      Map<String, dynamic> item,
      ) {
    final value =
        item['value']?.toString() ?? '—';

    final unit =
        item['unit']?.toString() ?? '';

    final range =
    item['reference_range']
        ?.toString();

    final flag =
    item['printed_flag']
        ?.toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            item['test_name']?.toString() ??
                'Test',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  unit.isEmpty
                      ? value
                      : '$value $unit',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF06271F),
                  ),
                ),
              ),

              if (flag != null &&
                  flag.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                        0xFFFFF2D9),
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    flag,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          if (range != null &&
              range.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reference: $range',
              style: const TextStyle(
                color:
                Color(0xFF667085),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _medicineScheduleCard(
      Map<String, dynamic> item,
      ) {
    final rawTime =
        item['time']?.toString() ?? '';

    final label =
    item['label']?.toString().trim();

    final basis =
    item['basis']?.toString().trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Color(0xFF11786D),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  _formatMedicineTime(rawTime),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
                  ),
                ),

                if (label != null &&
                    label.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF11786D),
                    ),
                  ),
                ],

                if (basis != null &&
                    basis.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    basis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF98A2B3),
          ),
        ],
      ),
    );
  }
  String _formatMedicineTime(
      String time,
      ) {
    final parts = time.split(':');

    if (parts.length != 2) {
      return time;
    }

    final hour =
    int.tryParse(parts[0]);

    final minute =
    int.tryParse(parts[1]);

    if (hour == null ||
        minute == null) {
      return time;
    }

    final period =
    hour >= 12 ? 'PM' : 'AM';

    var displayHour =
        hour % 12;

    if (displayHour == 0) {
      displayHour = 12;
    }

    final displayMinute =
    minute.toString().padLeft(
      2,
      '0',
    );

    return '$displayHour:$displayMinute $period';
  }
  void _showReminderComingNext(
      BuildContext context,
      Map<String, dynamic> medicine,
      List<Map<String, dynamic>> schedule,
      ) {
    final medicineName =
        medicine['name']?.toString() ??
            'Medicine';

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medicine Reminder',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  medicineName,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                  ),
                ),

                const SizedBox(height: 18),

                ...schedule.map(
                      (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor:
                      Color(0xFFE0F7F2),
                      child: Icon(
                        Icons.alarm_rounded,
                        color:
                        Color(0xFF11786D),
                      ),
                    ),
                    title: Text(
                      _formatMedicineTime(
                        item['time']
                            ?.toString() ??
                            '',
                      ),
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    subtitle: _hasValue(
                      item['label'],
                    )
                        ? Text(
                      item['label']
                          .toString(),
                    )
                        : null,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Continue',
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
  Widget _medicineMainCard(
      Map<String, dynamic> medicine,
      ) {
    final name = _hasValue(medicine['name'])
        ? medicine['name'].toString()
        : 'Medicine';

    final details = <String>[];

    if (_hasValue(medicine['strength'])) {
      details.add(
        medicine['strength'].toString(),
      );
    }

    if (_hasValue(medicine['form'])) {
      details.add(
        medicine['form'].toString(),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: Color(0xFF11786D),
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
                  ),
                ),

                if (details.isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Text(
                    details.join(' • '),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF667085),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                if (_hasValue(
                  medicine['generic_name'],
                )) ...[
                  const SizedBox(height: 8),

                  Text(
                    'Generic: ${medicine['generic_name']}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475467),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMedicineResult(BuildContext context) {
    final medicineData = result['medicine'];
    final instructionsData = result['instructions'];
    final scheduleData = result['suggested_schedule'];

    final medicine = medicineData is Map
        ? Map<String, dynamic>.from(medicineData)
        : <String, dynamic>{};

    final instructions = instructionsData is Map
        ? Map<String, dynamic>.from(instructionsData)
        : <String, dynamic>{};

    final schedule = scheduleData is List
        ? scheduleData
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList()
        : <Map<String, dynamic>>[];

    final hasMedicineInfo = [
      medicine['name'],
      medicine['generic_name'],
      medicine['strength'],
      medicine['form'],
    ].any(_hasValue);

    final hasInstructions = [
      instructions['dose'],
      instructions['frequency'],
      instructions['duration'],
      instructions['meal_relation'],
    ].any(_hasValue);

    final generalInformation =
    result['general_information']?.toString().trim();

    final uncertainFields =
    result['uncertain_fields'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        if (hasMedicineInfo)
          _medicineMainCard(medicine),


        if (hasInstructions) ...[
          const SizedBox(height: 22),

          _sectionTitle(
            'How to Take',
          ),

          _infoCard(
            children: [
              if (_hasValue(instructions['dose']))
                _infoRow(
                  'Dose',
                  instructions['dose'],
                ),

              if (_hasValue(instructions['frequency']))
                _infoRow(
                  'Frequency',
                  instructions['frequency'],
                ),

              if (_hasValue(instructions['duration']))
                _infoRow(
                  'Duration',
                  instructions['duration'],
                ),

              if (_hasValue(instructions['meal_relation']))
                _infoRow(
                  'With Food',
                  instructions['meal_relation'],
                ),
            ],
          ),
        ],


        if (instructions['explicit_times'] is List &&
            (instructions['explicit_times'] as List)
                .where(_hasValue)
                .isNotEmpty) ...[
          const SizedBox(height: 22),

          _sectionTitle(
            'Printed Times',
          ),

          _listCard(
            (instructions['explicit_times'] as List)
                .where(_hasValue)
                .toList(),
          ),
        ],


        if (schedule.isNotEmpty) ...[
          const SizedBox(height: 22),

          _sectionTitle(
            'Suggested Times',
          ),

          ...schedule.map(
                (item) => _medicineScheduleCard(item),
          ),

          const SizedBox(height: 6),

          _scheduleInfoCard(
            result['schedule_note']?.toString(),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MedicineReminderScreen(
                      medicine: medicine,
                      instructions: instructions,
                      schedule: schedule,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_active_outlined,
              ),
              label: const Text(
                'Set Medicine Reminder',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF11786D),
                foregroundColor: Colors.white,
                minimumSize:
                const Size.fromHeight(54),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],


        if (generalInformation != null &&
            generalInformation.isNotEmpty) ...[
          const SizedBox(height: 22),

          _sectionTitle(
            'About This Medicine',
          ),

          _textCard(
            generalInformation,
          ),
        ],


        if (uncertainFields is List &&
            uncertainFields.where(_hasValue).isNotEmpty) ...[
          const SizedBox(height: 22),

          _sectionTitle(
            'Please Confirm',
          ),

          _listCard(
            uncertainFields
                .where(_hasValue)
                .toList(),
          ),
        ],

        const SizedBox(height: 16),

        _disclaimerCard(
          'Reminder times are suggestions based on the instructions detected from the medicine. Follow the prescription or guidance from a qualified healthcare professional.',
        ),
      ],
    );
  }


  bool _hasValue(dynamic value) {
    if (value == null) {
      return false;
    }

    if (value is String) {
      final text = value.trim().toLowerCase();

      return text.isNotEmpty &&
          text != 'null' &&
          text != 'not available' &&
          text != 'unknown' &&
          text != 'n/a';
    }

    if (value is Iterable) {
      return value.isNotEmpty;
    }

    return true;
  }

  Widget _scheduleInfoCard(String? message) {
    final text = _hasValue(message)
        ? message!.trim()
        : 'Suggested reminder times based on the detected medicine instructions. Review them before creating reminders.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 19,
            color: Color(0xFF11786D),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF475467),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMealResult() {
    final foodsData = result['foods'];
    final nutritionData =
    result['nutrition'];

    final nutrition =
    nutritionData is Map
        ? Map<String, dynamic>.from(
      nutritionData,
    )
        : <String, dynamic>{};

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Detected Foods',
        ),

        if (foodsData is List &&
            foodsData.isNotEmpty)
          ...foodsData.map(
                (item) {
              if (item is! Map) {
                return const SizedBox.shrink();
              }

              return _foodCard(
                Map<String, dynamic>.from(
                  item,
                ),
              );
            },
          )
        else
          _emptyState(
            'No foods were detected.',
          ),

        const SizedBox(height: 18),

        _sectionTitle(
          'Estimated Nutrition',
        ),

        GridView.count(
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _nutritionCard(
              'Calories',
              nutrition[
              'estimated_calories_kcal'],
              'kcal',
            ),
            _nutritionCard(
              'Protein',
              nutrition[
              'estimated_protein_g'],
              'g',
            ),
            _nutritionCard(
              'Carbs',
              nutrition[
              'estimated_carbs_g'],
              'g',
            ),
            _nutritionCard(
              'Fat',
              nutrition[
              'estimated_fat_g'],
              'g',
            ),
          ],
        ),

        if (result['notes'] is List &&
            (result['notes'] as List)
                .isNotEmpty) ...[
          const SizedBox(height: 18),

          _sectionTitle(
            'Notes',
          ),

          _listCard(
            result['notes'] as List,
          ),
        ],

        const SizedBox(height: 14),

        _disclaimerCard(
          'Meal nutrition values are estimates based on what was visible in the image.',
        ),
      ],
    );
  }

  Widget _foodCard(
      Map<String, dynamic> food,
      ) {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor:
            Color(0xFFE8F8F2),
            child: Icon(
              Icons.restaurant_rounded,
              color: Color(0xFF07966A),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  food['name']?.toString() ??
                      'Food',
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  [
                    food['estimated_portion'],
                    food['estimated_grams'] != null
                        ? '${food['estimated_grams']} g'
                        : null,
                  ]
                      .where(
                        (value) =>
                    value != null,
                  )
                      .join(' • '),
                  style: const TextStyle(
                    color:
                    Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionCard(
      String label,
      dynamic value,
      String unit,
      ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Text(
            value == null
                ? '—'
                : '$value $unit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF06271F),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: const TextStyle(
              color:
              Color(0xFF667085),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }


  Widget _sectionTitle(
      String text,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight:
          FontWeight.w700,
          color: Color(0xFF101828),
        ),
      ),
    );
  }

  Widget _infoCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _infoRow(
      String label,
      dynamic value,
      ) {
    final display =
    value?.toString().trim();

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color:
                Color(0xFF667085),
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            child: Text(
              display == null ||
                  display.isEmpty
                  ? 'Not available'
                  : display,
              style: const TextStyle(
                fontWeight:
                FontWeight.w600,
                color:
                Color(0xFF101828),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textCard(
      String text,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF344054),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _listCard(
      List items,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: items.map(
              (item) {
            return Padding(
              padding:
              const EdgeInsets.only(
                bottom: 8,
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding:
                    EdgeInsets.only(
                      top: 6,
                    ),
                    child: CircleAvatar(
                      radius: 3,
                      backgroundColor:
                      Color(
                          0xFF07966A),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      item.toString(),
                    ),
                  ),
                ],
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _disclaimerCard(
      String text,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD88B00),
            size: 20,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF694A00),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(
      String text,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF667085),
        ),
      ),
    );
  }
}
