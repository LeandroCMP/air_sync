import 'package:flutter/services.dart';

/// Formata BTUs com separador de milhares (pontos): 18000 -> 18.000
/// Mantém apenas dígitos internamente.
class BtusInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    // Limita BTUs a um tamanho razoável (ex.: 7 dígitos -> até milhões)
    if (digits.length > 7) digits = digits.substring(0, 7);

    final formatted = _thousands(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _thousands(String digits) {
    final buf = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      buf.write(digits[i]);
      count++;
      if (count % 3 == 0 && i != 0) buf.write('.');
    }
    return buf.toString().split('').reversed.join();
  }
}

