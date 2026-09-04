import 'package:app_thu_chi/utils/amount_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

AmountCalculator _typeDigits(AmountCalculator calc, String digits) {
  var c = calc;
  for (final ch in digits.split('')) {
    c = ch == ',' ? c.inputDecimalPoint() : c.inputDigit(ch);
  }
  return c;
}

void main() {
  group('AmountCalculator', () {
    test('accumulates digits typed into currentValue', () {
      final calc = _typeDigits(const AmountCalculator(), '1500000');
      expect(calc.currentValue, 1500000);
    });

    test('leading zero is ignored', () {
      final calc = _typeDigits(const AmountCalculator(), '0');
      expect(calc.currentInput, isEmpty);
      expect(calc.currentValue, 0);
    });

    test('matches the reference example: 622222 - 32922 = 589300', () {
      var calc = _typeDigits(const AmountCalculator(), '622222');
      calc = calc.applyOperator(CalcOperator.subtract);
      calc = _typeDigits(calc, '32922');
      calc = calc.evaluate();
      expect(calc.currentValue, 589300);
      expect(calc.expressionTrail, isEmpty, reason: 'equals should clear the trail');
    });

    test('expression trail shows the completed step with thousands separators', () {
      var calc = _typeDigits(const AmountCalculator(), '622222');
      calc = calc.applyOperator(CalcOperator.subtract);
      expect(calc.expressionTrail, '622.222');
      calc = _typeDigits(calc, '32922');
      calc = calc.applyOperator(CalcOperator.add);
      expect(calc.expressionTrail, '622.222−32.922');
    });

    test('chained operations evaluate left-to-right without operator precedence', () {
      var calc = _typeDigits(const AmountCalculator(), '100');
      calc = calc.applyOperator(CalcOperator.add);
      calc = _typeDigits(calc, '200');
      calc = calc.applyOperator(CalcOperator.subtract);
      calc = _typeDigits(calc, '50');
      calc = calc.evaluate();
      expect(calc.currentValue, 250);
    });

    test('supports decimal input: 12,5 + 2,5 = 15', () {
      var calc = _typeDigits(const AmountCalculator(), '12,5');
      expect(calc.currentValue, 12.5);
      calc = calc.applyOperator(CalcOperator.add);
      calc = _typeDigits(calc, '2,5');
      calc = calc.evaluate();
      expect(calc.currentValue, 15);
    });

    test('a second comma is ignored once one decimal point exists', () {
      final calc = _typeDigits(const AmountCalculator(), '1,2,3');
      expect(calc.currentInput, '1,23');
    });

    test('tapping an operator with no operand yet is a no-op', () {
      const calc = AmountCalculator();
      final after = calc.applyOperator(CalcOperator.add);
      expect(after.currentValue, 0);
      expect(after.pendingOperator, isNull);
    });

    test('tapping an operator twice in a row swaps the pending operator', () {
      var calc = _typeDigits(const AmountCalculator(), '100');
      calc = calc.applyOperator(CalcOperator.add);
      calc = calc.applyOperator(CalcOperator.subtract);
      expect(calc.pendingOperator, CalcOperator.subtract);
      calc = _typeDigits(calc, '40');
      calc = calc.evaluate();
      expect(calc.currentValue, 60);
    });

    test('division by zero does not crash and returns the dividend unchanged', () {
      var calc = _typeDigits(const AmountCalculator(), '100');
      calc = calc.applyOperator(CalcOperator.divide);
      calc = _typeDigits(calc, '0');
      calc = calc.evaluate();
      expect(calc.currentValue, 100);
    });

    test('backspace removes the last typed character', () {
      var calc = _typeDigits(const AmountCalculator(), '123');
      calc = calc.backspace();
      expect(calc.currentInput, '12');
    });

    test('backspace on empty input is a no-op', () {
      const calc = AmountCalculator();
      expect(calc.backspace().currentInput, isEmpty);
    });

    test('evaluate with no pending operator is a no-op', () {
      final calc = _typeDigits(const AmountCalculator(), '42');
      expect(calc.evaluate().currentValue, 42);
    });

    test('result of evaluate can be extended by typing more digits', () {
      var calc = _typeDigits(const AmountCalculator(), '5');
      calc = calc.applyOperator(CalcOperator.add);
      calc = _typeDigits(calc, '5');
      calc = calc.evaluate();
      expect(calc.currentValue, 10);
      calc = calc.inputDigit('0');
      expect(calc.currentValue, 100);
    });
  });
}
