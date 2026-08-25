import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_lock_service.dart';
import '../../state/settings_state.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _authService = AuthLockService();
  String _pin = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final settings = context.read<SettingsState>();
    if (!settings.biometricEnabled) return;
    if (!await _authService.canUseBiometrics()) return;
    final ok = await _authService.authenticateWithBiometrics();
    if (ok && mounted) widget.onUnlocked();
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 4) _verify();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _verify() {
    final settings = context.read<SettingsState>();
    final hash = settings.pinHash;
    if (hash != null && _authService.verifyPin(_pin, hash)) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'Mã PIN không đúng';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              const Text('Nhập mã PIN để mở khoá', style: TextStyle(fontSize: 16)),
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
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              _NumPad(onDigit: _onDigit, onBackspace: _onBackspace),
              if (settings.biometricEnabled) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Dùng vân tay / Face ID'),
                ),
              ],
            ],
          ),
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
