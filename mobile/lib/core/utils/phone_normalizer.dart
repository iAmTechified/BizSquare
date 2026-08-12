class PhoneNormalizer {
  /// Normalizes any raw phone number string to canonical E.164 format
  /// Example: '0801 234 5678' -> '+2348012345678'
  /// Example: '2348012345678' -> '+2348012345678'
  /// Example: '+234 (801) 234-5678' -> '+2348012345678'
  static String normalize(String? rawPhone, {String defaultCountryCode = '234'}) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return '';

    // Strip all non-digit and non-plus characters
    String cleaned = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return '';

    // If starts with +, ensure digits follow
    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
      return digits.isEmpty ? '' : '+$digits';
    }

    // Nigerian local 0-prefixed 11-digit numbers (e.g. 080..., 070..., 090...)
    if (cleaned.startsWith('0') && cleaned.length == 11 && defaultCountryCode == '234') {
      return '+234${cleaned.substring(1)}';
    }

    // If starts with default country code without +
    if (cleaned.startsWith(defaultCountryCode)) {
      return '+$cleaned';
    }

    // Default: prepend +defaultCountryCode if 10-digit number without leading 0
    if (cleaned.length == 10 && defaultCountryCode == '234') {
      return '+234$cleaned';
    }

    return '+$cleaned';
  }

  /// Formats a canonical or raw phone number for human-friendly display
  /// Example: '+2348012345678' -> '+234 801 234 5678'
  static String formatDisplay(String rawPhone) {
    final normalized = normalize(rawPhone);
    if (normalized.startsWith('+234') && normalized.length == 14) {
      final code = normalized.substring(0, 4);
      final prefix = normalized.substring(4, 7);
      final mid = normalized.substring(7, 10);
      final last = normalized.substring(10, 14);
      return '$code $prefix $mid $last';
    }
    return rawPhone;
  }

  /// Determines if a phone number is a valid candidate for WhatsApp
  static bool isValidWhatsAppCandidate(String rawPhone) {
    final normalized = normalize(rawPhone);
    if (normalized.isEmpty || !normalized.startsWith('+')) return false;
    // Nigerian mobile prefixes under +234 (10 digits after +234: 80 + 8 digits = 10 digits total)
    if (normalized.startsWith('+234')) {
      final prefix = normalized.substring(4);
      return RegExp(r'^(70|80|81|90|91|71)\d{8}$').hasMatch(prefix);
    }
    // Generic international mobile check (between 10 and 15 digits)
    final digitsOnly = normalized.substring(1);
    return digitsOnly.length >= 9 && digitsOnly.length <= 15;
  }

  /// Constructs WhatsApp direct link
  static String getWhatsAppUrl(String rawPhone, {String? defaultMessage}) {
    final canonical = normalize(rawPhone).replaceAll('+', '');
    final msg = defaultMessage != null ? '?text=${Uri.encodeComponent(defaultMessage)}' : '';
    return 'https://wa.me/$canonical$msg';
  }
}
