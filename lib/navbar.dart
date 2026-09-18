import 'package:flutter/material.dart';

import 'features/assistant/presentation/health_assistant_screen.dart';
import 'package:hackthon2/pages/camera/camera.dart';
import 'package:hackthon2/pages/home/home.dart';
import 'package:hackthon2/pages/profile/profile.dart';

class Navbar extends StatefulWidget {
  final int currentIndex;
  final bool navigation;

  const Navbar(
      this.currentIndex,
      this.navigation, {
        super.key,
      });

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  static const Color _teal = Color(0xFF11786D);
  static const Color _mint = Color(0xFFE0F7F2);
  static const Color _inactive = Color(0xFF536261);

  late int currentIndex;
  late final PageController _pageController;

  final List<Widget> pages = const [
    Home(), // 0
    HealthAssistantScreen(), // 1
    Profile(), // 2
  ];

  @override
  void initState() {
    super.initState();

    currentIndex = widget.currentIndex;

    // Valid page indexes are now only 0, 1, and 2.
    if (currentIndex < 0 || currentIndex > 2) {
      currentIndex = 0;
    }

    _pageController = PageController(
      initialPage: currentIndex,
    );
  }

  void _onTabTapped(int index) {
    if (index == currentIndex) {
      return;
    }

    setState(() {
      currentIndex = index;
    });

    _pageController.jumpToPage(index);
  }

  Future<void> _openCamera() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const Camera(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        children: pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            8,
          ),
          child: SizedBox(
            height: 75,
            child: Row(
              children: [
                _buildScanButton(),

                const SizedBox(width: 15),

                Expanded(
                  child: Container(
                    height: 75,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(42),
                      border: Border.all(
                        color: const Color(0xFFE8EEEE),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A223B38),
                          blurRadius: 22,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildNavItem(
                          0,
                          Icons.home_outlined,
                          'Home',
                        ),

                        _buildNavItem(
                          1,
                          Icons.auto_awesome_outlined,
                          'AI',
                        ),

                        _buildNavItem(
                          2,
                          Icons.person_outline,
                          'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index,
      IconData icon,
      String label,
      ) {
    final selected = currentIndex == index;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: () => _onTabTapped(index),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 200,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? _mint
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(36),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: selected
                      ? _teal
                      : _inactive,
                ),

                const SizedBox(height: 3),

                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: selected
                        ? _teal
                        : _inactive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return Semantics(
      button: true,
      label: 'Scan',
      child: Material(
        color: _teal,
        shape: const CircleBorder(),
        elevation: 7,
        shadowColor: const Color(0x440B5D54),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _openCamera,
          child: const SizedBox(
            width: 75,
            height: 75,
            child: Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CustomPaint(
                  painter: _ScanIconPainter(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class _ScanIconPainter extends CustomPainter {
  const _ScanIconPainter();

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final arm = w * 0.22;

    canvas.drawLine(
      Offset(0, arm),
      const Offset(0, 0),
      paint,
    );

    canvas.drawLine(
      const Offset(0, 0),
      Offset(arm, 0),
      paint,
    );

    canvas.drawLine(
      Offset(w - arm, 0),
      Offset(w, 0),
      paint,
    );

    canvas.drawLine(
      Offset(w, 0),
      Offset(w, arm),
      paint,
    );

    canvas.drawLine(
      Offset(0, h - arm),
      Offset(0, h),
      paint,
    );

    canvas.drawLine(
      Offset(0, h),
      Offset(arm, h),
      paint,
    );

    canvas.drawLine(
      Offset(w - arm, h),
      Offset(w, h),
      paint,
    );

    canvas.drawLine(
      Offset(w, h),
      Offset(w, h - arm),
      paint,
    );

    canvas.drawLine(
      Offset(
        w * 0.30,
        h * 0.50,
      ),
      Offset(
        w * 0.70,
        h * 0.50,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}