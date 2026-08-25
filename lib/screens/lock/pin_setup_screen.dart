import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_lock_service.dart';
import '../../state/settings_state.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _authService = AuthLockService();
  String _firstPin = '';
  String _pin = '';
  bool _confirming = false;

  void _onDigit(String digit) {
    if (_pin.length >= 6) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) _submit();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (!_confirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _confirming = true;
      });
      return;
    }
    if (_pin != _firstPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã PIN không khớp, vui lòng thử lại')),
      );
      setState(() {
        _pin = '';
        _confirming = false;
        _firstPin = '';
      });
      return;
    }
    final settings = context.read<SettingsState>();
    await settings.setLock(enabled: true, newPinHash: _authService.hashPin(_pin));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_confirming ? 'Xác nhận mã PIN' : 'Đặt mã PIN mới')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_confirming ? 'Nhập lại mã PIN để xác nhận' : 'Nhập mã PIN gồm 4 chữ số'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            _NumPad(onDigit: _onDigit, onBackspace: _onBackspace),
          ],
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _NumPad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final key in row)
                SizedBox(
                  width: 72,
                  height: 56,
                  child: key.isEmpty
                      ? null
                      : TextButton(
                          onPressed: key == '⌫' ? onBackspace : () => onDigit(key),
                          child: Text(key, style: const TextStyle(fontSize: 22)),
                        ),
                ),
            ],
          ),
      ],
    );
  }
}
