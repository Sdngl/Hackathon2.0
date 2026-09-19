/// Reusable form field validators.
class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) return 'Please enter your email';
    if (!_emailRegex.hasMatch(input)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Please enter a password';
    if (input.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? Function(String?) required(String message) {
    return (value) => (value ?? '').trim().isEmpty ? message : null;
  }
}