import 'package:flutter/material.dart';

import '../profile/profile.dart';
import '../theme/apptheme.dart';
import 'app_button.dart';
import 'home.dart';


class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              Home(),
              _AiPlaceholder(),
              Profile(),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomBar(
              index: _index,
              onTap: (i) => setState(() => _index = i),
              onScan: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open scanner')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiPlaceholder extends StatelessWidget {
  const _AiPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'AI assistant coming soon',
        style: TextStyle(fontSize: 15, color: AppColors.textMuted),
      ),
    );
  }
}