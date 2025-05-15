import 'package:flutter/services.dart';

class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final textOnlyDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final isCnpj = textOnlyDigits.length > 11;
    String formatted = '';

    if (isCnpj) {
      // CNPJ: 00.000.000/0000-00
      final buffer = StringBuffer();
      for (int i = 0; i < textOnlyDigits.length && i < 14; i++) {
        if (i == 2 || i == 5) buffer.write('.');
        if (i == 8) buffer.write('/');
        if (i == 12) buffer.write('-');
        buffer.write(textOnlyDigits[i]);
      }
      formatted = buffer.toString();
    } else {
      // CPF: 000.000.000-00
      final buffer = StringBuffer();
      for (int i = 0; i < textOnlyDigits.length && i < 11; i++) {
        if (i == 3 || i == 6) buffer.write('.');
        if (i == 9) buffer.write('-');
        buffer.write(textOnlyDigits[i]);
      }
      formatted = buffer.toString();
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
