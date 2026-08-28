import 'package:flutter/material.dart';

/// The row of 4 dots showing how many PIN digits have been entered so far.
class PinDots extends StatelessWidget {
  final int filledCount;
  final int length;

  const PinDots({super.key, required this.filledCount, this.length = 4});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final filled = i < filledCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? scheme.primary : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}

/// A full-width numeric keypad (1-9, 0, backspace) used by both the PIN
/// setup screen and the unlock screen, sized to fill the bottom portion of
/// the screen rather than sitting as a small centered block.
class PinNumPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const PinNumPad({super.key, required this.onDigit, required this.onBackspace});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          for (final row in _rows)
            Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      child: AspectRatio(
                        aspectRatio: 1.4,
                        child: key.isEmpty
                            ? const SizedBox.shrink()
                            : Material(
                                color: Colors.transparent,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: key == '⌫' ? onBackspace : () => onDigit(key),
                                  child: Center(
                                    child: key == '⌫'
                                        ? const Icon(Icons.backspace_outlined, size: 24)
                                        : Text(key, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
