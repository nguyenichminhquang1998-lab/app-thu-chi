import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_lock_service.dart';
import '../../state/settings_state.dart';
import 'pin_numpad.dart';

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
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) _submit();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (!_confirming) {
      // Give the 4th dot a moment to render filled before switching screens.
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 56, color: scheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    _confirming ? 'Xác nhận mã PIN' : 'Đặt mã PIN mới',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _confirming ? 'Nhập lại mã PIN để xác nhận' : 'Nhập mã PIN gồm 4 chữ số',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 28),
                  PinDots(filledCount: _pin.length),
                ],
              ),
            ),
            PinNumPad(onDigit: _onDigit, onBackspace: _onBackspace),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
