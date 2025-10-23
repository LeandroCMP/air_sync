class Validators {
  static String? requiredField(String? value, {String message = 'Campo obrigatório'}) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'E-mail inválido';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Telefone inválido';
    }
    return null;
  }

  static String? cpfCnpj(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 && digits.length != 14) {
      return 'Documento inválido';
    }
    return null;
  }

  static String? money(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final normalized = value.replaceAll(RegExp(r'[^0-9,.]'), '').replaceAll(',', '.');
    if (double.tryParse(normalized) == null) {
      return 'Valor inválido';
    }
    return null;
  }
}
