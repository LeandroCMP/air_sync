import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class DigitsOnlyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);
    String out;
    if (digits.length <= 2) {
      out = '($digits';
    } else if (digits.length <= 6) {
      out = '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    } else if (digits.length <= 10) {
      out =
          '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    } else {
      out =
          '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

class CnpjCpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 14) digits = digits.substring(0, 14);
    String out;
    if (digits.length <= 11) {
      // CPF: 000.000.000-00
      if (digits.length <= 3) {
        out = digits;
      } else if (digits.length <= 6) {
        out = '${digits.substring(0, 3)}.${digits.substring(3)}';
      } else if (digits.length <= 9) {
        out =
            '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6)}';
      } else if (digits.length <= 11) {
        out =
            '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
      } else {
        out = digits;
      }
    } else {
      // CNPJ: 00.000.000/0000-00
      if (digits.length <= 2) {
        out = digits;
      } else if (digits.length <= 5) {
        out = '${digits.substring(0, 2)}.${digits.substring(2)}';
      } else if (digits.length <= 8) {
        out =
            '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5)}';
      } else if (digits.length <= 12) {
        out =
            '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8)}';
      } else {
        out =
            '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
      }
    }
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  }
}

class MoneyInputFormatter extends TextInputFormatter {
  MoneyInputFormatter({String locale = 'pt_BR', String symbol = 'R\$'})
    : _formatter = NumberFormat.currency(locale: locale, symbol: symbol);

  final NumberFormat _formatter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final value = double.parse(digits) / 100;
    final formatted = _formatter.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PercentInputFormatter extends TextInputFormatter {
  PercentInputFormatter({this.maxDigits = 5, this.locale = 'pt_BR'})
    : _formatter = NumberFormat.decimalPattern(locale);

  final int maxDigits;
  final String locale;
  final NumberFormat _formatter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (maxDigits > 0 && digits.length > maxDigits) {
      digits = digits.substring(0, maxDigits);
    }
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final value = double.parse(digits) / 100;
    final formatted = _formatter.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
