/// Utility class for form validation
class Validator {
  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  /// Validates password (min 6 characters)
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Validates required fields
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  /// Validates password confirmation matches
  static String? Function(String?) passwordMatch(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Confirm password is required';
      }

      if (value != password) {
        return 'Passwords do not match';
      }

      return null;
    };
  }
}
