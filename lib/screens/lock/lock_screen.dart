import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_lock_service.dart';
import '../../state/settings_state.dart';
import 'pin_numpad.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 56, color: scheme.primary),
                  const SizedBox(height: 20),
                  Text('Nhập mã PIN để mở khoá', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 28),
                  PinDots(filledCount: _pin.length),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            PinNumPad(onDigit: _onDigit, onBackspace: _onBackspace),
            if (settings.biometricEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Dùng vân tay / Face ID'),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
