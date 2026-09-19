import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/login.dart';
import '../theme/apptheme.dart';
import 'get_started.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade =
  CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween(begin: 0.85, end: 1.0)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const GetStartedScreen(),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.splashTop, AppColors.splashBottom],
            ),
          ),
          child: Stack(
            children: [
              // Soft light glow in the top-left corner
              Positioned(
                top: -120,
                left: -120,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.14),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/img.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_hospital_rounded,
                              size: 48,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'SEVA',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your health companion',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ],
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
}