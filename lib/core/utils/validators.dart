class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-\+]+@([\w\-]+\.)+[\w\-]{2,4}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    if (value.trim().length < 3) return 'Username must be at least 3 characters';
    if (value.trim().length > 20) return 'Username must be under 20 characters';
    final regex = RegExp(r'^[a-zA-Z0-9_ ]+$');
    if (!regex.hasMatch(value.trim())) return 'Only letters, numbers and _ allowed';
    return null;
  }

  static String? notEmpty(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final regex = RegExp(r'^(03[0-9]{9}|\+92[0-9]{10})$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid PK phone number (03XXXXXXXXX)';
    return null;
  }

  static String? amount(String? value, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return 'Amount must be greater than 0';
    if (min != null && parsed < min) return 'Minimum amount is $min';
    if (max != null && parsed > max) return 'Insufficient balance';
    return null;
  }

  static String? bankAccount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Account number is required';
    if (value.trim().length < 6) return 'Enter a valid account number';
    return null;
  }
}
