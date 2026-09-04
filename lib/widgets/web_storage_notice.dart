import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../platform/web_storage.dart';
import '../state/settings_state.dart';

/// Web-only safety net for the one real weakness of running in a browser:
/// the browser owns the storage and can throw it away.
///
/// Two warnings, in order of severity:
///  1. Not installed to the home screen — on iOS, Safari deletes a site's
///     storage after 7 days without interaction, and only home-screen web
///     apps are exempt. Losing the whole ledger is the worst case, so this
///     one is shown in a warning colour and cannot be dismissed by mistake.
///  2. No backup in a while — even installed, clearing browsing data wipes
///     everything, so a periodic JSON export is the real insurance.
class WebStorageNotice extends StatefulWidget {
  const WebStorageNotice({super.key});

  /// How long we let a backup age before nagging.
  static const staleBackupAfter = Duration(days: 14);

  @override
  State<WebStorageNotice> createState() => _WebStorageNoticeState();
}

class _WebStorageNoticeState extends State<WebStorageNotice> {
  bool _installed = true;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (!kIsWeb) return;
    // Ask the browser to keep our data even under storage pressure. Installed
    // web apps usually get this granted without prompting the user.
    await requestPersistentStorage();
    final installed = await isInstalledAsApp();
    if (mounted) {
      setState(() {
        _installed = installed;
        _checked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_checked) return const SizedBox.shrink();
    final settings = context.watch<SettingsState>();
    final scheme = Theme.of(context).colorScheme;

    if (!_installed && !settings.installHintDismissed) {
      return _Notice(
        icon: Icons.ios_share,
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
        title: 'Hãy thêm app vào Màn hình chính',
        message: 'Nếu chỉ mở trong trình duyệt, dữ liệu có thể bị xoá sau 7 ngày '
            'không dùng tới. Bấm nút Chia sẻ của trình duyệt rồi chọn '
            '"Thêm vào MH chính" để giữ dữ liệu an toàn.',
        onDismiss: settings.dismissInstallHint,
      );
    }

    final lastBackup = settings.lastBackupAt;
    final overdue = lastBackup == null ||
        DateTime.now().difference(lastBackup) > WebStorageNotice.staleBackupAfter;
    if (overdue) {
      return _Notice(
        icon: Icons.backup_outlined,
        background: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
        title: 'Nên sao lưu dữ liệu',
        message: lastBackup == null
            ? 'Bạn chưa sao lưu lần nào. Vào Cài đặt → Sao lưu dữ liệu để tải file JSON về máy.'
            : 'Lần sao lưu gần nhất đã lâu. Vào Cài đặt → Sao lưu dữ liệu để tải file JSON mới.',
      );
    }

    return const SizedBox.shrink();
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String message;
  final VoidCallback? onDismiss;

  const _Notice({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: foreground)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(fontSize: 13, color: foreground)),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: foreground),
              onPressed: onDismiss,
              tooltip: 'Ẩn nhắc nhở này',
            ),
        ],
      ),
    );
  }
}
