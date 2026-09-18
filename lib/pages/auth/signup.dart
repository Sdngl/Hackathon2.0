import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../service/auth_service.dart';
import '../../validators/validators.dart';
import '../theme/apptheme.dart';
import '../widgets/widget.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final AuthService _auth = AuthService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // REGISTER
  // ---------------------------------------------------------

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );

      if (!mounted) return;

      // Keeps the behavior from your existing signup screen.
      // The first/root screen can now detect the signed-in user.
      Navigator.of(context).popUntil(
            (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = AuthService.describeError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------
  // BACK TO LOGIN
  // ---------------------------------------------------------

  void _openLogin() {
    if (_loading) return;

    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -----------------------------------------
                  // HEADER
                  // -----------------------------------------

                  const AuthHeader(
                    title: 'Create Account',
                    subtitle:
                    'Start tracking vitals and scanning reports today',
                  ),

                  const SizedBox(height: 20),

                  // -----------------------------------------
                  // REGISTER CARD
                  // -----------------------------------------

                  AuthCard(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        // -----------------------------------
                        // FULL NAME
                        // -----------------------------------

                        AppTextField(
                          label: 'Full Name',
                          hint: 'Aarya Sharma',
                          icon:
                          Icons.person_outline_rounded,
                          controller: _nameCtrl,
                          keyboardType:
                          TextInputType.name,
                          validator:
                          Validators.required(
                            'Please enter your name',
                          ),
                        ),

                        const SizedBox(height: 16),

                        // -----------------------------------
                        // EMAIL
                        // -----------------------------------

                        AppTextField(
                          label: 'Email',
                          hint: 'aarya@gmail.com',
                          icon:
                          Icons.mail_outline_rounded,
                          controller: _emailCtrl,
                          keyboardType:
                          TextInputType.emailAddress,
                          validator: Validators.email,
                        ),

                        const SizedBox(height: 16),

                        // -----------------------------------
                        // PASSWORD
                        // -----------------------------------

                        AppTextField(
                          label: 'Password',
                          hint: '••••••••',
                          icon:
                          Icons.lock_outline_rounded,
                          isPassword: true,
                          controller: _passwordCtrl,
                          validator:
                          Validators.password,
                        ),

                        const SizedBox(height: 16),

                        // -----------------------------------
                        // CONFIRM PASSWORD
                        // -----------------------------------

                        AppTextField(
                          label: 'Confirm Password',
                          hint: '••••••••',
                          icon:
                          Icons.lock_outline_rounded,
                          isPassword: true,
                          controller: _confirmCtrl,
                          textInputAction:
                          TextInputAction.done,
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty) {
                              return 'Confirm your password';
                            }

                            if (value !=
                                _passwordCtrl.text) {
                              return 'Passwords do not match';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // -----------------------------------
                        // PRIVACY MESSAGE
                        // -----------------------------------

                        const Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 16,
                              color:
                              AppColors.primary,
                            ),

                            SizedBox(width: 6),

                            Expanded(
                              child: Text(
                                'Your medical data is encrypted on device.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color:
                                  AppColors.label,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // -----------------------------------
                        // FIREBASE ERROR
                        // -----------------------------------

                        if (_error != null) ...[
                          const SizedBox(height: 14),

                          Text(
                            _error!,
                            textAlign:
                            TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .error,
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // -----------------------------------
                        // CREATE ACCOUNT BUTTON
                        // -----------------------------------

                        PrimaryButton(
                          text: 'Create Account',
                          loading: _loading,
                          onPressed: _register,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // -----------------------------------------
                  // DIVIDER
                  // -----------------------------------------

                  const OrDivider(
                    text: 'or sign up with',
                  ),

                  const SizedBox(height: 22),

                  // -----------------------------------------
                  // GOOGLE
                  // -----------------------------------------

                  GoogleButton(
                    onPressed: () {
                      // Google authentication can be
                      // connected later.
                    },
                  ),

                  const SizedBox(height: 32),

                  // -----------------------------------------
                  // LOGIN
                  // -----------------------------------------

                  AuthFooter(
                    question:
                    'Already have an account?',
                    action: 'Log In',
                    onTap: _openLogin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}