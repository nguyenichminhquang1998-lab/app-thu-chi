import 'package:flutter/material.dart';

import '../utils/amount_calculator.dart';
import '../utils/formatters.dart';

/// The big bold amount readout plus the small gray expression trail below
/// it, replacing a plain TextField for the Add Transaction amount field.
/// Tapping it opens [CalculatorKeypad] (driven by the parent screen).
class CalculatorAmountDisplay extends StatelessWidget {
  final AmountCalculator state;
  final bool isActive;
  final VoidCallback onTap;

  const CalculatorAmountDisplay({
    super.key,
    required this.state,
    required this.isActive,
    required this.onTap,
  });

  String get _bigText {
    if (state.currentInput.isEmpty) {
      return state.accumulator != null ? formatAmount(state.displayValue) : '0';
    }
    final parts = state.currentInput.split(',');
    final intPart = parts[0].isEmpty ? '0' : parts[0];
    final formattedInt = formatAmount(int.parse(intPart));
    return state.hasDecimalPoint ? '$formattedInt,${parts.length > 1 ? parts[1] : ''}' : formattedInt;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: const ValueKey('calc-amount-display'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? scheme.primary : Colors.transparent, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_bigText, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4, left: 4),
                  child: Text('₫', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ),
              ],
            ),
            if (state.expressionTrail.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  state.expressionTrail,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A 4-column in-app keypad (digits, decimal point, backspace, ÷ × − +,
/// and a final equals row) driving [AmountCalculator] state — built the
/// same structural way as `PinNumPad` (Column of Rows of Expanded +
/// AspectRatio + Material + InkWell "buttons").
class CalculatorKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDecimal;
  final VoidCallback onBackspace;
  final ValueChanged<CalcOperator> onOperator;
  final VoidCallback onEquals;

  const CalculatorKeypad({
    super.key,
    required this.onDigit,
    required this.onDecimal,
    required this.onBackspace,
    required this.onOperator,
    required this.onEquals,
  });

  static const List<List<Object>> _rows = [
    ['7', '8', '9', CalcOperator.divide],
    ['4', '5', '6', CalcOperator.multiply],
    ['1', '2', '3', CalcOperator.subtract],
    [',', '0', 'back', CalcOperator.add],
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        // Caps how large the aspect-ratio buttons can grow on wide
        // screens (tablets, or the desktop-sized default test surface) —
        // on an actual phone width this constraint simply isn't reached.
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in _rows)
                Row(
                  children: [
                    for (final key in row)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: AspectRatio(
                            aspectRatio: 1.8,
                            child: _KeypadButton(
                              keyValue: key,
                              onTap: () => _handleTap(key),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: Material(
                  key: const ValueKey('calc-equals'),
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: onEquals,
                    child: Center(child: Icon(Icons.check, color: scheme.onPrimary)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(Object key) {
    if (key is CalcOperator) {
      onOperator(key);
    } else if (key == 'back') {
      onBackspace();
    } else if (key == ',') {
      onDecimal();
    } else if (key is String) {
      onDigit(key);
    }
  }
}

class _KeypadButton extends StatelessWidget {
  final Object keyValue; // digit String, ',', 'back', or a CalcOperator
  final VoidCallback onTap;

  const _KeypadButton({required this.keyValue, required this.onTap});

  Key get _valueKey => switch (keyValue) {
        CalcOperator op => ValueKey('calc-op-${op.name}'),
        'back' => const ValueKey('calc-backspace'),
        ',' => const ValueKey('calc-decimal'),
        _ => ValueKey('calc-digit-$keyValue'),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isOperator = keyValue is CalcOperator;
    return Material(
      key: _valueKey,
      color: isOperator ? scheme.primary : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(child: _buildChild(scheme, isOperator)),
      ),
    );
  }

  Widget _buildChild(ColorScheme scheme, bool isOperator) {
    if (keyValue == 'back') {
      return const Icon(Icons.backspace_outlined, size: 22);
    }
    if (keyValue is CalcOperator) {
      return Text(
        (keyValue as CalcOperator).symbol,
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: scheme.onPrimary),
      );
    }
    return Text('$keyValue', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500));
  }
}
