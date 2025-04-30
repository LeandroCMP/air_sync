class FormValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email obrigatório';
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Email inválido';
    return null;
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
}
