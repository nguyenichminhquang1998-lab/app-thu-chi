import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../platform/file_delivery.dart';
import '../../services/auth_lock_service.dart';
import '../../services/backup_service.dart';
import '../../services/notification_service.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../categories/categories_screen.dart';
import '../lock/pin_setup_screen.dart';
import '../recurring/recurring_screen.dart';
import '../wallets/wallets_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backupService = BackupService();
  final _authService = AuthLockService();
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          const _SectionHeader('Quản lý'),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Danh mục'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Ví / Tài khoản'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Giao dịch định kỳ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecurringScreen())),
          ),
          const Divider(),
          const _SectionHeader('Hiển thị'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Chế độ tối'),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (v) => settings.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_view_month_outlined),
            title: const Text('Ngày bắt đầu tháng'),
            subtitle: Text('Ngày ${settings.monthStartDay} hằng tháng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickMonthStartDay(context, settings, appState),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.pie_chart_outline),
            title: const Text('Chế độ ngân sách'),
            subtitle: const Text('Hiện tiến độ và cảnh báo ngân sách'),
            value: settings.budgetModeEnabled,
            onChanged: settings.setBudgetModeEnabled,
          ),
          // Scheduled local notifications need a native runtime — a browser
          // cannot fire a reminder once the tab/PWA is closed — so the whole
          // section is hidden on web rather than offering a switch that
          // silently does nothing.
          if (!kIsWeb) ...[
            const Divider(),
            const _SectionHeader('Nhắc nhở'),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Nhắc ghi chép hằng ngày'),
              subtitle: Text(settings.reminderEnabled
                  ? '${settings.reminderHour.toString().padLeft(2, '0')}:${settings.reminderMinute.toString().padLeft(2, '0')} mỗi ngày'
                  : 'Đang tắt'),
              value: settings.reminderEnabled,
              onChanged: (v) => _toggleReminder(context, settings, v),
            ),
            if (settings.reminderEnabled) ...[
              ListTile(
                leading: const SizedBox(width: 24),
                title: const Text('Đổi giờ nhắc nhở'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickReminderTime(context, settings),
              ),
              ListTile(
                leading: const SizedBox(width: 24),
                title: const Text('Gửi thông báo thử ngay'),
                subtitle: const Text('Kiểm tra xem điện thoại có hiện thông báo/chuông không'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => NotificationService.instance.showTestNotification(),
              ),
            ],
          ],
          const Divider(),
          const _SectionHeader('Bảo mật'),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('Khoá ứng dụng bằng mã PIN'),
            value: settings.lockEnabled,
            onChanged: (v) => _toggleLock(context, settings, v),
          ),
          // Browsers give this app no usable Face ID / fingerprint API, so on
          // web the PIN is the only lock and this switch would be dead.
          if (settings.lockEnabled && !kIsWeb)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Mở khoá bằng vân tay / Face ID'),
              value: settings.biometricEnabled,
              onChanged: (v) async {
                if (v && !await _authService.canUseBiometrics()) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thiết bị không hỗ trợ sinh trắc học')),
                    );
                  }
                  return;
                }
                await settings.setLock(enabled: true, biometric: v);
              },
            ),
          const Divider(),
          const _SectionHeader('Sao lưu & Dữ liệu'),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Sao lưu dữ liệu (xuất file)'),
            onTap: () => _exportBackup(context, settings),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Khôi phục dữ liệu (nhập file)'),
            onTap: () => _restore(context, appState),
          ),
          const Divider(),
          const _SectionHeader('Khác'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Phiên bản'),
            subtitle: Text(_version.isEmpty ? '—' : _version),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonthStartDay(BuildContext context, SettingsState settings, AppState appState) async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Chọn ngày bắt đầu tháng'),
        children: [
          SizedBox(
            height: 300,
            width: 300,
            child: GridView.count(
              crossAxisCount: 7,
              children: [
                for (var d = 1; d <= 28; d++)
                  InkWell(
                    onTap: () => Navigator.of(context).pop(d),
                    child: Center(
                      child: Text(
                        '$d',
                        style: TextStyle(
                          fontWeight: d == settings.monthStartDay ? FontWeight.bold : FontWeight.normal,
                          color: d == settings.monthStartDay ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      await settings.setMonthStartDay(selected);
      await appState.resetToCurrentPeriod();
    }
  }

  Future<void> _toggleReminder(BuildContext context, SettingsState settings, bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.instance.requestPermissions();
      await settings.setReminder(enabled: true);
      await NotificationService.instance.scheduleDailyReminder(
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
      );
      if (!granted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Điện thoại đang chặn thông báo của app này. Vào Cài đặt hệ thống → Thông báo → Thu Chi để bật, nếu không nhắc nhở sẽ không hiện.',
            ),
            duration: Duration(seconds: 6),
          ),
        );
      }
    } else {
      await settings.setReminder(enabled: false);
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  Future<void> _pickReminderTime(BuildContext context, SettingsState settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.reminderHour, minute: settings.reminderMinute),
    );
    if (picked != null) {
      await settings.setReminder(enabled: true, hour: picked.hour, minute: picked.minute);
      await NotificationService.instance.scheduleDailyReminder(hour: picked.hour, minute: picked.minute);
    }
  }

  Future<void> _toggleLock(BuildContext context, SettingsState settings, bool enabled) async {
    if (enabled) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PinSetupScreen()));
    } else {
      await settings.setLock(enabled: false, biometric: false);
    }
  }

  Future<void> _exportBackup(BuildContext context, SettingsState settings) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Chọn định dạng', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.restore_outlined),
              title: const Text('JSON — dùng để khôi phục sau này'),
              subtitle: const Text('Định dạng duy nhất "Khôi phục dữ liệu" đọc được'),
              onTap: () => Navigator.of(context).pop('json'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Excel/CSV — để xem trong Excel, Google Sheets'),
              subtitle: const Text('Chỉ để xem, không dùng để khôi phục lại vào app'),
              onTap: () => Navigator.of(context).pop('csv'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Markdown (.md) — để xem/lưu trữ dạng văn bản'),
              subtitle: const Text('Chỉ để xem, không dùng để khôi phục lại vào app'),
              onTap: () => Navigator.of(context).pop('md'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    final file = switch (choice) {
      'csv' => await _backupService.buildCsvExport(),
      'md' => await _backupService.buildMarkdownExport(),
      _ => await _backupService.buildJsonBackup(),
    };
    await deliverFile(file, text: 'Dữ liệu Thu Chi');
    await settings.markBackedUp();
  }

  Future<void> _restore(BuildContext context, AppState appState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục dữ liệu?'),
        content: const Text('Toàn bộ dữ liệu hiện tại sẽ bị thay thế bằng dữ liệu trong file sao lưu.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Tiếp tục')),
        ],
      ),
    );
    if (confirmed != true) return;
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (files.isEmpty) return;
    // readAsBytes() works on every platform: in the browser a picked file is
    // a Blob with no path at all, which is why reading it by path used to
    // silently do nothing there.
    try {
      await _backupService.restoreFromBytes(await files.single.readAsBytes());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không đọc được file sao lưu: $e')),
        );
      }
      return;
    }
    await appState.reloadAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khôi phục dữ liệu thành công')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
