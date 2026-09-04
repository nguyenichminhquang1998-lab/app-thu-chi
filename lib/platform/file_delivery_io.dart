import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'exported_file.dart';

/// Writes the file to the app's temp directory and opens the OS share sheet —
/// the same behaviour the app has always had on iOS and Android.
Future<void> deliverFile(ExportedFile file, {String? text}) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/${file.name}';
  await File(path).writeAsBytes(file.bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(path, mimeType: file.mimeType)], text: text),
  );
}
