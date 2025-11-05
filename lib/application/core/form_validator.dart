class FormValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-mail obrigatório';
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'E-mail inválido';
    return null;
  }

  static String? validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return validateEmail(value);
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Senha obrigatória';
    if (value.length < 6) return 'Senha muito curta';
    return null;
  }

  static String? validateNotEmpty(String? value, {String fieldName = 'Campo'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName obrigatório';
    return null;
  }

  // Compatibilidade: aceita "positive: true" (equivale a min: > 0)
  static String? validateNumber(
    String? value, {
    String fieldName = 'Campo',
    double? min,
    double? max,
    bool positive = false,
  }) {
    if (value == null || value.trim().isEmpty) return '$fieldName obrigatório';
    final v = double.tryParse(value.replaceAll(',', '.'));
    if (v == null) return '$fieldName inválido';
    final double? effectiveMin = positive ? (min ?? double.minPositive) : min;
    if (positive && v <= 0) return '$fieldName deve ser > 0';
    if (effectiveMin != null && !positive && v < effectiveMin) return '$fieldName deve ser ≥ $effectiveMin';
    if (max != null && v > max) return '$fieldName deve ser ≤ $max';
    return null;
  }

  static String? validateOptionalNumber(
    String? value, {
    String fieldName = 'Campo',
    double? min,
    double? max,
    bool positive = false,
  }) {
    if (value == null || value.trim().isEmpty) return null;
    return validateNumber(value, fieldName: fieldName, min: min, max: max, positive: positive);
  }

  static String? validateOptionalCpfCnpj(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (v.isEmpty) return null;
    if (v.length == 11 || v.length == 14) return null;
    return 'Documento inválido';
  }

  static String? validateOptionalPhone(String? value) {
    final v = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (v.isEmpty) return null;
    if (v.length >= 10 && v.length <= 11) return null;
    return 'Telefone inválido';
  }
}

