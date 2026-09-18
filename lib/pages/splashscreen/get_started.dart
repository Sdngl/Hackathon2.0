import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/login.dart';
import '../theme/apptheme.dart';
import '../widgets/widget.dart';


class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const _VitalsCard(),
                      const SizedBox(height: 30),
                      const _BrandRow(),
                      const SizedBox(height: 16),
                      const Text(
                        'Your Complete Health\nCompanion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Track your daily vitals, get seamless medicine '
                            'scanning, and connect with custom AI-powered '
                            'insights all in one intelligent app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _PageIndicator(count: 3, current: 0),
                      const Spacer(),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        text: 'Get Started',
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        )
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VitalsCard extends StatelessWidget {
  const _VitalsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            // Ring fills up once when the screen opens
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 0.93),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) => CustomPaint(
                size: const Size(182, 182),
                painter: _RingPainter(progress: value),
                child: child,
              ),
              child: const SizedBox(
                width: 182,
                height: 182,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        size: 30, color: AppColors.primary),
                    SizedBox(height: 6),
                    Text(
                      '96 bpm',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Resting HR',
                      style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 42,
            right: 10,
            child: _StatChip(
              icon: Icons.nightlight_outlined,
              text: '7h 45m sleep',
              background: AppColors.sleepBg,
              foreground: AppColors.sleepText,
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 16,
            child: _StatChip(
              icon: Icons.directions_walk_rounded,
              text: '8,240 steps',
              background: AppColors.accentLight,
              foreground: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 22.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final track = Paint()
      ..color = AppColors.accentLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start at 12 o'clock
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  const _StatChip({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child:
          const Icon(Icons.add_rounded, size: 20, color: AppColors.accent),
        ),
        const SizedBox(width: 8),
        const Text(
          'SEVA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _PageIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFD5DBD9),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}