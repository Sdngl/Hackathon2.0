import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum MovementType {
  yoga,
  exercise,
  breathing,
}

class MovementItem {
  final String title;
  final String subtitle;

  const MovementItem({
    required this.title,
    required this.subtitle,
  });
}

class MovementSession {
  final MovementType type;
  final String title;
  final String description;
  final String duration;
  final String level;
  final String videoId;
  final String sectionTitle;
  final String information;
  final List<MovementItem> items;

  const MovementSession({
    required this.type,
    required this.title,
    required this.description,
    required this.duration,
    required this.level,
    required this.videoId,
    required this.sectionTitle,
    required this.information,
    required this.items,
  });

  String get youtubeUrl =>
      'https://www.youtube.com/watch?v=$videoId';

  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
}

class MovementPage extends StatefulWidget {
  final MovementType initialType;

  const MovementPage({
    super.key,
    this.initialType = MovementType.yoga,
  });

  @override
  State<MovementPage> createState() => _MovementPageState();
}

class _MovementPageState extends State<MovementPage> {
  late MovementType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  static const MovementSession _yogaSession = MovementSession(
    type: MovementType.yoga,
    title: 'Morning Yoga Flow',
    description:
    'A gentle morning yoga session for mobility, stretching and relaxation.',
    duration: '15 min',
    level: 'Beginner',
    videoId: 'r7xsYgTeM2Q',
    sectionTitle: 'Poses in this flow',
    information:
    'Start gently and move at a comfortable pace. Focus on slow movement, balance and relaxed breathing.',
    items: [
      MovementItem(
        title: 'Mountain Pose',
        subtitle: 'Posture · balance',
      ),
      MovementItem(
        title: 'Cat–Cow Stretch',
        subtitle: 'Spine mobility',
      ),
      MovementItem(
        title: "Child's Pose",
        subtitle: 'Gentle relaxation',
      ),
      MovementItem(
        title: 'Cobra Pose',
        subtitle: 'Back mobility',
      ),
      MovementItem(
        title: 'Downward-Facing Dog',
        subtitle: 'Full-body stretch',
      ),
      MovementItem(
        title: 'Low Lunge',
        subtitle: 'Hip mobility',
      ),
      MovementItem(
        title: 'Warrior II',
        subtitle: 'Balance · legs',
      ),
      MovementItem(
        title: 'Seated Forward Fold',
        subtitle: 'Gentle leg stretch',
      ),
      MovementItem(
        title: 'Corpse Pose',
        subtitle: 'Relaxation',
      ),
    ],
  );

  static const MovementSession _exerciseSession = MovementSession(
    type: MovementType.exercise,
    title: 'Full Body Workout',
    description:
    'A simple beginner bodyweight session covering the major muscle groups.',
    duration: '20 min',
    level: 'Beginner',
    videoId: 'LqW9gdpctKE',
    sectionTitle: 'Exercises in this flow',
    information:
    'Use controlled movements and comfortable effort. Rest when needed and avoid pushing through pain.',
    items: [
      MovementItem(
        title: 'Bodyweight Squats',
        subtitle: 'Legs · glutes',
      ),
      MovementItem(
        title: 'Push-Ups',
        subtitle: 'Chest · shoulders · arms',
      ),
      MovementItem(
        title: 'Reverse Lunges',
        subtitle: 'Legs · balance',
      ),
      MovementItem(
        title: 'Glute Bridge',
        subtitle: 'Glutes · hips',
      ),
      MovementItem(
        title: 'Plank',
        subtitle: 'Core',
      ),
      MovementItem(
        title: 'Bird Dog',
        subtitle: 'Core · balance',
      ),
      MovementItem(
        title: 'Shoulder Taps',
        subtitle: 'Shoulders · core',
      ),
      MovementItem(
        title: 'Calf Raises',
        subtitle: 'Calves · lower legs',
      ),
      MovementItem(
        title: 'Dead Bug',
        subtitle: 'Core · coordination',
      ),
    ],
  );

  static const MovementSession _breathingSession = MovementSession(
    type: MovementType.breathing,
    title: 'Calm Breathing',
    description:
    'A guided breathing session for slowing down, relaxing and improving focus.',
    duration: 'Guided',
    level: 'Beginner',
    videoId: 'OXjlR4mXxSk',
    sectionTitle: 'Breathing in this flow',
    information:
    'Keep breathing comfortable and natural. Stop the exercise if you feel light-headed or uncomfortable.',
    items: [
      MovementItem(
        title: 'Natural Breathing',
        subtitle: 'Notice your normal breath',
      ),
      MovementItem(
        title: 'Belly Breathing',
        subtitle: 'Gentle diaphragmatic breathing',
      ),
      MovementItem(
        title: 'Slow Nasal Breathing',
        subtitle: 'Comfortable slow breaths',
      ),
      MovementItem(
        title: 'Equal Breathing',
        subtitle: 'Balanced inhale and exhale',
      ),
      MovementItem(
        title: 'Extended Exhale',
        subtitle: 'Gentle longer exhale',
      ),
      MovementItem(
        title: 'Box Breathing',
        subtitle: 'Steady breathing rhythm',
      ),
      MovementItem(
        title: 'Relaxed Belly Breathing',
        subtitle: 'Release tension',
      ),
      MovementItem(
        title: 'Mindful Breathing',
        subtitle: 'Focus on each breath',
      ),
    ],
  );

  MovementSession get _currentSession {
    switch (_selectedType) {
      case MovementType.yoga:
        return _yogaSession;

      case MovementType.exercise:
        return _exerciseSession;

      case MovementType.breathing:
        return _breathingSession;
    }
  }

  Future<void> _openYoutube(
      MovementSession session,
      ) async {
    final uri = Uri.parse(
      session.youtubeUrl,
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the YouTube video.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the YouTube video.',
          ),
        ),
      );
    }
  }

  void _selectType(
      MovementType type,
      ) {
    setState(() {
      _selectedType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _currentSession;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F7F6,
      ),
      appBar: AppBar(
        backgroundColor: const Color(
          0xFFF5F7F6,
        ),
        surfaceTintColor: const Color(
          0xFFF5F7F6,
        ),
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Movement',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Color(
              0xFF17211E,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(
              right: 18,
              top: 9,
              bottom: 9,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            child: const Text(
              'Week 1',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(
                  0xFF4B5552,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            40,
          ),
          children: [
            _MovementTabs(
              selectedType: _selectedType,
              onSelected: _selectType,
            ),

            const SizedBox(
              height: 16,
            ),

            _InformationCard(
              text: session.information,
            ),

            const SizedBox(
              height: 16,
            ),

            _VideoSessionCard(
              session: session,
              onTap: () {
                _openYoutube(
                  session,
                );
              },
            ),

            const SizedBox(
              height: 20,
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    session.sectionTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(
                        0xFF17211E,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${session.items.length} items',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(
                      0xFF7C8783,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            _MovementItemsCard(
              items: session.items,
            ),
          ],
        ),
      ),
    );
  }
}

class _MovementTabs extends StatelessWidget {
  final MovementType selectedType;
  final ValueChanged<MovementType> onSelected;

  const _MovementTabs({
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(
        4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Yoga',
              selected:
              selectedType == MovementType.yoga,
              onTap: () {
                onSelected(
                  MovementType.yoga,
                );
              },
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Exercise',
              selected:
              selectedType ==
                  MovementType.exercise,
              onTap: () {
                onSelected(
                  MovementType.exercise,
                );
              },
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Breathing',
              selected:
              selectedType ==
                  MovementType.breathing,
              onTap: () {
                onSelected(
                  MovementType.breathing,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(
        0xFF102A24,
      )
          : Colors.transparent,
      borderRadius: BorderRadius.circular(
        13,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          13,
        ),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : const Color(
                0xFF7A8581,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  final String text;

  const _InformationCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF0EDFF,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(
              top: 1,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Color(
                0xFF7961EA,
              ),
              size: 18,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: Color(
                  0xFF48514F,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoSessionCard extends StatelessWidget {
  final MovementSession session;
  final VoidCallback onTap;

  const _VideoSessionCard({
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(
        26,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          26,
        ),
        child: Container(
          height: 265,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              26,
            ),
            color: const Color(
              0xFF6446E8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF6446E8,
                ).withOpacity(
                  0.20,
                ),
                blurRadius: 22,
                offset: const Offset(
                  0,
                  10,
                ),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                session.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (
                    context,
                    error,
                    stackTrace,
                    ) {
                  return const ColoredBox(
                    color: Color(
                      0xFF6446E8,
                    ),
                  );
                },
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(
                        0xFF3E27A7,
                      ).withOpacity(
                        0.25,
                      ),
                      const Color(
                        0xFF4324BA,
                      ).withOpacity(
                        0.88,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(
                  20,
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(
                          0.22,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: const Text(
                        "TODAY'S SESSION",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                          FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const Spacer(),

                    Text(
                      session.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight:
                        FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      session.description,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(
                          0.88,
                        ),
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(
                      height: 17,
                    ),

                    Row(
                      children: [
                        _VideoInfoChip(
                          icon:
                          Icons.schedule_rounded,
                          text: session.duration,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        _VideoInfoChip(
                          icon:
                          Icons.favorite_border_rounded,
                          text: session.level,
                        ),

                        const Spacer(),

                        Container(
                          width: 50,
                          height: 50,
                          decoration:
                          const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 30,
                            color: Color(
                              0xFF6446E8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _VideoInfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.20,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementItemsCard extends StatelessWidget {
  final List<MovementItem> items;

  const _MovementItemsCard({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.035,
            ),
            blurRadius: 18,
            offset: const Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          for (
          var index = 0;
          index < items.length;
          index++
          ) ...[
            _MovementItemTile(
              index: index,
              item: items[index],
            ),
            if (index != items.length - 1)
              const Divider(
                height: 1,
                indent: 48,
                color: Color(
                  0xFFE5EAE8,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MovementItemTile extends StatelessWidget {
  final int index;
  final MovementItem item;

  const _MovementItemTile({
    required this.index,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: index < 2
                  ? const Color(
                0xFFE2F5EF,
              )
                  : const Color(
                0xFFF1F3F2,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: index < 2
                ? const Icon(
              Icons.check_rounded,
              color: Color(
                0xFF159378,
              ),
              size: 20,
            )
                : Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(
                  0xFF78827F,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(
                      0xFF26302D,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(
                      0xFF7A8581,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: Color(
              0xFF7A8581,
            ),
          ),
        ],
      ),
    );
  }
}