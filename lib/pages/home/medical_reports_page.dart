import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../service/analysis_api_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../camera/camera.dart';
import '../camera/analysis_result_screen.dart';

class MedicalReportsPage extends StatefulWidget {
  const MedicalReportsPage({super.key});

  @override
  State<MedicalReportsPage> createState() => _MedicalReportsPageState();
}

class _MedicalReportsPageState extends State<MedicalReportsPage> {
  final AnalysisApiService _api = AnalysisApiService();

  bool _isUploading = false;

  Future<void> _openCamera() async {
    PermissionStatus status = await Permission.camera.status;

    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (!mounted) return;

    if (status.isGranted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const Camera(),
        ),
      );

      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Camera permission required',
          ),
          content: const Text(
            'Without camera permission, we cannot continue with scanning the medical report.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            if (status.isPermanentlyDenied)
              FilledButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  await openAppSettings();
                },
                child: const Text(
                  'Open Settings',
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickPdf() async {
    if (_isUploading) return;

    final pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (pickedFile == null) {
      return;
    }

    final filePath = pickedFile.path;

    if (filePath == null || filePath.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not access the selected PDF.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await _api.analyzeReportFile(
        filePath: filePath,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report analyzed successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not analyze report: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _openUploadOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (bottomContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              4,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.picture_as_pdf_outlined,
                  ),
                  title: const Text(
                    'Choose PDF',
                  ),
                  subtitle: const Text(
                    'Upload a medical report from your device',
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomContext,
                    );

                    _pickPdf();
                  },
                ),

                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                  ),
                  title: const Text(
                    'Scan with camera',
                  ),
                  subtitle: const Text(
                    'Take a photo of a medical report',
                  ),
                  onTap: () {
                    Navigator.pop(bottomContext);

                    _openCamera();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _reportsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('reports')
        .where(
      'status',
      isEqualTo: 'completed',
    )
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F6),
        surfaceTintColor: const Color(0xFFF5F7F6),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(
          'Medical Reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF17211E),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _reportsStream(),
        builder: (
            context,
            snapshot,
            ) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final documents = snapshot.data?.docs.toList() ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];

          documents.sort(
                (a, b) {
              final aDate = _dateFromDocument(a.data());
              final bDate = _dateFromDocument(b.data());
              return bDate.compareTo(aDate);
            },
          );

          final latestReport =
          documents.isNotEmpty ? documents.first : null;

          final previousReports =
          documents.length > 1 ? documents.skip(1).toList() : [];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                40,
              ),
              children: [
                const _ReportsIntro(),

                const SizedBox(height: 18),

                _UploadReportCard(
                  loading: _isUploading,
                  onTap: _openUploadOptions,
                ),

                if (latestReport != null) ...[
                  const SizedBox(height: 26),
                  const _SectionHeader(
                    title: 'Latest Report',
                    subtitle:
                    'Your most recently analyzed medical report.',
                  ),
                  const SizedBox(height: 12),
                  _ReportCard(
                    document: latestReport,
                    featured: true,
                    onTap: () => _openReportAnalysis(
                      latestReport,
                    ),
                  ),
                ],

                if (previousReports.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _SectionHeader(
                    title: 'Previous Reports',
                    subtitle:
                    '${previousReports.length} saved ${previousReports.length == 1 ? 'report' : 'reports'}',
                  ),
                  const SizedBox(height: 12),
                  ...previousReports.map(
                        (document) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: _ReportCard(
                        document: document,
                        onTap: () =>
                            _openReportAnalysis(
                              document,
                            ),
                      ),
                    ),
                  ),
                ],

                if (documents.isEmpty) ...[
                  const SizedBox(height: 26),
                  const _EmptyReportsState(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _openReportAnalysis(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data();
    final analysisRaw = data['analysis'];

    if (analysisRaw is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This report does not contain analysis data.',
          ),
        ),
      );
      return;
    }

    final analysis =
    Map<String, dynamic>.from(analysisRaw);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisResultScreen(
          type: 'report',
          result: analysis,
        ),
      ),
    );
  }

  static DateTime _dateFromDocument(
      Map<String, dynamic> data,
      ) {
    final value =
    data['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }
}

class _ReportsIntro extends StatelessWidget {
  const _ReportsIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE7F7F2),
            Color(0xFFD8F0E8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR HEALTH VAULT',
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.05,
              fontWeight: FontWeight.w800,
              color: Color(0xFF11786D),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Medical Reports',
            style: TextStyle(
              fontSize: 25,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17211E),
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Keep your analyzed reports organized and open any report to review its results.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFF5F6F69),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF17211E),
          ),
        ),
        if (subtitle != null &&
            subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 11.8,
              color: Color(0xFF7A8581),
            ),
          ),
        ],
      ],
    );
  }
}

class _UploadReportCard extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _UploadReportCard({
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
        BorderRadius.circular(20),
        onTap: loading ? null : onTap,
        child: Container(
          padding:
          const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(20),
            border: Border.all(
              color:
              const Color(0xFFDDE7E3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFE7F6F1,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                ),
                child: loading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.add_rounded,
                  color: Color(
                    0xFF11786D,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a medical report',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight:
                        FontWeight.w800,
                        color: Color(
                          0xFF17211E,
                        ),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Upload a PDF or scan using your camera',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(
                          0xFF71807B,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8B9894),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final QueryDocumentSnapshot<
      Map<String, dynamic>> document;
  final VoidCallback onTap;
  final bool featured;

  const _ReportCard({
    required this.document,
    required this.onTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final raw = document.data();

    final analysisRaw = raw['analysis'];

    final analysis = analysisRaw is Map
        ? Map<String, dynamic>.from(
      analysisRaw,
    )
        : <String, dynamic>{};

    final reportInfo = _mapValue(
      analysis['report'],
    );

    final title = _firstText(
      [
        reportInfo['title'],
        reportInfo['report_type'],
        analysis['title'],
        analysis['report_type'],
        raw['fileName'],
      ],
    ) ??
        'Medical report';

    final labName = _firstText(
      [
        reportInfo['lab_name'],
        reportInfo['lab'],
        analysis['lab_name'],
      ],
    );

    final reportDate = _firstText(
      [
        reportInfo['report_date'],
        analysis['report_date'],
      ],
    );

    final results = _extractResults(
      analysis,
    );

    final summary = _firstText(
      [
        reportInfo['summary'],
        analysis['summary'],
      ],
    );

    final uncertainCount =
    reportInfo['uncertain_fields'] is List
        ? (reportInfo['uncertain_fields']
    as List)
        .length
        : 0;

    final createdAt =
    raw['createdAt'] is Timestamp
        ? (raw['createdAt'] as Timestamp)
        .toDate()
        : null;

    final previewResults =
    results.take(featured ? 3 : 2).toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color: featured
                  ? const Color(
                0xFFBFDCD4,
              )
                  : const Color(
                0xFFE4EAE7,
              ),
            ),
            boxShadow: featured
                ? [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.035),
                blurRadius: 16,
                offset:
                const Offset(0, 6),
              ),
            ]
                : null,
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
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          const TextStyle(
                            fontSize: 16,
                            height: 1.15,
                            fontWeight:
                            FontWeight
                                .w900,
                            color: Color(
                              0xFF17211E,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          [
                            if (labName != null)
                              labName,
                            if (reportDate != null)
                              reportDate
                            else if (createdAt !=
                                null)
                              _formatDate(
                                createdAt,
                              ),
                          ].join(' • '),
                          style:
                          const TextStyle(
                            fontSize: 11.5,
                            color: Color(
                              0xFF7A8581,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration:
                    BoxDecoration(
                      color: const Color(
                        0xFFE7F6F1,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      featured
                          ? 'Latest'
                          : 'Analyzed',
                      style:
                      const TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                        FontWeight.w800,
                        color: Color(
                          0xFF11786D,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (previewResults
                  .isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(
                  height: 1,
                  color: Color(
                    0xFFE9EEEC,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                  previewResults.map(
                        (item) {
                      final valueText = [
                        if (item.value !=
                            null)
                          item.value!,
                        if (item.unit !=
                            null)
                          item.unit!,
                      ].join(' ');

                      return Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration:
                        BoxDecoration(
                          color: const Color(
                            0xFFF5F7F6,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(14),
                        ),
                        child: Text(
                          valueText.isEmpty
                              ? item.name
                              : '${item.name}: $valueText',
                          style:
                          const TextStyle(
                            fontSize: 11.5,
                            fontWeight:
                            FontWeight
                                .w700,
                            color: Color(
                              0xFF3C4945,
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],

              if (featured &&
                  summary != null) ...[
                const SizedBox(height: 13),
                Text(
                  summary,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(
                      0xFF66736F,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              Row(
                children: [
                  if (uncertainCount > 0)
                    Text(
                      '$uncertainCount ${uncertainCount == 1 ? 'detail needs' : 'details need'} confirmation',
                      style:
                      const TextStyle(
                        fontSize: 10.8,
                        color: Color(
                          0xFF9A6700,
                        ),
                      ),
                    )
                  else
                    const Text(
                      'Analysis available',
                      style:
                      TextStyle(
                        fontSize: 10.8,
                        color: Color(
                          0xFF71807B,
                        ),
                      ),
                    ),
                  const Spacer(),
                  const Text(
                    'View analysis',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                      FontWeight.w800,
                      color: Color(
                        0xFF11786D,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons
                        .arrow_forward_rounded,
                    size: 16,
                    color: Color(
                      0xFF11786D,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> _mapValue(
      dynamic value,
      ) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return {};
  }

  static List<_ReportResult> _extractResults(
      Map<String, dynamic> analysis,
      ) {
    dynamic rawResults =
    analysis['results'];

    final report =
    _mapValue(analysis['report']);

    rawResults ??= report['results'];
    rawResults ??= analysis['values'];
    rawResults ??= analysis['tests'];

    if (rawResults is! List) {
      return [];
    }

    final items = <_ReportResult>[];

    for (final item in rawResults) {
      if (item is! Map) {
        continue;
      }

      final map =
      Map<String, dynamic>.from(
        item,
      );

      final name = _firstText(
        [
          map['name'],
          map['test_name'],
          map['parameter'],
          map['label'],
        ],
      );

      if (name == null) {
        continue;
      }

      final value = _firstText(
        [
          map['value'],
          map['result'],
        ],
      );

      final unit = _firstText(
        [
          map['unit'],
        ],
      );

      final status = _firstText(
        [
          map['printed_flag'],
          map['status'],
          map['flag'],
          map['classification'],
        ],
      );

      items.add(
        _ReportResult(
          name: name,
          value: value,
          unit: unit,
          status: status,
        ),
      );
    }

    return items;
  }

  static String? _firstText(
      List<dynamic> values,
      ) {
    for (final value in values) {
      final text =
      value?.toString().trim();

      if (text != null &&
          text.isNotEmpty &&
          text.toLowerCase() !=
              'null') {
        return text;
      }
    }

    return null;
  }

  static String _formatDate(
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _EmptyReportsState
    extends StatelessWidget {
  const _EmptyReportsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color:
          const Color(
            0xFFE4EAE7,
          ),
        ),
      ),
      child: const Column(
        children: [
          Text(
            'No reports yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w800,
              color: Color(
                0xFF17211E,
              ),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Upload a PDF or scan a report to see your analyzed results here.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(
                0xFF71807B,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportResult {
  final String name;
  final String? value;
  final String? unit;
  final String? status;

  const _ReportResult({
    required this.name,
    required this.value,
    required this.unit,
    required this.status,
  });
}
