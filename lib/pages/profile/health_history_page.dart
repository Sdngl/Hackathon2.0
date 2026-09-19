import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../camera/analysis_result_screen.dart';
import '../theme/apptheme.dart';

enum HealthHistoryType {
  medicine,
  report,
}

class HealthHistoryPage extends StatefulWidget {
  final HealthHistoryType type;

  const HealthHistoryPage({
    super.key,
    required this.type,
  });

  @override
  State<HealthHistoryPage> createState() => _HealthHistoryPageState();
}

class _HealthHistoryPageState extends State<HealthHistoryPage> {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String get _collectionName =>
      widget.type == HealthHistoryType.medicine ? 'medicines' : 'reports';

  String get _analysisType =>
      widget.type == HealthHistoryType.medicine ? 'medicine' : 'report';

  String get _title =>
      widget.type == HealthHistoryType.medicine
          ? 'Medication history'
          : 'Medical records';

  String get _subtitle =>
      widget.type == HealthHistoryType.medicine
          ? 'Your saved medication scans'
          : 'Your saved report analyses';

  IconData get _icon =>
      widget.type == HealthHistoryType.medicine
          ? Icons.medication_outlined
          : Icons.description_outlined;

  Color get _accent =>
      widget.type == HealthHistoryType.medicine
          ? const Color(0xFFD98E04)
          : const Color(0xFF3B74E0);

  Color get _accentLight =>
      widget.type == HealthHistoryType.medicine
          ? const Color(0xFFFFF3D6)
          : const Color(0xFFE5EEFD);

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection(_collectionName)
        .snapshots();
  }

  Future<void> _refresh() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection(_collectionName)
        .get(const GetOptions(source: Source.server));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _stream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return _ErrorState(
                onRetry: _refresh,
              );
            }

            final records = (snapshot.data?.docs ?? const [])
                .map(_HealthHistoryRecord.fromDocument)
                .toList()
              ..sort((a, b) => b.sortDate.compareTo(a.sortDate));

            if (records.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 120),
                  children: [
                    _EmptyState(
                      icon: _icon,
                      title: widget.type == HealthHistoryType.medicine
                          ? 'No medications saved yet'
                          : 'No medical records yet',
                      message: widget.type == HealthHistoryType.medicine
                          ? 'Medication scans you save will appear here.'
                          : 'Saved report analyses will appear here.',
                    ),
                  ],
                ),
              );
            }

            final latest = records.first;
            final older = records.skip(1).toList();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _subtitle,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Latest',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _FeaturedHistoryCard(
                            record: latest,
                            icon: _icon,
                            accent: _accent,
                            accentLight: _accentLight,
                            onTap: () => _openRecord(latest),
                          ),
                          if (older.isNotEmpty) ...[
                            const SizedBox(height: 26),
                            Text(
                              widget.type == HealthHistoryType.medicine
                                  ? 'Previous medications'
                                  : 'Previous records',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (older.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final record = older[index];
                            return _HistoryGridCard(
                              record: record,
                              icon: _icon,
                              accent: _accent,
                              accentLight: _accentLight,
                              onTap: () => _openRecord(record),
                            );
                          },
                          childCount: older.length,
                        ),
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                      ),
                    )
                  else
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 120),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openRecord(_HealthHistoryRecord record) async {
    if (record.analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            record.status == 'failed'
                ? 'This analysis did not complete successfully.'
                : 'This analysis is not available yet.',
          ),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisResultScreen(
          type: _analysisType,
          result: record.analysis!,
        ),
      ),
    );
  }
}

class _HealthHistoryRecord {
  final String id;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? analysis;
  final DateTime sortDate;

  const _HealthHistoryRecord({
    required this.id,
    required this.data,
    required this.analysis,
    required this.sortDate,
  });

  factory _HealthHistoryRecord.fromDocument(
      QueryDocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data();
    final rawAnalysis = data['analysis'];

    Map<String, dynamic>? analysis;
    if (rawAnalysis is Map) {
      analysis = Map<String, dynamic>.from(rawAnalysis);
    }

    DateTime? date;
    for (final value in [data['updatedAt'], data['createdAt']]) {
      if (value is Timestamp) {
        date = value.toDate();
        break;
      }
      if (value is DateTime) {
        date = value;
        break;
      }
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          date = parsed;
          break;
        }
      }
    }

    return _HealthHistoryRecord(
      id: document.id,
      data: data,
      analysis: analysis,
      sortDate: date ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String get status =>
      (data['status']?.toString().trim().toLowerCase().isNotEmpty ?? false)
          ? data['status'].toString().trim().toLowerCase()
          : (analysis != null ? 'completed' : 'pending');

  String get title {
    if (data['type']?.toString().toLowerCase() == 'medicine') {
      return _medicineTitle;
    }
    return _reportTitle;
  }

  String get _medicineTitle {
    final a = analysis ?? const <String, dynamic>{};

    final medicine = a['medicine'];
    if (medicine is Map) {
      for (final key in ['name', 'medicine_name', 'generic_name', 'brand_name']) {
        final value = medicine[key]?.toString().trim();
        if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
          return value;
        }
      }
    }

    final medicines = a['medicines'];
    if (medicines is List && medicines.isNotEmpty && medicines.first is Map) {
      final first = medicines.first as Map;
      for (final key in ['name', 'medicine_name', 'generic_name', 'brand_name']) {
        final value = first[key]?.toString().trim();
        if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
          return value;
        }
      }
    }

    for (final key in ['medicine_name', 'name', 'generic_name']) {
      final value = a[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    return 'Medication scan';
  }

  String get _reportTitle {
    final a = analysis ?? const <String, dynamic>{};

    for (final key in [
      'report_title',
      'title',
      'report_type',
      'document_type',
      'test_name',
    ]) {
      final value = a[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }

    final fileName = data['fileName']?.toString().trim();
    if (fileName != null && fileName.isNotEmpty) {
      return fileName;
    }

    return 'Medical report';
  }

  String get dateLabel {
    if (sortDate.millisecondsSinceEpoch == 0) return 'Date unavailable';

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

    return '${months[sortDate.month - 1]} ${sortDate.day}, ${sortDate.year}';
  }

  Uint8List? get imageBytes {
    final raw = data['imageBase64'];
    if (raw is! String || raw.trim().isEmpty) return null;

    try {
      var value = raw.trim();
      final comma = value.indexOf(',');
      if (value.startsWith('data:') && comma >= 0) {
        value = value.substring(comma + 1);
      }
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}

class _FeaturedHistoryCard extends StatelessWidget {
  final _HealthHistoryRecord record;
  final IconData icon;
  final Color accent;
  final Color accentLight;
  final VoidCallback onTap;

  const _FeaturedHistoryCard({
    required this.record,
    required this.icon,
    required this.accent,
    required this.accentLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = record.imageBytes;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 240,
              width: double.infinity,
              child: bytes == null
                  ? _ImageFallback(
                icon: icon,
                accent: accent,
                accentLight: accentLight,
                large: true,
              )
                  : Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => _ImageFallback(
                  icon: icon,
                  accent: accent,
                  accentLight: accentLight,
                  large: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          record.dateLabel,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusBadge(status: record.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryGridCard extends StatelessWidget {
  final _HealthHistoryRecord record;
  final IconData icon;
  final Color accent;
  final Color accentLight;
  final VoidCallback onTap;

  const _HistoryGridCard({
    required this.record,
    required this.icon,
    required this.accent,
    required this.accentLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = record.imageBytes;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: bytes == null
                    ? _ImageFallback(
                  icon: icon,
                  accent: accent,
                  accentLight: accentLight,
                )
                    : Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => _ImageFallback(
                    icon: icon,
                    accent: accent,
                    accentLight: accentLight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    record.dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusBadge(status: record.status, compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color accentLight;
  final bool large;

  const _ImageFallback({
    required this.icon,
    required this.accent,
    required this.accentLight,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accentLight,
      alignment: Alignment.center,
      child: Container(
        width: large ? 74 : 52,
        height: large ? 74 : 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: large ? 34 : 26,
          color: accent,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const _StatusBadge({
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final (label, background, foreground) = switch (normalized) {
      'completed' => (
      'Completed',
      const Color(0xFFE3F5EF),
      const Color(0xFF0F7B64),
      ),
      'failed' => (
      'Failed',
      const Color(0xFFFEE4E2),
      const Color(0xFFD92D20),
      ),
      'processing' => (
      'Processing',
      const Color(0xFFE5EEFD),
      const Color(0xFF3B74E0),
      ),
      _ => (
      'Pending',
      const Color(0xFFFFF3D6),
      const Color(0xFFD98E04),
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: Color(0xFFE3F5EF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 34,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.onRetry,
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
              Icons.cloud_off_outlined,
              size: 44,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load your history',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => onRetry(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
