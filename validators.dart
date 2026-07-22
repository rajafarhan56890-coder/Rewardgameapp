import '../constants/app_constants.dart';

/// Centralized, pure validation functions. Returns null when valid,
/// or a user-facing error string when invalid. Used by both the
/// presentation layer (form fields) and domain layer (use cases) so
/// invalid data can never reach Firebase from a compromised client UI.
class Validators {
  Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[a-zA-Z]{2,}$');

  // Pakistani mobile format: 03XXXXXXXXX
  static final RegExp _phoneRegex = RegExp(r'^03[0-9]{9}$');

  static final RegExp _ibanRegex = RegExp(r'^PK[0-9]{2}[A-Z]{4}[0-9]{16}$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name is too short';
    }
    if (value.trim().length > AppConstants.maxNameLength) {
      return 'Name is too long';
    }
    if (!RegExp(r"^[a-zA-Z\s\.'-]+$").hasMatch(value.trim())) {
      return 'Name contains invalid characters';
    }
    return null;
  }

  static String? mobileNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid mobile number (e.g. 03001234567)';
    }
    return null;
  }

  static String? bankIban(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IBAN is required';
    }
    if (!_ibanRegex.hasMatch(value.trim().toUpperCase())) {
      return 'Enter a valid Pakistani IBAN (PKxx XXXX xxxxxxxxxxxxxxxx)';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? positiveAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final num? amount = num.tryParse(value.trim());
    if (amount == null) {
      return 'Enter a valid number';
    }
    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }
    return null;
  }
}
