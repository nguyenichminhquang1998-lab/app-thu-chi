import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Live-formats a numeric amount field with Vietnamese thousands
/// separators as the user types (e.g. "1000000" while typing shows as
/// "1.000.000").
class ThousandsInputFormatter extends TextInputFormatter {
  final NumberFormat _format = NumberFormat.decimalPattern('vi_VN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final value = int.parse(digitsOnly);
    final formatted = _format.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static double parse(String formatted) {
    final digitsOnly = formatted.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return 0;
    return double.parse(digitsOnly);
  }
}
