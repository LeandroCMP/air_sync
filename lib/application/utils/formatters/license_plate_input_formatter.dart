import 'package:flutter/services.dart';

class LicensePlateInputFormatter extends TextInputFormatter {
  const LicensePlateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Suporta placas antigas (AAA1234/AAA-1234) e Mercosul (AAA1A23/AAA-1A23).
    final raw = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length && i < 7; i++) {
      if (i == 3) buffer.write('-');
      buffer.write(raw[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
