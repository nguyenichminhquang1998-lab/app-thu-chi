import 'package:app_thu_chi/widgets/thousands_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThousandsInputFormatter.parse', () {
    test('parses a plain formatted number', () {
      expect(ThousandsInputFormatter.parse('1.234.567'), 1234567);
    });

    test('returns 0 for empty input', () {
      expect(ThousandsInputFormatter.parse(''), 0);
    });

    test('ignores non-digit characters', () {
      expect(ThousandsInputFormatter.parse('12a3b'), 123);
    });
  });
}
