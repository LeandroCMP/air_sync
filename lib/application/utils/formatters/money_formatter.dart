import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter({this.locale = 'pt_BR', this.symbol = 'R\$'});

  final String locale;
  final String symbol;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final value = double.parse(digitsOnly) / 100;
    final text = formatCurrencyPtBr(value, locale: locale, symbol: symbol);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

double? parseCurrencyPtBr(String? value) {
  if (value == null) return null;
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return double.parse(digits) / 100;
}

String formatCurrencyPtBr(
  num value, {
  String locale = 'pt_BR',
  String symbol = 'R\$',
}) {
  return NumberFormat.currency(locale: locale, symbol: symbol).format(value);
}
