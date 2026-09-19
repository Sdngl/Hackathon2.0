import 'package:flutter/material.dart';

import '../../features/assistant/presentation/health_assistant_screen.dart';
import '../profile/profile.dart';
import 'app_button.dart';
import 'home.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainShell> createState() =>
      _MainShellState();
}

class _MainShellState
    extends State<MainShell> {
  late int _index =
      widget.initialIndex;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              Home(),
              HealthAssistantScreen(),
              Profile(),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomBar(
              index: _index,
              onTap: (i) {
                setState(() {
                  _index = i;
                });
              },
              onScan: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Open scanner',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}