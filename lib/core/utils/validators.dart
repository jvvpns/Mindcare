class Validators {
  Validators._();

  // ── Email ─────────────────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ── Password ──────────────────────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  // ── Confirm Password ──────────────────────────────────────────────────────
  static String? Function(String?) confirmPassword(String original) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != original) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  // ── Required (generic) ───────────────────────────────────────────────────
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ── Name ──────────────────────────────────────────────────────────────────
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // ── Journal / Free Text (min length) ─────────────────────────────────────
  static String? Function(String?) minLength(int min, {String? label}) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '${label ?? 'This field'} is required';
      }
      if (value.trim().length < min) {
        return '${label ?? 'This field'} must be at least $min characters';
      }
      return null;
    };
  }

  // ── Stress Rating (1–5) ───────────────────────────────────────────────────
  static String? stressRating(int? value) {
    if (value == null) return 'Please rate your stress level';
    if (value < 1 || value > 5) return 'Rating must be between 1 and 5';
    return null;
  }
}