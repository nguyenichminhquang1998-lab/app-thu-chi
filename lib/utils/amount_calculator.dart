import 'package:intl/intl.dart';

/// The four arithmetic operators exposed on the amount-field calculator
/// keypad, in the order they appear (÷ × − +).
enum CalcOperator { divide, multiply, subtract, add }

extension CalcOperatorSymbol on CalcOperator {
  String get symbol => switch (this) {
        CalcOperator.divide => '÷',
        CalcOperator.multiply => '×',
        CalcOperator.subtract => '−',
        CalcOperator.add => '+',
      };

  double apply(double a, double b) => switch (this) {
        CalcOperator.divide => b == 0 ? a : a / b,
        CalcOperator.multiply => a * b,
        CalcOperator.subtract => a - b,
        CalcOperator.add => a + b,
      };
}

/// Pure, immutable calculator state for the amount-entry keypad.
///
/// Supports a left-to-right chain of operations (e.g. "100+200-50"),
/// evaluated eagerly as each operator/equals is pressed (no operator
/// precedence) — the same behavior as a plain pocket calculator.
class AmountCalculator {
  /// Running total carried over from previous operations in the chain.
  /// Null until the first operator is applied.
  final double? accumulator;

  /// The operator waiting to be applied once the next operand is entered.
  final CalcOperator? pendingOperator;

  /// Digits (and optional ',' decimal point) typed for the operand
  /// currently being entered — this is what's showing as the big number.
  final String currentInput;

  /// Human-readable trail of completed steps, e.g. "622.222−32.922",
  /// shown on the small line below. Empty until an operator has fired.
  final String expressionTrail;

  const AmountCalculator({
    this.accumulator,
    this.pendingOperator,
    this.currentInput = '',
    this.expressionTrail = '',
  });

  double get currentValue =>
      currentInput.isEmpty || currentInput == ',' ? 0 : double.parse(currentInput.replaceAll(',', '.'));

  /// The value that should be shown/committed right now.
  double get displayValue => currentValue;

  bool get hasDecimalPoint => currentInput.contains(',');

  AmountCalculator inputDigit(String digit) {
    if (currentInput.isEmpty && digit == '0') return this; // no leading zeros
    if (currentInput.length >= 15) return this; // sane cap
    return copyWith(currentInput: currentInput + digit);
  }

  AmountCalculator inputDecimalPoint() {
    if (hasDecimalPoint) return this;
    return copyWith(currentInput: currentInput.isEmpty ? '0,' : '$currentInput,');
  }

  AmountCalculator backspace() {
    if (currentInput.isEmpty) return this;
    return copyWith(currentInput: currentInput.substring(0, currentInput.length - 1));
  }

  AmountCalculator clear() => const AmountCalculator();

  /// Applies [op]: if there's already a pending operator and a fresh
  /// operand was typed, folds it into the accumulator first (so chained
  /// ops like 100+200-50 evaluate left-to-right), then arms [op] for the
  /// next operand.
  AmountCalculator applyOperator(CalcOperator op) {
    if (currentInput.isEmpty && accumulator == null) return this; // nothing to operate on yet
    if (currentInput.isEmpty && pendingOperator != null) {
      // Operator tapped twice in a row: just swap which operator is pending.
      return copyWith(pendingOperator: op);
    }
    final newAccumulator = _fold();
    final trail = expressionTrail.isEmpty
        ? _fmtDisplay(accumulator ?? currentValue)
        : '$expressionTrail${pendingOperator?.symbol ?? ''}${_fmtDisplay(currentValue)}';
    return AmountCalculator(
      accumulator: newAccumulator,
      pendingOperator: op,
      currentInput: '',
      expressionTrail: trail,
    );
  }

  /// Equals: folds any pending operation and clears the pending operator,
  /// leaving a plain resolved number. Has no other side effect (does not
  /// save anything) — the caller decides what to do with the result.
  AmountCalculator evaluate() {
    if (pendingOperator == null) return this;
    final result = _fold();
    return AmountCalculator(currentInput: _fmtRaw(result), expressionTrail: '');
  }

  double _fold() =>
      pendingOperator == null || accumulator == null ? currentValue : pendingOperator!.apply(accumulator!, currentValue);

  /// Raw digit string (no thousands separators) suitable for re-feeding
  /// into [currentInput] so further digit taps can keep appending to it.
  String _fmtRaw(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ',');

  /// Thousands-separated display form (vi_VN) used only in [expressionTrail].
  String _fmtDisplay(double v) => NumberFormat.decimalPattern('vi_VN').format(v);

  AmountCalculator copyWith({
    double? accumulator,
    CalcOperator? pendingOperator,
    String? currentInput,
    String? expressionTrail,
  }) {
    return AmountCalculator(
      accumulator: accumulator ?? this.accumulator,
      pendingOperator: pendingOperator ?? this.pendingOperator,
      currentInput: currentInput ?? this.currentInput,
      expressionTrail: expressionTrail ?? this.expressionTrail,
    );
  }
}
