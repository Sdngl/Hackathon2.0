import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


import '../../features/assistant/models/app_notification.dart';
import '../../service/notification_repository.dart';
import '../theme/apptheme.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationRepository _repository = NotificationRepository();
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _repository.syncTodayAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F8),
        surfaceTintColor: const Color(0xFFF7F9F8),
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<AppNotification>>(
          stream: _repository.watchNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final all = snapshot.data ?? const <AppNotification>[];
            final filtered = all.where(_matchesFilter).toList();

            return Column(
              children: [
                _FilterBar(
                  selected: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const _EmptyNotifications()
                      : _NotificationList(
                    items: filtered,
                    onTap: _openNotification,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _matchesFilter(AppNotification item) {
    switch (_filter) {
      case _NotificationFilter.all:
        return true;
      case _NotificationFilter.doctors:
        return item.type == AppNotificationType.appointment;
      case _NotificationFilter.medicine:
        return item.type == AppNotificationType.medicine;
      case _NotificationFilter.reports:
        return item.type == AppNotificationType.report;
      case _NotificationFilter.content:
        return item.type == AppNotificationType.content;
      case _NotificationFilter.announcements:
        return item.type == AppNotificationType.announcement;
    }
  }

  Future<void> _openNotification(AppNotification item) async {
    if (!item.isRead) {
      await _repository.markRead(item.id);
    }

    if (!mounted) return;

    if (item.type == AppNotificationType.content) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _BroadcastDetailPage(
            item: item,
          ),
        ),
      );
    }
  }
}

enum _NotificationFilter { all, doctors, medicine, reports, content, announcements }

class _FilterBar extends StatelessWidget {
  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = <(_NotificationFilter, String)>[
      (_NotificationFilter.all, 'All'),
      (_NotificationFilter.doctors, 'Doctors'),
      (_NotificationFilter.medicine, 'Medicine'),
      (_NotificationFilter.reports, 'Reports'),
      (_NotificationFilter.content, 'Content'),
      (_NotificationFilter.announcements, 'Announcements'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          for (final item in items) ...[
            ChoiceChip(
              label: Text(item.$2),
              selected: selected == item.$1,
              onSelected: (_) => onChanged(item.$1),
              showCheckmark: false,
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFE3F5EF),
              side: BorderSide(
                color: selected == item.$1
                    ? const Color(0xFFB8E3D5)
                    : const Color(0xFFE6EBE8),
              ),
              labelStyle: TextStyle(
                color: selected == item.$1
                    ? AppColors.primary
                    : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;

  const _NotificationList({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final today = <AppNotification>[];
    final yesterday = <AppNotification>[];
    final earlier = <AppNotification>[];

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    for (final item in items) {
      final date = item.createdAt;
      if (date == null || date.isBefore(yesterdayStart)) {
        earlier.add(item);
      } else if (date.isBefore(todayStart)) {
        yesterday.add(item);
      } else {
        today.add(item);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        if (today.isNotEmpty) ..._section('TODAY', today),
        if (yesterday.isNotEmpty) ..._section('YESTERDAY', yesterday),
        if (earlier.isNotEmpty) ..._section('EARLIER', earlier),
      ],
    );
  }

  List<Widget> _section(String title, List<AppNotification> items) {
    return [
      Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
      ),
      for (final item in items) ...[
        _NotificationCard(item: item, onTap: () => onTap(item)),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(item.type);

    return Material(
      color: item.isRead ? Colors.white : const Color(0xFFFBFEFD),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8ECEA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: visual.$2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(visual.$1, color: visual.$3, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.message.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static (IconData, Color, Color) _visualFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.appointment:
        return (
        Icons.medical_services_outlined,
        const Color(0xFFE3F5EF),
        const Color(0xFF0F7B64),
        );
      case AppNotificationType.medicine:
        return (
        Icons.medication_outlined,
        const Color(0xFFFFF3D6),
        const Color(0xFFD98E04),
        );
      case AppNotificationType.report:
        return (
        Icons.description_outlined,
        const Color(0xFFE5EEFD),
        const Color(0xFF3B74E0),
        );
      case AppNotificationType.meal:
        return (
        Icons.restaurant_rounded,
        const Color(0xFFFDE8E2),
        const Color(0xFFF26B4E),
        );
      case AppNotificationType.content:
        return (
        Icons.lightbulb_outline_rounded,
        const Color(0xFFEDE9FE),
        const Color(0xFF7C5CE0),
        );
      case AppNotificationType.announcement:
        return (
        Icons.campaign_outlined,
        const Color(0xFFE8F4FD),
        const Color(0xFF2D7FD3),
        );
      case AppNotificationType.general:
        return (
        Icons.notifications_none_rounded,
        const Color(0xFFF0F2F1),
        const Color(0xFF6B7572),
        );
    }
  }

  static String _timeLabel(DateTime? date) {
    if (date == null) return '';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}


class _BroadcastDetailPage
    extends StatelessWidget {
  final AppNotification item;

  const _BroadcastDetailPage({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl =
    item.imageUrl?.trim();

    return Scaffold(
      backgroundColor:
      const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFFF7F9F8),
        surfaceTintColor:
        const Color(0xFFF7F9F8),
        elevation: 0,
        title: Text(
          'Content',
          style: const TextStyle(
            fontWeight:
            FontWeight.w800,
            color:
            AppColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child:
        SingleChildScrollView(
          padding:
          const EdgeInsets
              .fromLTRB(
            20,
            10,
            20,
            40,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              if (imageUrl != null &&
                  imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius:
                  BorderRadius
                      .circular(
                    22,
                  ),
                  child: AspectRatio(
                    aspectRatio:
                    16 / 9,
                    child:
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                          context,
                          error,
                          stackTrace,
                          ) {
                        return Container(
                          color:
                          const Color(
                            0xFFEDE9FE,
                          ),
                          alignment:
                          Alignment
                              .center,
                          child:
                          const Icon(
                            Icons
                                .image_not_supported_outlined,
                            size: 34,
                            color:
                            Color(
                              0xFF7C5CE0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration:
                    BoxDecoration(
                      color: const Color(
                        0xFFEDE9FE,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        20,
                      ),
                    ),
                    child: Text(
                      item.category ??
                          'Content',
                      style:
                      const TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight
                            .w700,
                        color: Color(
                          0xFF7C5CE0,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _detailDate(
                      item.createdAt,
                    ),
                    style:
                    const TextStyle(
                      fontSize: 12,
                      color:
                      AppColors.label,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                item.title,
                style:
                const TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  AppColors.textDark,
                ),
              ),
              if (item.message
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 16,
                ),
                Container(
                  width:
                  double.infinity,
                  padding:
                  const EdgeInsets
                      .all(
                    18,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius
                        .circular(
                      22,
                    ),
                    border:
                    Border.all(
                      color:
                      const Color(
                        0xFFE8ECEA,
                      ),
                    ),
                  ),
                  child: Text(
                    item.message,
                    style:
                    const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color:
                      AppColors
                          .textDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _detailDate(
      DateTime? date,
      ) {
    if (date == null) {
      return '';
    }

    const months = <String>[
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
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE3F5EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You’re all caught up',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Appointments, analysis updates, content, and announcements will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}