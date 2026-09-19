import 'package:flutter/material.dart';
import '../theme/apptheme.dart';

/// Labelled input field with leading icon and optional password toggle.
class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.validator,
    this.textInputAction = TextInputAction.next,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.isPassword;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppColors.label,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          textInputAction: widget.textInputAction,
          style: const TextStyle(fontSize: 15, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.hint, fontSize: 15),
            prefixIcon: Icon(widget.icon, size: 21, color: AppColors.label),
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 21,
                color: AppColors.label,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.primary, 1.5),
            errorBorder: _border(Colors.red.shade300),
            focusedErrorBorder: _border(Colors.red.shade400, 1.5),
          ),
        ),
      ],
    );
  }
}


/// Big filled teal button with a soft drop shadow.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.4, color: Colors.white),
        )
            : Text(
          text,
          style: const TextStyle(
              fontSize: 16.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// White outlined "Google" button. Drop google.png into assets/images
/// to show the real logo; otherwise it falls back to an icon.

class GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          side: const BorderSide(
            color: Color(0xFFE1E7E5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/google.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ────── or log in with ──────
class OrDivider extends StatelessWidget {
  final String text;
  const OrDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    const line = Expanded(child: Divider(color: AppColors.border, height: 1));
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text,
              style: const TextStyle(fontSize: 13.5, color: AppColors.label)),
        ),
        line,
      ],
    );
  }
}

/// White rounded card that holds the form.
class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Title + subtitle at the top of the auth screens.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
              fontSize: 15, height: 1.35, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// "Don't have an account? Sign Up"
class AuthFooter extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;

  const AuthFooter({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$question ',
            style: const TextStyle(fontSize: 14.5, color: AppColors.textMuted)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}