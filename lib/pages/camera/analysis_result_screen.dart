import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'medicine_reminder_screen.dart';

class AnalysisResultScreen extends StatefulWidget {
  final String type;
  final Map<String, dynamic> result;

  const AnalysisResultScreen({
    super.key,
    required this.type,
    required this.result,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  int _selectedMedicineIndex = 0;
  bool _loadingMedicines = false;
  String? _medicineLoadError;
  List<Map<String, dynamic>> _savedMedicineEntries = [];

  String? _reportImageBase64;
  DateTime? _reportCreatedAt;
  DateTime? _reportUpdatedAt;
  bool _loadingReportSource = false;

  @override
  void initState() {
    super.initState();

    if (widget.type == 'medicine') {
      _loadSavedMedicines();
    }

    if (widget.type == 'report') {
      _loadReportSource();
    }
  }

  Future<void> _loadSavedMedicines() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _loadingMedicines = true;
      _medicineLoadError = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .where('status', isEqualTo: 'completed')
          .get();

      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aTime = a.data()['updatedAt'];
          final bTime = b.data()['updatedAt'];

          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }

          return 0;
        });

      final entries = <Map<String, dynamic>>[];

      for (final doc in docs) {
        final data = doc.data();
        final analysisData = data['analysis'];

        if (analysisData is! Map) {
          continue;
        }

        final analysis = Map<String, dynamic>.from(analysisData);
        final entry = _medicineEntryFromAnalysis(analysis);
        final medicine = entry['medicine'];

        if (medicine is Map &&
            [
              medicine['name'],
              medicine['generic_name'],
              medicine['strength'],
              medicine['form'],
            ].any(_hasValue)) {
          entries.add({
            ...entry,
            'document_id': doc.id,
          });
        }
      }

      if (!mounted) return;

      setState(() {
        _savedMedicineEntries = entries;
        _selectedMedicineIndex = 0;
        _loadingMedicines = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingMedicines = false;
        _medicineLoadError = e.toString();
      });
    }
  }

  Future<void> _loadReportSource() async {
    final user = FirebaseAuth.instance.currentUser;
    final reportData = widget.result['report'];

    if (user == null || reportData is! Map) {
      return;
    }

    final currentReport =
    Map<String, dynamic>.from(reportData);

    final currentTitle =
    currentReport['title']?.toString().trim();
    final currentDate =
    currentReport['report_date']?.toString().trim();
    final currentSummary =
    currentReport['summary']?.toString().trim();

    if (mounted) {
      setState(() {
        _loadingReportSource = true;
      });
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reports')
          .where('status', isEqualTo: 'completed')
          .get();

      QueryDocumentSnapshot<Map<String, dynamic>>? match;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final analysisData = data['analysis'];

        if (analysisData is! Map) {
          continue;
        }

        final analysis =
        Map<String, dynamic>.from(analysisData);

        final candidateData = analysis['report'];

        if (candidateData is! Map) {
          continue;
        }

        final candidate =
        Map<String, dynamic>.from(candidateData);

        final candidateTitle =
        candidate['title']?.toString().trim();
        final candidateDate =
        candidate['report_date']?.toString().trim();
        final candidateSummary =
        candidate['summary']?.toString().trim();

        final sameTitle =
            currentTitle != null &&
                currentTitle.isNotEmpty &&
                candidateTitle == currentTitle;

        final sameDate =
            currentDate != null &&
                currentDate.isNotEmpty &&
                candidateDate == currentDate;

        final sameSummary =
            currentSummary != null &&
                currentSummary.isNotEmpty &&
                candidateSummary == currentSummary;

        if ((sameTitle && sameDate) ||
            (sameTitle && sameSummary) ||
            (sameDate && sameSummary)) {
          match = doc;
          break;
        }
      }

      if (match == null || !mounted) {
        if (mounted) {
          setState(() {
            _loadingReportSource = false;
          });
        }
        return;
      }

      final data = match.data();

      setState(() {
        final image = data['imageBase64'];
        _reportImageBase64 =
        image is String && image.trim().isNotEmpty
            ? image.trim()
            : null;

        final createdAt = data['createdAt'];
        final updatedAt = data['updatedAt'];

        _reportCreatedAt =
        createdAt is Timestamp
            ? createdAt.toDate()
            : null;

        _reportUpdatedAt =
        updatedAt is Timestamp
            ? updatedAt.toDate()
            : null;

        _loadingReportSource = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingReportSource = false;
      });
    }
  }

  String get type => widget.type;
  Map<String, dynamic> get result => widget.result;

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
              if (type != 'medicine' && type != 'report') ...[
                _buildHeaderCard(),
                const SizedBox(height: 18),
              ],

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

    final uncertainFields =
    report['uncertain_fields'] is List
        ? (report['uncertain_fields'] as List)
        .where(_hasValue)
        .map(
          (item) =>
          _humanizeReportField(
            item.toString(),
          ),
    )
        .toList()
        : <String>[];

    final title = _hasValue(report['title'])
        ? report['title'].toString().trim()
        : 'Medical Report';

    final reportDate =
    _hasValue(report['report_date'])
        ? report['report_date']
        .toString()
        .trim()
        : 'Date not available';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reportHero(
          title: title,
          reportDate: reportDate,
        ),

        const SizedBox(height: 22),

        _sectionTitle('Report Information'),
        _reportInformationCard(report),

        if (results is List &&
            results.isNotEmpty) ...[
          const SizedBox(height: 22),
          _sectionTitle('Test Results'),
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

        const SizedBox(height: 22),

        _sectionTitle('Summary'),
        _reportSummaryCard(
          report['summary']?.toString() ??
              'No summary available.',
        ),

        if (uncertainFields.isNotEmpty) ...[
          const SizedBox(height: 22),
          _sectionTitle('Needs Confirmation'),
          _reportNeedsConfirmationCard(
            uncertainFields,
          ),
        ],

        if (_loadingReportSource ||
            _reportImageBase64 != null) ...[
          const SizedBox(height: 22),
          _sectionTitle('Original Report'),
          _originalReportCard(),
        ],

        if (_reportCreatedAt != null ||
            _reportUpdatedAt != null) ...[
          const SizedBox(height: 22),
          _sectionTitle('Analysis Details'),
          _reportAnalysisDetailsCard(),
        ],

        const SizedBox(height: 16),

        _disclaimerCard(
          'This analysis explains information visible in the report. It is informational and does not diagnose a medical condition.',
        ),
      ],
    );
  }

  Widget _reportHero({
    required String title,
    required String reportDate,
  }) {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final compact =
            constraints.maxWidth < 350;

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: compact ? 154 : 170,
          ),
          padding: EdgeInsets.all(
            compact ? 16 : 20,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE7F7F2),
                Color(0xFFD7F0E8),
              ],
            ),
            borderRadius:
            BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -54,
                top: -72,
                child: Container(
                  width: compact ? 170 : 210,
                  height: compact ? 170 : 210,
                  decoration: BoxDecoration(
                    color:
                    Colors.white.withOpacity(
                      0.38,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  const Text(
                    'REPORT ANALYSIS',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1.1,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      Color(0xFF11786D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize:
                      compact ? 24 : 28,
                      height: 1.05,
                      fontWeight:
                      FontWeight.w900,
                      letterSpacing: -0.4,
                      color:
                      const Color(
                        0xFF101828,
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    reportDate,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      Color(0xFF475467),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reportInformationCard(
      Map<String, dynamic> report,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(16),
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
          _reportInfoLine(
            'Title',
            report['title'],
          ),
          _reportDivider(),
          _reportInfoLine(
            'Lab',
            report['lab_name'],
          ),
          _reportDivider(),
          _reportInfoLine(
            'Report Date',
            report['report_date'],
          ),
        ],
      ),
    );
  }

  Widget _reportInfoLine(
      String label,
      dynamic value,
      ) {
    final display =
    value?.toString().trim();

    final missing =
        display == null ||
            display.isEmpty ||
            display.toLowerCase() == 'null';

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color:
              Color(0xFF667085),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            missing
                ? 'Not available'
                : display,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.3,
              fontWeight:
              FontWeight.w700,
              color: missing
                  ? const Color(
                0xFF98A2B3,
              )
                  : const Color(
                0xFF101828,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reportSummaryCard(
      String summary,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(16),
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
      child: Text(
        summary,
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.55,
          color:
          Color(0xFF344054),
        ),
      ),
    );
  }

  Widget _reportNeedsConfirmationCard(
      List<String> items,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
        const Color(0xFFFFF7E8),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Some details could not be read clearly from the report.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF694A00),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
                (item) => Padding(
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
                      top: 7,
                    ),
                    child: CircleAvatar(
                      radius: 2.5,
                      backgroundColor:
                      Color(
                        0xFFD88B00,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item,
                      style:
                      const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color:
                        Color(
                          0xFF694A00,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _originalReportCard() {
    if (_loadingReportSource) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(20),
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
        child: const Center(
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    final imageBase64 =
        _reportImageBase64;

    if (imageBase64 == null) {
      return const SizedBox.shrink();
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Scanned report',
            style: TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'View the image used for this analysis.',
            style: TextStyle(
              fontSize: 11.5,
              color:
              Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                _openOriginalReport(
                  imageBase64,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor:
                const Color(
                  0xFF11786D,
                ),
                side: const BorderSide(
                  color:
                  Color(
                    0xFFB9DCD2,
                  ),
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              child: const Text(
                'View Original Report',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportAnalysisDetailsCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(16),
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
          if (_reportCreatedAt != null)
            _reportDetailLine(
              'Uploaded',
              _formatReportTimestamp(
                _reportCreatedAt!,
              ),
            ),
          if (_reportCreatedAt != null &&
              _reportUpdatedAt != null)
            _reportDivider(),
          if (_reportUpdatedAt != null)
            _reportDetailLine(
              'Analysis completed',
              _formatReportTimestamp(
                _reportUpdatedAt!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _reportDetailLine(
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color:
              Color(0xFF667085),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight:
            FontWeight.w700,
            color:
            Color(0xFF101828),
          ),
        ),
      ],
    );
  }

  Future<void> _openOriginalReport(
      String imageBase64,
      ) async {
    try {
      final bytes =
      base64Decode(imageBase64);

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor:
            const Color(
              0xFF101828,
            ),
            appBar: AppBar(
              backgroundColor:
              const Color(
                0xFF101828,
              ),
              foregroundColor:
              Colors.white,
              surfaceTintColor:
              const Color(
                0xFF101828,
              ),
              title: const Text(
                'Original Report',
              ),
            ),
            body: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(
                child: Image.memory(
                  bytes,
                  fit:
                  BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the original report image.',
          ),
        ),
      );
    }
  }

  String _humanizeReportField(
      String value,
      ) {
    final cleaned = value
        .replaceAll('_', ' ')
        .trim()
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (cleaned.isEmpty) {
      return value;
    }

    return cleaned[0].toUpperCase() +
        cleaned.substring(1);
  }

  String _formatReportTimestamp(
      DateTime date,
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

    final hour =
    date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute =
    date.minute
        .toString()
        .padLeft(2, '0');

    final period =
    date.hour >= 12
        ? 'PM'
        : 'AM';

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year} • '
        '$hour:$minute $period';
  }

  Widget _reportResultCard(
      Map<String, dynamic> item,
      ) {
    final testName =
    _hasValue(item['test_name'])
        ? item['test_name']
        .toString()
        .trim()
        : 'Test';

    final value =
    _hasValue(item['value'])
        ? item['value']
        .toString()
        .trim()
        : '—';

    final unit =
    _hasValue(item['unit'])
        ? item['unit']
        .toString()
        .trim()
        : '';

    final range =
    _hasValue(
      item['reference_range'],
    )
        ? item['reference_range']
        .toString()
        .trim()
        : null;

    final flag =
    _hasValue(
      item['printed_flag'],
    )
        ? item['printed_flag']
        .toString()
        .trim()
        : null;

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const EdgeInsets.all(16),
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  testName,
                  style:
                  const TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(
                      0xFF475467,
                    ),
                  ),
                ),
              ),
              if (flag != null)
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFFFF2D9,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(20),
                  ),
                  child: Text(
                    flag,
                    style:
                    const TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                      FontWeight.w700,
                      color:
                      Color(
                        0xFF694A00,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            unit.isEmpty
                ? value
                : '$value $unit',
            style: const TextStyle(
              fontSize: 24,
              height: 1.05,
              fontWeight:
              FontWeight.w900,
              color:
              Color(0xFF06271F),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Reference range',
                  style: TextStyle(
                    fontSize: 11.5,
                    color:
                    Color(
                      0xFF667085,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  range ??
                      'Not available',
                  textAlign:
                  TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                    FontWeight.w700,
                    color: range == null
                        ? const Color(
                      0xFF98A2B3,
                    )
                        : const Color(
                      0xFF475467,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  Widget _medicineMainCard(
      Map<String, dynamic> medicine,
      ) {
    final name = _hasValue(medicine['name'])
        ? medicine['name'].toString().trim()
        : 'Medicine';

    final genericName = _hasValue(medicine['generic_name'])
        ? medicine['generic_name'].toString().trim()
        : null;

    final details = <String>[];

    if (_hasValue(medicine['strength'])) {
      details.add(medicine['strength'].toString().trim());
    }

    if (_hasValue(medicine['form'])) {
      details.add(medicine['form'].toString().trim());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 350;

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: compact ? 178 : 196,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE6F7F1),
                Color(0xFFD5F0E7),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -42,
                top: -52,
                child: Container(
                  width: compact ? 170 : 200,
                  height: compact ? 170 : 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.42),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 20,
                  compact ? 18 : 22,
                  compact ? 16 : 20,
                  compact ? 18 : 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'MEDICINE ANALYSIS',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF11786D),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 24 : 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    if (genericName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        genericName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475467),
                        ),
                      ),
                    ],
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          details.join(' • '),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF11786D),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _medicineEntryFromAnalysis(
      Map<String, dynamic> analysis,
      ) {
    final medicineData = analysis['medicine'];
    final instructionsData = analysis['instructions'];
    final scheduleData = analysis['suggested_schedule'];

    return <String, dynamic>{
      'medicine': medicineData is Map
          ? Map<String, dynamic>.from(medicineData)
          : <String, dynamic>{},
      'instructions': instructionsData is Map
          ? Map<String, dynamic>.from(instructionsData)
          : <String, dynamic>{},
      'suggested_schedule': scheduleData is List
          ? scheduleData
          : <dynamic>[],
      'general_information': analysis['general_information'] is List
          ? analysis['general_information']
          : <dynamic>[],
      'uncertain_fields': analysis['uncertain_fields'] is List
          ? analysis['uncertain_fields']
          : <dynamic>[],
      'doctor_name': analysis['doctor_name'],
      'schedule_note': analysis['schedule_note'],
      'requires_user_confirmation':
      analysis['requires_user_confirmation'] == true,
    };
  }

  List<Map<String, dynamic>> _medicineEntries() {
    if (_savedMedicineEntries.isNotEmpty) {
      return _savedMedicineEntries;
    }

    // Immediate fallback while Firestore is loading, or if there are no
    // previously completed medicine records yet.
    return [_medicineEntryFromAnalysis(result)];
  }

  String _medicineDropdownLabel(
      Map<String, dynamic> medicine,
      int index,
      ) {
    final name = _hasValue(medicine['name'])
        ? medicine['name'].toString()
        : 'Medicine ${index + 1}';

    final details = <String>[];

    if (_hasValue(medicine['strength'])) {
      details.add(medicine['strength'].toString());
    }

    if (_hasValue(medicine['form'])) {
      details.add(medicine['form'].toString());
    }

    return details.isEmpty
        ? name
        : '$name — ${details.join(' • ')}';
  }

  Widget _medicineDropdown(
      List<Map<String, dynamic>> entries,
      int safeIndex,
      ) {
    return DropdownButtonFormField<int>(
      value: safeIndex,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Choose medicine',
        prefixIcon: const Icon(
          Icons.medication_rounded,
          color: Color(0xFF11786D),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE4E7EC),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE4E7EC),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF11786D),
            width: 1.5,
          ),
        ),
      ),
      items: List.generate(
        entries.length,
            (index) {
          final rawMedicine = entries[index]['medicine'];
          final medicine = rawMedicine is Map
              ? Map<String, dynamic>.from(rawMedicine)
              : <String, dynamic>{};

          return DropdownMenuItem<int>(
            value: index,
            child: Text(
              _medicineDropdownLabel(medicine, index),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
      onChanged: (index) {
        if (index == null) return;

        setState(() {
          _selectedMedicineIndex = index;
        });
      },
    );
  }

  Widget _buildMedicineResult(BuildContext context) {
    final entries = _medicineEntries();

    if (entries.isEmpty) {
      return _emptyState(
        'Medicine information could not be identified reliably.',
      );
    }

    final safeIndex =
    _selectedMedicineIndex < entries.length ? _selectedMedicineIndex : 0;

    final selectedEntry = entries[safeIndex];

    final medicineData = selectedEntry['medicine'];
    final instructionsData = selectedEntry['instructions'];
    final scheduleData = selectedEntry['suggested_schedule'];

    final medicine = medicineData is Map
        ? Map<String, dynamic>.from(medicineData)
        : <String, dynamic>{};

    final instructions = instructionsData is Map
        ? Map<String, dynamic>.from(instructionsData)
        : <String, dynamic>{};

    final schedule = scheduleData is List
        ? scheduleData
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
        : <Map<String, dynamic>>[];

    final explicitTimes = instructions['explicit_times'] is List
        ? (instructions['explicit_times'] as List)
        .where(_hasValue)
        .map((item) => item.toString())
        .toList()
        : <String>[];

    final generalInformation = selectedEntry['general_information'] is List
        ? (selectedEntry['general_information'] as List)
        .where(_hasValue)
        .map((item) => item.toString())
        .toList()
        : <String>[];

    final uncertainFields = selectedEntry['uncertain_fields'] is List
        ? (selectedEntry['uncertain_fields'] as List)
        .where(_hasValue)
        .map((item) => item.toString())
        .toList()
        : <String>[];

    final doctorName = _hasValue(selectedEntry['doctor_name'])
        ? selectedEntry['doctor_name'].toString().trim()
        : null;

    final scheduleNote = _hasValue(selectedEntry['schedule_note'])
        ? selectedEntry['schedule_note'].toString().trim()
        : null;

    final requiresConfirmation =
        selectedEntry['requires_user_confirmation'] == true;

    final hasMedicineInfo = [
      medicine['name'],
      medicine['generic_name'],
      medicine['strength'],
      medicine['form'],
    ].any(_hasValue);

    final hasQuickSummary = [
      instructions['dose'],
      instructions['frequency'],
      instructions['duration'],
    ].any(_hasValue);

    final hasHowToTake = [
      instructions['dose'],
      instructions['frequency'],
      instructions['meal_relation'],
    ].any(_hasValue) ||
        explicitTimes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loadingMedicines) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 14),
        ],

        if (_medicineLoadError != null) ...[
          _disclaimerCard(
            'Could not load your saved medicines. Showing the medicine from this scan.',
          ),
          const SizedBox(height: 14),
        ],

        if (entries.length > 1) ...[
          _sectionTitle('Choose Medicine'),
          _medicineDropdown(entries, safeIndex),
          const SizedBox(height: 16),
        ],

        if (hasMedicineInfo)
          _medicineMainCard(medicine)
        else
          _emptyState(
            'Medicine information could not be identified reliably.',
          ),

        if (hasQuickSummary) ...[
          const SizedBox(height: 20),
          _sectionTitle('Quick Summary'),
          _medicineQuickSummary(
            dose: instructions['dose'],
            frequency: instructions['frequency'],
            duration: instructions['duration'],
          ),
        ],

        if (hasHowToTake) ...[
          const SizedBox(height: 22),
          _sectionTitle('How to Take'),
          _medicineHowToTakeCard(
            dose: instructions['dose'],
            frequency: instructions['frequency'],
            mealRelation: instructions['meal_relation'],
            explicitTimes: explicitTimes,
          ),
        ],

        if (doctorName != null) ...[
          const SizedBox(height: 22),
          _sectionTitle('Prescription Information'),
          _infoCard(
            children: [
              _infoRow('Doctor', doctorName),
            ],
          ),
        ],

        if (schedule.isNotEmpty || hasMedicineInfo) ...[
          const SizedBox(height: 22),
          _sectionTitle('Medicine Reminder'),
          _medicineReminderCard(
            context: context,
            medicine: medicine,
            instructions: instructions,
            schedule: schedule,
            scheduleNote: scheduleNote,
          ),
        ],

        if (generalInformation.isNotEmpty) ...[
          const SizedBox(height: 22),
          _sectionTitle('General Information'),
          _listCard(generalInformation),
        ],

        if (uncertainFields.isNotEmpty) ...[
          const SizedBox(height: 22),
          _sectionTitle('Needs Confirmation'),
          _listCard(uncertainFields),
        ],

        const SizedBox(height: 16),

        _disclaimerCard(
          requiresConfirmation
              ? 'Some details could not be confirmed from the scan. Review them against the prescription or medicine package before using reminders.'
              : 'Medicine information is shown for reference only. Follow the prescription or instructions from a qualified healthcare professional.',
        ),
      ],
    );
  }

  Widget _medicineQuickSummary({
    required dynamic dose,
    required dynamic frequency,
    required dynamic duration,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 350;
        final gap = compact ? 7.0 : 9.0;

        return Row(
          children: [
            Expanded(
              child: _medicineSummaryTile(
                icon: Icons.medication_outlined,
                label: 'Dose',
                value: _hasValue(dose) ? dose.toString() : '—',
                compact: compact,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _medicineSummaryTile(
                icon: Icons.repeat_rounded,
                label: 'Frequency',
                value: _hasValue(frequency) ? frequency.toString() : '—',
                compact: compact,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _medicineSummaryTile(
                icon: Icons.calendar_month_outlined,
                label: 'Duration',
                value: _hasValue(duration) ? duration.toString() : '—',
                compact: compact,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _medicineSummaryTile({
    required IconData icon,
    required String label,
    required String value,
    required bool compact,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: EdgeInsets.all(compact ? 9 : 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5EAE8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 29 : 32,
            height: compact ? 29 : 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F7F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: compact ? 15 : 17,
              color: const Color(0xFF11786D),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 9.5 : 10.5,
              color: const Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 12.5 : 13.5,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicineHowToTakeCard({
    required dynamic dose,
    required dynamic frequency,
    required dynamic mealRelation,
    required List<String> explicitTimes,
  }) {
    final rows = <Widget>[];

    void addRow(IconData icon, String label, String value) {
      if (rows.isNotEmpty) {
        rows.add(_medicineDivider());
      }
      rows.add(
        _medicineInstructionRow(
          icon: icon,
          label: label,
          value: value,
        ),
      );
    }

    if (_hasValue(dose)) {
      addRow(
        Icons.medication_outlined,
        'Dose',
        dose.toString(),
      );
    }

    if (_hasValue(frequency)) {
      addRow(
        Icons.repeat_rounded,
        'Frequency',
        frequency.toString(),
      );
    }

    if (_hasValue(mealRelation)) {
      addRow(
        Icons.restaurant_outlined,
        'Meal relation',
        mealRelation.toString(),
      );
    }

    if (explicitTimes.isNotEmpty) {
      addRow(
        Icons.schedule_outlined,
        'Printed times',
        explicitTimes.map(_formatMedicineTime).join(', '),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5EAE8),
        ),
      ),
      child: Column(children: rows),
    );
  }

  Widget _medicineInstructionRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 19,
            color: const Color(0xFF11786D),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101828),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _medicineDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 11),
      child: Divider(
        height: 1,
        color: Color(0xFFE9EEEC),
      ),
    );
  }

  Widget _medicineReminderCard({
    required BuildContext context,
    required Map<String, dynamic> medicine,
    required Map<String, dynamic> instructions,
    required List<Map<String, dynamic>> schedule,
    required String? scheduleNote,
  }) {
    final firstTime =
    schedule.isNotEmpty && _hasValue(schedule.first['time'])
        ? _formatMedicineTime(schedule.first['time'].toString())
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xFF11786D),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstTime == null
                          ? 'No reminder scheduled'
                          : 'Detected reminder schedule',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      firstTime == null
                          ? 'You can create reminder times from the detected medicine information.'
                          : schedule.length == 1
                          ? firstTime
                          : '$firstTime and ${schedule.length - 1} more',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_hasValue(scheduleNote)) ...[
            const SizedBox(height: 12),
            Text(
              scheduleNote!,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Color(0xFF667085),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
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
                Icons.notifications_none_rounded,
              ),
              label: Text(
                schedule.isNotEmpty
                    ? 'Review & Set Reminder'
                    : 'Set Reminder',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF11786D),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
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



  Widget _reportDivider() {
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
