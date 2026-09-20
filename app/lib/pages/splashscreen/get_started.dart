import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/signup.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.asset(
              'assets/img_2.png',
              fit: BoxFit.cover,
            ),

            // Overall black overlay
            // Makes the image darker so text is easier to read
            Container(
              color: Colors.black.withOpacity(0.32),
            ),

            // Additional gradient overlay
            // Keeps the lower part darker for the legal text and button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.18),
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.72),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [
                    0.0,
                    0.35,
                    0.62,
                    0.84,
                    1.0,
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    const Spacer(
                      flex: 5,
                    ),

                    // SEVA Brand
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/img_3.png',
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        Text(
                          'SEVA',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 46,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.6,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    const Text(
                      'Your health, in your hands',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const Text(
                      'Smart Everyday Vital Assistance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: 0.6,
                      ),
                    ),

                    const Spacer(
                      flex: 4,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // Legal text
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: Colors.white.withOpacity(0.92),
                          ),
                          children: const [
                            TextSpan(
                              text:
                              'By tapping on “Get Started”, you agree to our\n',
                            ),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Color(0xFF6ED7FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' & ',
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: Color(0xFF6ED7FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              32,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 32,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}