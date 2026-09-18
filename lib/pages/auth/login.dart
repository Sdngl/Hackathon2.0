import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../navbar.dart';
import '../../service/auth_service.dart';
import '../../validators/validators.dart';


import '../theme/apptheme.dart';
import '../widgets/widget.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final AuthService _auth = AuthService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const Navbar(0, true),
        ),
            (route) => false,
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

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      setState(() {
        _error =
        'Enter your email first, then tap Forgot password.';
      });
      return;
    }

    setState(() {
      _error = null;
    });

    try {
      await _auth.sendPasswordReset(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset link sent to $email',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = AuthService.describeError(e);
      });
    }
  }

  void _openSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SignupScreen(),
      ),
    );
  }

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
                  const AuthHeader(
                    title: 'Welcome Back',
                    subtitle:
                    'Sign in to continue your personalized health journey',
                  ),

                  const SizedBox(height: 24),

                  AuthCard(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Email or Phone',
                          hint: 'name@example.com',
                          icon: Icons.mail_outline_rounded,
                          controller: _emailCtrl,
                          keyboardType:
                          TextInputType.emailAddress,
                          validator: Validators.email,
                        ),

                        const SizedBox(height: 18),

                        AppTextField(
                          label: 'Password',
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          controller: _passwordCtrl,
                          textInputAction:
                          TextInputAction.done,
                          validator: Validators.password,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loading
                                ? null
                                : _resetPassword,
                            style: TextButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              foregroundColor:
                              AppColors.primary,
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                        if (_error != null) ...[
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .error,
                            ),
                          ),

                          const SizedBox(height: 12),
                        ],

                        PrimaryButton(
                          text: 'Log In',
                          loading: _loading,
                          onPressed: _login,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const OrDivider(
                    text: 'or log in with',
                  ),

                  const SizedBox(height: 22),

                  GoogleButton(
                    onPressed: () {
                      // Google login can be connected later.
                    },
                  ),

                  const SizedBox(height: 36),

                  AuthFooter(
                    question: "Don't have an account?",
                    action: 'Sign Up',
                    onTap: _openSignup,
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