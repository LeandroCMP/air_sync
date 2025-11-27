import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    int len = digitsOnly.length;

    // Se o campo estiver vazio, retorna o valor sem alterações
    if (len == 0) {
      return newValue;
    }

    int index = 0;

    // Adiciona o DDD (com parênteses e espaço)
    if (len >= 2) {
      buffer.write('(${digitsOnly.substring(0, 2)}) ');
      index = 2;
    } else if (len > 0) {
      buffer.write('(${digitsOnly.substring(0, len)}');
      return TextEditingValue(
        text: buffer.toString(),
        selection: TextSelection.collapsed(offset: buffer.length),
      );
    }

    // Número principal
    if (len - index >= 5) {
      buffer.write(digitsOnly.substring(index, index + 5));
      index += 5;

      if (len - index > 0) {
        buffer.write('-${digitsOnly.substring(index, len)}');
      }
    } else if (len > index) {
      buffer.write(digitsOnly.substring(index, len));
    }

    // Limita o número de caracteres para 11
    if (len > 11) {
      buffer.clear();
      buffer.write('(${digitsOnly.substring(0, 2)}) ');
      buffer.write(digitsOnly.substring(2, 7));
      buffer.write('-${digitsOnly.substring(7, 11)}');
    }

    // Se o usuário está apagando, remover os parênteses e o espaço corretamente
    if (newValue.text.length < oldValue.text.length) {
      String currentText = buffer.toString();
      if (currentText.endsWith(" ")) {
        currentText = currentText.substring(0, currentText.length - 1); // Remove o espaço
      }
      if (currentText.endsWith(")")) {
        currentText = currentText.substring(0, currentText.length - 1); // Remove o parêntese
      }
      if (currentText.endsWith("(")) {
        currentText = currentText.substring(0, currentText.length - 1); // Remove o parêntese
      }

      return TextEditingValue(
        text: currentText,
        selection: TextSelection.collapsed(offset: currentText.length),
      );
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
