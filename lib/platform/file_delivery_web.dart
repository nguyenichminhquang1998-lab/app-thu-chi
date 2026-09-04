import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'exported_file.dart';

/// Triggers a normal browser download. The Web Share API refuses files on
/// several desktop browsers and is patchy elsewhere, so a download is the
/// dependable route; on an iPhone the file lands in Tệp (Files), which is
/// where a backup needs to end up anyway.
Future<void> deliverFile(ExportedFile file, {String? text}) async {
  final blob = web.Blob(
    <JSUint8Array>[file.bytes.toJS].toJS,
    web.BlobPropertyBag(type: file.mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = file.name
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
